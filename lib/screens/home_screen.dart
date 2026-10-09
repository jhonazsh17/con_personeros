import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'registro_acta_screen.dart';
import 'lista_actas_screen.dart';
import 'votos_por_candidato_screen.dart';
import '../core/theme/app_colors.dart';
import '../widgets/user_profile_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalVotos = 0;
  String _dni = '';
  String _nombre = '';
  String _rol = 'personero';
  bool _isLoading = true;
  bool _actaRegistrada = false;

  bool get _puedeVerResultados => _rol == 'admin' || _rol == 'coordinador';
  bool get _puedeRegistrarActa =>
      _rol == 'admin' || (_rol == 'personero' && !_actaRegistrada);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = StorageService();
    var dni = '';
    var nombre = '';
    var rol = 'personero';
    var totalVotos = 0;
    var actaRegistrada = false;

    try {
      dni = await storage.getDni() ?? '';
      nombre = await storage.getNombre() ?? '';
      rol = await storage.getRol() ?? 'personero';

      if (rol == 'admin' || rol == 'coordinador') {
        totalVotos = await storage.getTotalVotos();
      } else if (rol == 'personero' && dni.isNotEmpty) {
        actaRegistrada = await ApiService.hasRegisteredActa(
          dni: dni,
          role: rol,
        );
      }
    } catch (_) {
      totalVotos = 0;
    }

    if (mounted) {
      setState(() {
        _dni = dni;
        _nombre = nombre;
        _rol = rol;
        _totalVotos = totalVotos;
        _actaRegistrada = actaRegistrada;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: _isLoading
          ? null
          : AppBar(
              title: const Text('Con Personeros'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await StorageService().clearDni();
                    if (mounted) {
                      navigator.pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                ),
              ],
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            )
          : Column(
              children: [
                UserProfileHeader(nombre: _nombre, dni: _dni, rol: _rol),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            children: [
                              if (_rol == 'personero' && _actaRegistrada) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    border: Border.all(
                                      color: Colors.red.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red.shade800,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '¡IMPORTANTE!',
                                              style: TextStyle(
                                                color: Colors.red.shade900,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Ya registraste un acta.',
                                              style: TextStyle(
                                                color: Colors.red.shade900,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_puedeVerResultados) ...[
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent.withValues(
                                      alpha: 0.3,
                                    ),
                                    border: Border.all(
                                      color: AppColors.primaryLight,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryLight
                                            .withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                      vertical: 24.0,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Total de Votos Válidos',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$_totalVotos',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 44,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                              if (_puedeRegistrarActa)
                                SizedBox(
                                  width: isDesktop ? 440 : double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegistroActaScreen(),
                                        ),
                                      );
                                      _loadData();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: AppColors.primaryDark,
                                    ),
                                    child: const Text(
                                      'REGISTRAR CONTEO DE ACTA',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_puedeVerResultados) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: isDesktop ? 440 : double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ListaActasScreen(),
                                        ),
                                      );
                                      _loadData();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: AppColors.primaryDark,
                                    ),
                                    child: const Text(
                                      'VER ACTAS REGISTRADAS',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: isDesktop ? 440 : double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const VotosPorCandidatoScreen(),
                                        ),
                                      );
                                      _loadData();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: AppColors.primaryDark,
                                    ),
                                    child: const Text(
                                      'VER VOTOS POR CANDIDATO',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
