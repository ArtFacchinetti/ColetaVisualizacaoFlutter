class Localizacao {
  const Localizacao({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.precisao,
    required this.instante,
  });

  final int? id;
  final double latitude;
  final double longitude;
  final double precisao;
  final DateTime instante;

  factory Localizacao.fromMap(Map<String, Object?> map) => Localizacao(
    id: map['id'] as int?,
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    precisao: (map['precisao'] as num).toDouble(),
    instante: DateTime.parse(map['instante'] as String).toUtc(),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'precisao': precisao,
    'instante': instante.toUtc().toIso8601String(),
  };
}
