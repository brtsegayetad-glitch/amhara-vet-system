import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/owner_model.dart';

class DatabaseService {
  final supabase = Supabase.instance.client;

  // 1. Save owner and return the record
  Future<Map<String, dynamic>> registerOwner(Owner owner) async {
    try {
      final response = await supabase
          .from('owners')
          .insert(owner.toMap())
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception("Error saving owner: $e");
    }
  }

  // 2. Update livestock counts
  Future<void> updateLivestockCounts(String ownerId, Map<String, int> counts) async {
    if (ownerId.isEmpty || ownerId == "null") {
      throw Exception("Owner ID is missing. Cannot save livestock.");
    }
    try {
      await supabase.from('livestock_population').upsert({
        'owner_id': ownerId,
        'cattle': counts['cattle'] ?? 0,
        'sheep': counts['sheep'] ?? 0,
        'goat': counts['goat'] ?? 0,
        'poultry': counts['poultry'] ?? 0,
        'donkey': counts['donkey'] ?? 0,
        'horse': counts['horse'] ?? 0,
        'mule': counts['mule'] ?? 0,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception("Failed to update livestock: $e");
    }
  }

  // 3. Record Treatment and Drugs
  Future<void> recordTreatment({
    required String ownerId,
    required String serviceType,
    required String speciesTreated, 
    required String notes,
    required List<Map<String, String>> drugs,
  }) async {
    try {
      final serviceResponse = await supabase.from('service_records').insert({
        'owner_id': ownerId,
        'service_type': serviceType,
        'species_treated': speciesTreated,
        'notes': notes,
      }).select().single();

      final serviceId = serviceResponse['id'];

      if (drugs.isNotEmpty) {
        final drugEntries = drugs.map((drug) => {
          'service_record_id': serviceId,
          'drug_name': drug['drug_name'],
          'quantity_used': double.tryParse(drug['quantity'] ?? '1') ?? 1.0,
        }).toList();

        await supabase.from('service_drugs').insert(drugEntries);
      }
    } catch (e) {
      throw Exception("Failed to record treatment: $e");
    }
  }

  // 4. Fetch the Professional Summary with Month Filtering
  Future<List<Map<String, dynamic>>> getProfessionalSummary(String weredaId, DateTime selectedMonth) async {
    try {
      final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

      final response = await supabase
          .from('wereda_final_summary')
          .select('*')
          .eq('wereda_id', weredaId)
          .gte('record_date', firstDay.toIso8601String())
          .lte('record_date', lastDay.toIso8601String());
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Database Error: $e");
      throw Exception("Failed to fetch summary: $e");
    }
  }

  // 5. Fetch Disease Trends
  Future<List<Map<String, dynamic>>> getTopDiseases() async {
    try {
      final response = await supabase
          .from('regional_epidemiology_report') 
          .select('*')
          .order('case_count', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception("Failed to fetch disease trends: $e");
    }
  }

  // 6. Updated: Fetch Drug Summary using existing view columns
  Future<List<Map<String, dynamic>>> getRegionalDrugSummary() async {
    try {
      // We are fetching 'diagnosis' to use as the label since 'drug_name' is missing
      final response = await supabase
          .from('regional_epidemiology_report')
          .select('diagnosis, total_medication_units'); 
      
      return response.map((item) => {
        'drug_name': item['diagnosis'] ?? 'General Meds', // Use diagnosis as the name for now
        'total_medication_units': item['total_medication_units']
      }).toList();
    } catch (e) {
      print("Drug Summary Error: $e");
      return []; // Return empty list instead of crashing the screen
    }
  }

  // 7. NEW: Fetch Drug Usage Stats for a specific Month
  // This fixes the "getDrugUsageStats isn't defined" error!
  Future<List<Map<String, dynamic>>> getDrugUsageStats(DateTime selectedMonth) async {
    try {
      final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
      final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

      // Querying the junction table and joining the record date
      final response = await supabase
          .from('service_drugs')
          .select('drug_name, quantity_used, service_records!inner(created_at)')
          .gte('service_records.created_at', firstDay.toIso8601String())
          .lte('service_records.created_at', lastDay.toIso8601String());

      // Aggregate counts in Dart for quick processing
      final Map<String, int> counts = {};
      for (var item in response) {
        final name = item['drug_name']?.toString() ?? 'Unknown';
        counts[name] = (counts[name] ?? 0) + 1;
      }

      return counts.entries.map((e) => {
        'name': e.key,
        'usage_count': e.value,
      }).toList();
    } catch (e) {
      print("Error in Drug Usage Stats: $e");
      return [];
    }
  }

  // 8. Search Owners
  Future<List<Map<String, dynamic>>> searchOwners(String query) async {
    try {
      final response = await supabase
          .from('owners')
          .select('id, name, phone, kebele_name, wereda_id') 
          .or('name.ilike.%$query%,phone.ilike.%$query%')
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception("Search failed: $e");
    }
  }

  // 9. Location Fetchers
  Future<List<Map<String, dynamic>>> getZones() async => 
      await (supabase.from('zones').select().order('name'));

  Future<List<Map<String, dynamic>>> getWeredas(String zoneId) async => 
      await (supabase.from('weredas').select().eq('zone_id', zoneId).order('name'));
}