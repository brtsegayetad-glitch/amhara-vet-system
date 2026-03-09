import 'package:flutter/material.dart';
import 'owner_registration_screen.dart';
import 'owner_search_screen.dart';
import 'regional_dashboard_screen.dart';
import 'monthly_report_screen.dart'; // 1. Added this import

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Amhara Vet Clinic System"),
        centerTitle: true,
        elevation: 2,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.pets, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "Clinic Management",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Region: Amhara",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OwnerSearchScreen()),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text("FIND EXISTING OWNER"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OwnerRegistrationScreen()),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text("REGISTER NEW OWNER"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),

            const Divider(height: 40),

            // 2. NEW: OFFICIAL MONTHLY REPORT BUTTON
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MonthlyReportScreen()),
                );
              },
              icon: const Icon(Icons.assignment),
              label: const Text("GENERATE MONTHLY WEREDA REPORT"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.deepPurple.shade700,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
               MaterialPageRoute(builder: (context) => RegionalDashboardScreen()),
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text("DRUG USAGE DASHBOARD"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}