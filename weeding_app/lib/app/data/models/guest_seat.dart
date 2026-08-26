class GuestSeat {
  final String id;
  final String guestId;
  final String tableId;
  final String chairId;
  final String tableLabel;
  final int chairNumber;
  final DateTime assignedAt;

  GuestSeat({
    required this.id,
    required this.guestId,
    required this.tableId,
    required this.chairId,
    required this.tableLabel,
    required this.chairNumber,
    DateTime? assignedAt,
  }) : assignedAt = assignedAt ?? DateTime.now();

  factory GuestSeat.fromJson(Map<String, dynamic> json) {
    return GuestSeat(
      id: json['id'] as String,
      guestId: json['guest_id'] as String,
      tableId: json['table_id'] as String,
      chairId: (json['chair_id'] ?? json['id']) as String,
      tableLabel:
          (json['table_label'] ??
                  (json['seating_tables'] as Map<String, dynamic>?)?['label'] ??
                  '')
              as String,
      chairNumber: json['chair_number'] as int,
      assignedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'table_id': tableId,
      'chair_id': chairId,
      'table_label': tableLabel,
      'chair_number': chairNumber,
      'created_at': assignedAt.toIso8601String(),
    };
  }
}
