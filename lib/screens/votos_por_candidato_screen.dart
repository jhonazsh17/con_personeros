import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../core/theme/app_colors.dart';
import '../widgets/user_profile_header.dart';

class VotosPorCandidatoScreen extends StatefulWidget {
  const VotosPorCandidatoScreen({super.key});

  @override
  State<VotosPorCandidatoScreen> createState() =>
      _VotosPorCandidatoScreenState();
}

class _VotosPorCandidatoScreenState extends State<VotosPorCandidatoScreen> {
  String _nombre = '';
  String _dni = '';
  String _rol = 'personero';
  Map<String, int> _votosPorCandidato = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNombre();
    _loadVotos();
  }

  Future<void> _loadNombre() async {
    final nombre = await StorageService().getNombre();
    final dni = await StorageService().getDni();
    final rol = await StorageService().getRol();
    if (mounted) {
      setState(() {
        _nombre = nombre ?? '';
        _dni = dni ?? '';
        _rol = rol ?? 'personero';
      });
    }
  }

  Future<void> _loadVotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final candidates = await StorageService().getCandidateVotes();
      final votosMap = <String, int>{};

      for (var candidate in candidates) {
        votosMap[candidate['nombre']] = candidate['totalVotos'];
      }

      if (mounted) {
        setState(() {
          _votosPorCandidato = votosMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar votos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votos por Candidato')),
      body: Column(
        children: [
          UserProfileHeader(nombre: _nombre, dni: _dni, rol: _rol),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _votosPorCandidato.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.how_to_vote,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay votos registrados',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _votosPorCandidato.length,
                        itemBuilder: (context, index) {
                          final entries = _votosPorCandidato.entries.toList();
                          final sortedEntries = entries
                            ..sort((a, b) => b.value.compareTo(a.value));
                          final sortedEntry = sortedEntries[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1}.',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      sortedEntry.key,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      sortedEntry.value.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
