class Candidato {
  final String nombre;
  final String partido;
  int votos;

  Candidato({
    required this.nombre,
    required this.partido,
    this.votos = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'partido': partido,
      'votos': votos,
    };
  }

  factory Candidato.fromJson(Map<String, dynamic> json) {
    return Candidato(
      nombre: json['nombre'] as String? ?? '',
      partido: json['partido'] as String? ?? '',
      votos: json['votos'] as int? ?? 0,
    );
  }
}

class Acta {
  final String id;
  final String numeroActa;
  final String lugar;
  final List<Candidato> candidatos;
  final DateTime fecha;

  Acta({
    required this.id,
    required this.numeroActa,
    required this.lugar,
    required this.candidatos,
    required this.fecha,
  });

  int get totalVotos {
    return candidatos.fold(0, (sum, candidato) => sum + candidato.votos);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numeroActa': numeroActa,
      'lugar': lugar,
      'candidatos': candidatos.map((c) => c.toJson()).toList(),
      'fecha': fecha.toIso8601String(),
    };
  }

  factory Acta.fromJson(Map<String, dynamic> json) {
    return Acta(
      id: json['id'],
      numeroActa: json['numeroActa'],
      lugar: json['lugar'],
      candidatos: (json['candidatos'] as List)
          .map((c) => Candidato.fromJson(c))
          .toList(),
      fecha: DateTime.parse(json['fecha']),
    );
  }
}
