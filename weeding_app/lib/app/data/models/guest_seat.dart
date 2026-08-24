class GuestSeat {
  final String id;
  final String guestId;
  final String tableId;
  final String chairId;
  final DateTime assignedAt;

  GuestSeat({
    required this.id,
    required this.guestId,
    required this.tableId,
    required this.chairId,
    DateTime? assignedAt,
  }) : assignedAt = assignedAt ?? DateTime.now();

  factory GuestSeat.fromJson(Map<String, dynamic> json) {
    return GuestSeat(
      id: json['id'] as String,
      guestId: json['guest_id'] as String,
      tableId: json['table_id'] as String,
      chairId: json['chair_id'] as String,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'table_id': tableId,
      'chair_id': chairId,
      'assigned_at': assignedAt.toIso8601String(),
    };
  }
}
