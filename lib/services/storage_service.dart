import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class StorageService {
  static const String _dniKey = 'dni';

  Future<void> saveDni(String dni) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dniKey, dni);
  }

  Future<String?> getDni() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dniKey);
  }

  Future<void> saveNombre(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
  }

  Future<String?> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre');
  }

  Future<void> saveRol(String rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rol', rol);
  }

  Future<String?> getRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rol');
  }

  Future<void> clearDni() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dniKey);
    await prefs.remove('nombre');
    await prefs.remove('rol');
    await prefs.remove('isAdmin');
  }

  // Guardar acta usando API
  Future<void> saveActa({
    required String numeroActa,
    required String lugar,
    required Map<String, int> candidatos,
    required int nulos,
    required int blancos,
    required int noVotantes,
    required String dniUsuario,
  }) async {
    await ApiService.saveActa(
      numeroActa: numeroActa,
      lugar: lugar,
      candidatos: candidatos,
      nulos: nulos,
      blancos: blancos,
      noVotantes: noVotantes,
      dniUsuario: dniUsuario,
    );
  }

  Future<void> updateActa({
    required String actaId,
    required String lugar,
    required Map<String, int> candidatos,
    required int nulos,
    required int blancos,
    required int noVotantes,
    required String dniUsuario,
  }) async {
    await ApiService.updateActa(
      actaId: actaId,
      lugar: lugar,
      candidatos: candidatos,
      nulos: nulos,
      blancos: blancos,
      noVotantes: noVotantes,
      dniUsuario: dniUsuario,
    );
  }

  // Obtener actas usando API
  Future<List<Map<String, dynamic>>> getActas() async {
    return await ApiService.getActas();
  }

  // Obtener total de votos usando API
  Future<int> getTotalVotos() async {
    return await ApiService.getTotalVotos();
  }

  // Obtener votos por candidato usando API
  Future<List<Map<String, dynamic>>> getCandidateVotes() async {
    return await ApiService.getCandidateVotes();
  }
}
