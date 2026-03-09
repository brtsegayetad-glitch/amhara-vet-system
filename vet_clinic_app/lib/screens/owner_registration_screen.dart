import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/owner_model.dart';
import 'livestock_count_screen.dart';

class OwnerRegistrationScreen extends StatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  State<OwnerRegistrationScreen> createState() => _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState extends State<OwnerRegistrationScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController kebeleController = TextEditingController();
  final TextEditingController _weredaSearchController = TextEditingController();

  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _filteredWeredas = [];

  String? _selectedZoneId;
  Map<String, dynamic>? _selectedWereda; // Stores both ID and Name
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchZones();
  }

  Future<void> _fetchZones() async {
    try {
      final data = await _dbService.getZones();
      if (mounted) setState(() => _zones = data);
    } catch (e) {
      _showSnackBar("Connection error. Check internet.", isError: true);
    }
  }

  void _onZoneChanged(String? zoneId) async {
    setState(() {
      _selectedZoneId = zoneId;
      _selectedWereda = null;
      _weredaSearchController.clear(); // Clear the search when zone changes
      _filteredWeredas = [];
    });

    if (zoneId != null) {
      try {
        final data = await _dbService.getWeredas(zoneId);
        setState(() => _filteredWeredas = data);
      } catch (e) {
        _showSnackBar("Could not load Weredas", isError: true);
      }
    }
  }

  Future<void> _saveOwner() async {
  if (!_formKey.currentState!.validate()) return;
  if (_selectedWereda == null) return;

  setState(() => _isLoading = true);

  try {
    // 1. Save the owner
    final savedOwnerData = await _dbService.registerOwner(
      Owner(
        name: ownerNameController.text.trim(),
        phone: phoneController.text.trim(),
        weredaId: _selectedWereda!['id'],
        kebeleName: kebeleController.text.trim(),
      ),
    );

    // 2. STOP the spinning here so the user knows the save finished
    setState(() => _isLoading = false);

    // 3. Move to the next screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LivestockCountScreen(
            ownerId: savedOwnerData['id'],
            ownerName: ownerNameController.text.trim(),
          ),
        ),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
    );
  }
}

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Farmer Registration"), backgroundColor: Colors.blue.shade900, foregroundColor: Colors.white),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel("PERSONAL INFORMATION"),
                    TextFormField(
                      controller: ownerNameController,
                      decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                      validator: (v) => v!.isEmpty ? "Name required" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 30),
                    _sectionLabel("LOCATION (AMHARA REGION)"),

                    // 1. ZONE DROPDOWN
                    DropdownButtonFormField<String>(
                      initialValue: _selectedZoneId,
                      hint: const Text("Select Zone"),
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "1. Zone"),
                      items: _zones.map((z) => DropdownMenuItem(value: z['id'].toString(), child: Text(z['name']))).toList(),
                      onChanged: _onZoneChanged,
                    ),
                    const SizedBox(height: 20),

                    // 2. SEARCHABLE WEREDA AUTOCOMPLETE
                    const Text(" 2. Search Wereda", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    const SizedBox(height: 5),
                    Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (option) => option['name'],
                      optionsBuilder: (TextEditingValue textValue) {
                        if (textValue.text.isEmpty || _selectedZoneId == null) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return _filteredWeredas.where((w) => 
                            w['name'].toLowerCase().contains(textValue.text.toLowerCase()));
                      },
                      onSelected: (selection) {
                        setState(() => _selectedWereda = selection);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        // Link the external controller so we can clear it manually
                        if (_weredaSearchController.text.isEmpty && controller.text.isNotEmpty) {
                           // sync
                        }
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: _selectedZoneId == null ? "Select Zone first" : "Start typing wereda name...",
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.search),
                            enabled: _selectedZoneId != null,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),

                    // 3. MANUAL KEBELE ENTRY
                    TextFormField(
                      controller: kebeleController,
                      decoration: const InputDecoration(
                        labelText: "3. Kebele Name", 
                        hintText: "Enter Kebele manually",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on)
                      ),
                      validator: (v) => v!.isEmpty ? "Kebele required" : null,
                    ),
                    
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveOwner,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(18), 
                        backgroundColor: Colors.blue.shade900, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      child: const Center(child: Text("PROCEED TO LIVESTOCK COUNT", style: TextStyle(fontWeight: FontWeight.bold))),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12)),
  );
}