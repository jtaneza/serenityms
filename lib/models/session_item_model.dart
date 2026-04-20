class SessionItemModel {
  final String name;
  final String service;
  final String status;
  final String time;
  final bool placeholderAvatar;

  const SessionItemModel({
    required this.name,
    required this.service,
    required this.status,
    required this.time,
    this.placeholderAvatar = false,
  });
}