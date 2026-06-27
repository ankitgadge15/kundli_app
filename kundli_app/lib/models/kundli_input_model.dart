class KundliInput {
  final String name;
  final DateTime birthDateTime;
  final double timezoneOffset;
  final String place;
  final double latitude;
  final double longitude;

  const KundliInput({
    required this.name,
    required this.birthDateTime,
    required this.timezoneOffset,
    required this.place,
    required this.latitude,
    required this.longitude,
  });
}