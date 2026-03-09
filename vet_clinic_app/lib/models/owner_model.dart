class Owner {
  final String? id;
  final String name;
  final String phone;
  final String weredaId;    // New Anchor
  final String kebeleName;  // New Manual Entry

  Owner({
    this.id,
    required this.name,
    required this.phone,
    required this.weredaId,
    required this.kebeleName,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'wereda_id': weredaId,
      'kebele_name': kebeleName,
    };
  }
}