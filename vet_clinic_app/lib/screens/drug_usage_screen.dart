import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DrugUsageScreen extends StatelessWidget {
  const DrugUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(title: const Text("Clinic Drug Usage")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbService.getDrugUsageStats(DateTime.now()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final stats = snapshot.data ?? [];

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Total Prescriptions by Medicine",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: stats.length,
                  itemBuilder: (context, index) {
                    final item = stats[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.medication, color: Colors.redAccent),
                        title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(item['usage_count'].toString()),
                        ),
                        subtitle: const Text("Prescribed this month"),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}