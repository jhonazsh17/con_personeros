import 'package:flutter/material.dart';
import 'registro_acta_screen.dart';
import '../services/storage_service.dart';
import '../widgets/user_profile_header.dart';

class ListaActasScreen extends StatefulWidget {
  const ListaActasScreen({super.key});

  @override
  State<ListaActasScreen> createState() => _ListaActasScreenState();
}

class _ListaActasScreenState extends State<ListaActasScreen> {
  static const Color primaryLight = Color(0xFF2A835F);
  static const Color accent = Color(0xFF8BBB92);
  static const List<String> _ordenCandidatos = [
    'Marcos Enrique Ramos Bancayan',
    'Juan Manuel Chamaya Silva',
    'Manuel Orlando Cruz Correa',
    'Victor Raul Hidalgo Lopez',
    'Rafael Grisolle Alvarez Calderon',
  ];

  String _nombre = '';
  String _dni = '';
  String _rol = 'personero';
  List<Map<String, dynamic>> _actas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNombre();
    _loadActas();
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

  Future<void> _loadActas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final actas = await StorageService().getActas();

      if (mounted) {
        setState(() {
          _actas = actas;
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
            content: Text('Error al cargar actas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDetalleActa(Map<String, dynamic> acta) {
    final items = List<Map<String, dynamic>>.from(
      acta['items'] as List? ?? const [],
    );
    final totalVotos = _totalVotosEmitidos(items);
    final nombreRegistrador = acta['nombreUsuario']?.toString().trim();
    final votos = acta['votos'] is Map
        ? Map<String, dynamic>.from(acta['votos'] as Map)
        : <String, dynamic>{};
    final candidatos = votos['candidatos'] is Map
        ? Map<String, dynamic>.from(votos['candidatos'] as Map)
        : <String, dynamic>{};

    int obtenerConteo(String tipo, String clave) {
      for (final item in items) {
        if (item['tipo'] == tipo) return _entero(item['votos']);
      }
      return _entero(votos[clave] ?? acta[clave]);
    }

    final filasVotos = [
      ..._ordenCandidatos.map((nombre) {
        final item = items.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['nombre']?.toString() == nombre,
          orElse: () => null,
        );
        return {
          'nombre': nombre,
          'votos': _entero(item?['votos'] ?? candidatos[nombre]),
        };
      }),
      {
        'nombre': 'Votos Nulos',
        'votos': obtenerConteo('nulos', 'nulos'),
        'mostrarUnidad': false,
      },
      {
        'nombre': 'Votos en Blanco',
        'votos': obtenerConteo('blancos', 'blancos'),
        'mostrarUnidad': false,
      },
      {
        'nombre': 'No Votantes',
        'votos': obtenerConteo('noVotantes', 'noVotantes'),
        'mostrarUnidad': false,
      },
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Detalle del Acta',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetalleRow(
                  'Número de Acta:',
                  acta['numeroActa']?.toString() ?? '',
                ),
                const SizedBox(height: 8),
                _buildDetalleRow(
                  'Local de Votación:',
                  acta['lugar']?.toString() ?? '',
                ),
                const SizedBox(height: 8),
                _buildDetalleRow(
                  'Fecha:',
                  acta['fecha']?.toString().split('.')[0] ?? '',
                ),
                const SizedBox(height: 8),
                _buildDetalleRow(
                  'Registrado por:',
                  nombreRegistrador == null || nombreRegistrador.isEmpty
                      ? 'No disponible'
                      : nombreRegistrador,
                ),
                const SizedBox(height: 8),
                _buildDetalleRow(
                  'Total de Votos Válidos:',
                  totalVotos.toString(),
                ),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Detalle de Votos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...filasVotos.map(_buildConteoRow),
                if (_rol == 'admin') ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RegistroActaScreen(actaToEdit: acta),
                        ),
                      );
                      if (updated == true && mounted) await _loadActas();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar acta'),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _entero(dynamic valor) {
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  int _totalVotosEmitidos(Iterable<dynamic> items) {
    return items.fold(0, (total, item) {
      if (item is! Map) return total;
      final tipo = item['tipo']?.toString().toLowerCase();
      final nombre = item['nombre']?.toString().toLowerCase();
      if (tipo == 'nulos' ||
          tipo == 'blancos' ||
          tipo == 'no votantes' ||
          tipo == 'novotantes' ||
          nombre == 'votos nulos' ||
          nombre == 'votos en blanco' ||
          nombre == 'no votantes') {
        return total;
      }
      final votos = item['votos'];
      return total + (votos is num ? votos.toInt() : 0);
    });
  }

  Widget _buildConteoRow(Map<String, dynamic> item) {
    final votos = item['votos'];
    final textoVotos = item['mostrarUnidad'] == false
        ? votos.toString()
        : '$votos votos';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item['nombre']?.toString() ?? '',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                textoVotos,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Actas')),
      body: Column(
        children: [
          UserProfileHeader(nombre: _nombre, dni: _dni, rol: _rol),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _actas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay actas registradas',
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
                        itemCount: _actas.length,
                        itemBuilder: (context, index) {
                          final acta = _actas[index];
                          final items = acta['items'] as List? ?? [];
                          final totalVotos = _totalVotosEmitidos(items);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryLight,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                'Acta #${acta['numeroActa']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Local de Votación: ${acta['lugar']}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$totalVotos votos válidos',
                                    style: const TextStyle(
                                      color: primaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showDetalleActa(acta),
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
