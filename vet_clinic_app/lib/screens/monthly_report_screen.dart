import 'package:flutter/material.dart';
import '../services/database_service.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final dbService = DatabaseService();
  String? selectedZoneId;
  String? selectedWeredaId;
  DateTime selectedMonth = DateTime.now(); // Required for your new DatabaseService logic

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Wereda Report")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildZoneDropdown()),
                const SizedBox(width: 10),
                Expanded(child: _buildWeredaDropdown()),
              ],
            ),
            const Divider(height: 30),
            Expanded(
              child: selectedWeredaId == null
                  ? const Center(child: Text("Please select a Wereda to view the report"))
                  : FutureBuilder<List<Map<String, dynamic>>>(
                      // Ensure you pass the month so the sum is for the current month
                      future: dbService.getProfessionalSummary(selectedWeredaId!, selectedMonth),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                        
                        return _buildReportTable(snapshot.data ?? []);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneDropdown() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: dbService.getZones(),
      builder: (context, snapshot) {
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Zone"),
          initialValue: selectedZoneId,
          items: snapshot.data?.map((z) => DropdownMenuItem(
            value: z['id'].toString(),
            child: Text(z['name']),
          )).toList(),
          onChanged: (val) => setState(() {
            selectedZoneId = val;
            selectedWeredaId = null;
          }),
        );
      },
    );
  }

  Widget _buildWeredaDropdown() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: selectedZoneId == null ? Future.value([]) : dbService.getWeredas(selectedZoneId!),
      builder: (context, snapshot) {
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: "Wereda"),
          initialValue: selectedWeredaId,
          items: snapshot.data?.map((w) => DropdownMenuItem(
            value: w['id'].toString(),
            child: Text(w['name']),
          )).toList(),
          onChanged: (val) => setState(() => selectedWeredaId = val),
        );
      },
    );
  }

Widget _buildReportTable(List<Map<String, dynamic>> stats) {
  if (stats.isEmpty) return const Center(child: Text("No data for this selection."));

  // --- THE SUMMING ENGINE ---
  // We group ONLY by Species + Diagnosis so that different Kebeles are SUMMED together.
  Map<String, Map<String, dynamic>> aggregatedMap = {};
  Map<String, int> speciesCounts = {};
  int grandTotal = 0;

  for (var row in stats) {
    String species = row['species_treated']?.toString().toUpperCase() ?? 'OTHER';
    String diagnosis = row['diagnosis'] ?? 'General';
    
    // The key NO LONGER includes the Kebele name, so all Kebeles merge together!
    String groupKey = "${species}_$diagnosis";

    int count = int.tryParse(row['total_animals_served'].toString()) ?? 0;
    double meds = double.tryParse(row['total_medication_sum'].toString()) ?? 0.0;

    if (aggregatedMap.containsKey(groupKey)) {
      aggregatedMap[groupKey]!['total_animals_served'] += count;
      aggregatedMap[groupKey]!['total_medication_sum'] += meds;
    } else {
      aggregatedMap[groupKey] = {
        'species_treated': species,
        'diagnosis': diagnosis,
        'total_animals_served': count,
        'total_medication_sum': meds,
      };
    }

    // Top Blue Box Totals
    speciesCounts[species] = (speciesCounts[species] ?? 0) + count;
    grandTotal += count;
  }

  List<Map<String, dynamic>> summedData = aggregatedMap.values.toList();

  return SingleChildScrollView(
    child: Column(
      children: [
        // --- TOP BLUE SUMMARY BOX ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Text("TOTAL ANIMALS TREATED: $grandTotal", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Divider(),
              Wrap(
                spacing: 20,
                children: speciesCounts.entries.map((e) => Column(
                  children: [
                    Text(e.key, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text(e.value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // --- THE TABLE (Now showing SUMS instead of individual Kebeles) ---
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            const TableRow(decoration: BoxDecoration(color: Colors.blueGrey), children: [
              _TableCell("Species", isHeader: true),
              _TableCell("Diagnosis", isHeader: true),
              _TableCell("Total Count", isHeader: true), // This will now show the SUM
              _TableCell("Total Meds", isHeader: true),
            ]),
            ...summedData.map((row) => TableRow(children: [
              _TableCell(row['species_treated']),
              _TableCell(row['diagnosis']),
              _TableCell(row['total_animals_served'].toString(), isBold: true),
              _TableCell("${row['total_medication_sum']} Units"),
            ])),
          ],
        ),
      ],
    ),
  );
}
}
class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isBold;
  const _TableCell(this.text, {this.isHeader = false, this.isBold = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: TextStyle(
        color: isHeader ? Colors.white : Colors.black,
        fontWeight: (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      )),
    );
  }
}