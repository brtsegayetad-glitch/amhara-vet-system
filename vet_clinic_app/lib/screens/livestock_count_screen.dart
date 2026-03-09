import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'treatment_screen.dart';

class LivestockCountScreen extends StatefulWidget {
  final String ownerId;
  final String ownerName;

  const LivestockCountScreen({super.key, required this.ownerId, required this.ownerName});

  @override
  State<LivestockCountScreen> createState() => _LivestockCountScreenState();
}

class _LivestockCountScreenState extends State<LivestockCountScreen> {
  final DatabaseService _dbService = DatabaseService();
  
  // controllers organized by the species defined in your requirements
  final Map<String, TextEditingController> _controllers = {
    'cattle': TextEditingController(text: '0'),
    'sheep': TextEditingController(text: '0'),
    'goat': TextEditingController(text: '0'),
    'poultry': TextEditingController(text: '0'),
    'donkey': TextEditingController(text: '0'),
    'horse': TextEditingController(text: '0'),
    'mule': TextEditingController(text: '0'),
  };

  bool _isSaving = false;

  Future<void> _saveCounts() async {
    setState(() => _isSaving = true);
    
    Map<String, int> finalCounts = {};
    _controllers.forEach((species, controller) {
      // Ensure we don't save negative numbers
      int value = int.tryParse(controller.text) ?? 0;
      finalCounts[species] = value < 0 ? 0 : value;
    });

    try {
      // 1. Save the population data to Supabase using the upsert logic
      await _dbService.updateLivestockCounts(widget.ownerId, finalCounts);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Population updated! Moving to treatment..."),
          backgroundColor: Colors.green,
        )
      );

      // 2. AUTOMATIC WORKFLOW: Move to Treatment Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TreatmentScreen(
            ownerId: widget.ownerId,
            ownerName: widget.ownerName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // This is usually where the "ON CONFLICT" error appears if SQL isn't set up
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Database Error: $e"), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Livestock: ${widget.ownerName}"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Enter the total current population for this owner. This helps the Bureau track regional growth.",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Improved Input Grid/List
              ..._controllers.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key.toUpperCase(), 
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.numbers),
                    suffixText: "Heads",
                  ),
                  keyboardType: TextInputType.number,
                  // Automatically select all text on tap so vet can just type over the '0'
                  onTap: () => entry.value.selection = TextSelection(
                    baseOffset: 0, 
                    extentOffset: entry.value.text.length
                  ),
                ),
              )),
              
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saveCounts,
                icon: const Icon(Icons.check_circle),
                label: const Text("SAVE & RECORD TREATMENT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
    );
  }
}