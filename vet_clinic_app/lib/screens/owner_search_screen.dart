import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'livestock_count_screen.dart';

class OwnerSearchScreen extends StatefulWidget {
  const OwnerSearchScreen({super.key});

  @override
  State<OwnerSearchScreen> createState() => _OwnerSearchScreenState();
}

class _OwnerSearchScreenState extends State<OwnerSearchScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  void _performSearch() async {
    if (_searchController.text.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await _dbService.searchOwners(_searchController.text);
      setState(() => _results = results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find Livestock Owner")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by Name or Phone",
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _performSearch),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final owner = _results[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(owner['name']),
                  subtitle: Text("Phone: ${owner['phone']} | Kebele: ${owner['kebeles']['name']}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LivestockCountScreen(
                          ownerId: owner['id'],
                          ownerName: owner['name'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}