import 'package:flutter/material.dart';
import '../services/database_service.dart';

class RegionalDashboardScreen extends StatelessWidget {
  const RegionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Amhara Regional Stats"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbService.getRegionalDrugSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final rawData = snapshot.data ?? [];

          // --- AGGREGATION LOGIC: Squashing duplicates into a SUM ---
          Map<String, double> aggregatedData = {};
          for (var item in rawData) {
            // Using 'drug_name' or 'diagnosis' as the key to group sums
            String key = item['drug_name'] ?? item['diagnosis'] ?? "Unknown";
            double units = double.tryParse(item['total_medication_units'].toString()) ?? 0.0;
            
            aggregatedData[key] = (aggregatedData[key] ?? 0.0) + units;
          }

          // Convert to a sorted list (Highest usage first)
          final sortedStats = aggregatedData.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Top Medicines Consumed", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 5),
                const Text(
                  "Aggregated usage across all Weredas (Units/ML)",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 25),
                
                Expanded(
                  child: sortedStats.isEmpty 
                    ? _buildNoDataState()
                    : ListView.builder(
                        itemCount: sortedStats.length,
                        itemBuilder: (context, index) {
                          final entry = sortedStats[index];
                          final String drugName = entry.key;
                          final double totalUnits = entry.value;
                          
                          // Dynamic bar width logic based on the highest value
                          double maxVal = sortedStats.first.value;
                          double screenWidth = MediaQuery.of(context).size.width - 60;
                          double usageWidth = maxVal > 0 
                              ? (totalUnits / maxVal) * screenWidth 
                              : 20.0;

                          return _buildDrugStatRow(drugName, totalUnits, usageWidth.clamp(20.0, screenWidth));
                        },
                      ),
                ),
                
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text("RETURN TO HOME"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrugStatRow(String name, double units, double width) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text("${units.toStringAsFixed(1)} Units", 
                style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 14,
                width: width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: units > 50 ? [Colors.red, Colors.orange] : [Colors.green, Colors.lightGreen]
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text("No medication data has been synced yet."),
        ],
      ),
    );
  }
}