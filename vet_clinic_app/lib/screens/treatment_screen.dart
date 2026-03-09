import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TreatmentScreen extends StatefulWidget {
  final String ownerId;
  final String ownerName;

  const TreatmentScreen({super.key, required this.ownerId, required this.ownerName});

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _drugNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();

  String _selectedService = 'treatment';
  String? _selectedSpecies; 
  final List<Map<String, String>> _addedDrugs = [];
  bool _isLoading = false;

  // Standardized Ethiopian Veterinary Drug Catalogue
  final List<String> _ethiopianDrugCatalogue = [
    'Oxytetracycline LA', 
    'Ivermectin Injection', 
    'Albendazole Bolus', 
    'Penicillin-Streptomycin', 
    'Diminazene Aceturate', 
    'Triclabendazole',
    'Rabies Vaccine', 
    'LSD Vaccine',
    'Anthrax Vaccine',
    'Multivitamin Injection'
  ];

  // 1. Update Catalogue Entry
void _addFromCatalogue(String drugName) {
  setState(() {
    _addedDrugs.add({
      'drug_name': drugName,
      'quantity': '1', // Default quantity
    });
  });
}

// 2. Update Manual Entry (Crucial Change!)
void _addManualDrug() {
    if (_drugNameController.text.trim().isNotEmpty) {
      setState(() {
        _addedDrugs.add({
          'drug_name': _drugNameController.text.trim(),
          'quantity': _dosageController.text.trim(), // CHANGE 'dosage' TO 'quantity'
        });
        _drugNameController.clear();
        _dosageController.clear();
      });
    }
  }

  Future<void> _saveTreatment() async {
    if (_selectedSpecies == null) {
      _showError("Please select the species being treated");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _dbService.recordTreatment(
        ownerId: widget.ownerId,
        serviceType: _selectedService,
        speciesTreated: _selectedSpecies!,
        notes: _notesController.text,
        drugs: _addedDrugs,
      );
      
      _showSuccess("Case submitted to Regional Database");
      Navigator.pop(context); 
    } catch (e) {
      _showError("Database Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Treatment: ${widget.ownerName}")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("I. CASE DETAILS"),
                _buildDropdown("Service Category", _selectedService, 
                  ['treatment', 'vaccination', 'deworming'], (val) => setState(() => _selectedService = val!)),
                const SizedBox(height: 15),
                _buildDropdown("Species Treated", _selectedSpecies, 
                  ['cattle', 'sheep', 'goat', 'poultry', 'donkey', 'horse', 'mule'], (val) => setState(() => _selectedSpecies = val!)),
                const SizedBox(height: 15),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Diagnosis/Notes", border: OutlineInputBorder()),
                ),
                
                const Divider(height: 40, thickness: 1.5),
                _sectionHeader("II. STANDARD DRUG CATALOGUE"),
                const Text("Tap to add common Ethiopian medicines:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _ethiopianDrugCatalogue.map((drug) => ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text(drug),
                    onPressed: () => _addFromCatalogue(drug),
                    backgroundColor: Colors.blue.shade50,
                  )).toList(),
                ),

                const SizedBox(height: 25),
                _sectionHeader("III. OTHER / MANUAL ENTRY"),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _drugNameController, decoration: const InputDecoration(labelText: "Drug Name"))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _dosageController, decoration: const InputDecoration(labelText: "Dosage"))),
                    IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 30), onPressed: _addManualDrug),
                  ],
                ),

                const SizedBox(height: 20),
                if (_addedDrugs.isNotEmpty) ...[
                  const Text("Selected Medications:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: _addedDrugs.asMap().entries.map((entry) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.medication),
                          title: Text(entry.value['drug_name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Quantity: ${entry.value['quantity'] ?? '1'}"),
                          trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), 
                            onPressed: () => setState(() => _addedDrugs.removeAt(entry.key))),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _saveTreatment,
                  icon: const Icon(Icons.cloud_done),
                  label: const Text("UPLOAD TREATMENT RECORD"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
  );

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}