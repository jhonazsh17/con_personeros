import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String host = '4g1vps5k71.execute-api.us-east-1.amazonaws.com';
  static const String stage = 'dev';

  static Future<bool> isNewVotingSystemEnabled() async {
    final response = await http
        .get(Uri.https(host, '$stage/feature-flags/enableNewVotingSystem'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) return false;

    try {
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final data = result['data'];
      return result['success'] == true &&
          data is Map<String, dynamic> &&
          data['featureName'] == 'enableNewVotingSystem' &&
          data['enabled'] == true;
    } on FormatException {
      return false;
    } on TypeError {
      return false;
    }
  }

  static Future<Map<String, dynamic>> login({required String dni}) async {
    final response = await http
        .post(
          Uri.https(host, '$stage/users/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'dni': dni}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 404) {
      throw Exception('Este DNI no está autorizado.');
    }

    final Map<String, dynamic> result;
    try {
      result = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta inválida.');
    } on TypeError {
      throw Exception('El servidor devolvió una respuesta inválida.');
    }

    if (response.statusCode >= 500) {
      throw Exception(
        'No se pudo conectar con el servicio de inicio de sesión.',
      );
    }

    if (response.statusCode != 200 || result['success'] != true) {
      if (result['success'] == false) {
        throw Exception('Este DNI no está autorizado.');
      }
      throw Exception(
        result['message'] as String? ?? 'No se pudo iniciar sesión.',
      );
    }

    final data = result['data'];
    if (data is! Map<String, dynamic> ||
        data['nombre'] is! String ||
        data['rol'] is! String ||
        data['dni'] is! String) {
      throw Exception('El servidor devolvió datos de usuario inválidos.');
    }

    return data;
  }

  static Future<bool> hasRegisteredActa({
    required String dni,
    required String role,
  }) async {
    final response = await http
        .post(
          Uri.https(host, '$stage/users/acta-registered'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'dni': dni, 'role': role}),
        )
        .timeout(const Duration(seconds: 30));

    final Map<String, dynamic> result;
    try {
      result = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('El servidor devolvió una respuesta inválida.');
    } on TypeError {
      throw Exception('El servidor devolvió una respuesta inválida.');
    }

    if (response.statusCode != 200 || result['success'] != true) {
      throw Exception('No se pudo verificar el registro del acta.');
    }

    final data = result['data'];
    if (data is! Map<String, dynamic> ||
        data['dni'] is! String ||
        data['hasRegisteredActa'] is! bool) {
      throw Exception('El servidor devolvió datos de registro inválidos.');
    }

    if (data['dni'] != dni) {
      throw Exception('El servidor devolvió un DNI distinto al consultado.');
    }

    return data['hasRegisteredActa'] as bool;
  }

  // Guardar una nueva acta
  static Future<Map<String, dynamic>> saveActa({
    required String numeroActa,
    required String lugar,
    required Map<String, int> candidatos,
    required int nulos,
    required int blancos,
    required int noVotantes,
    required String dniUsuario,
  }) async {
    try {
      final response = await http
          .post(
            Uri.https(host, '$stage/records'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'numeroActa': numeroActa,
              'lugar': lugar,
              'votos': {
                'candidatos': candidatos,
                'nulos': nulos,
                'blancos': blancos,
              },
              'dniUsuario': dniUsuario,
              'noVotantes': noVotantes,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Error al guardar acta: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateActa({
    required String actaId,
    required String lugar,
    required Map<String, int> candidatos,
    required int nulos,
    required int blancos,
    required int noVotantes,
    required String dniUsuario,
  }) async {
    final response = await http
        .put(
          Uri.https(host, '$stage/records/${Uri.encodeComponent(actaId)}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'lugar': lugar,
            'votos': {
              'candidatos': candidatos,
              'nulos': nulos,
              'blancos': blancos,
            },
            'noVotantes': noVotantes,
            'dniUsuario': dniUsuario,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error al actualizar acta: ${response.statusCode} - ${response.body}',
      );
    }

    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Obtener todas las actas
  static Future<List<Map<String, dynamic>>> getActas() async {
    try {
      final response = await http.get(Uri.https(host, '$stage/records'));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final data = result['data'] is Map<String, dynamic>
            ? result['data'] as Map<String, dynamic>
            : result;
        final actas = data['actas'];
        if (actas is! List) {
          throw const FormatException(
            'La respuesta no contiene una lista de actas.',
          );
        }
        return actas
            .map((acta) => Map<String, dynamic>.from(acta as Map))
            .toList();
      } else {
        throw Exception('Error al obtener actas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener votos por candidato
  static Future<List<Map<String, dynamic>>> getCandidateVotes() async {
    try {
      final response = await http.get(
        Uri.https(host, '$stage/votes/candidates'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['candidates']);
      } else {
        throw Exception('Error al obtener votos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Calcular total de votos
  static Future<int> getTotalVotos() async {
    try {
      final actas = await getActas();
      var total = 0;
      for (final acta in actas) {
        final items = acta['items'];
        if (items is! List) continue;

        for (final item in items) {
          if (item is! Map<String, dynamic>) continue;
          final tipo = item['tipo']?.toString().toLowerCase();
          if (tipo != 'candidato') continue;

          final votos = item['votos'];
          if (votos is num) total += votos.toInt();
        }
      }
      return total;
    } catch (e) {
      throw Exception('Error al calcular total: $e');
    }
  }
}
