import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../core/theme/app_colors.dart';
import '../widgets/user_profile_header.dart';

class RegistroActaScreen extends StatefulWidget {
  const RegistroActaScreen({super.key, this.actaToEdit});

  final Map<String, dynamic>? actaToEdit;

  @override
  State<RegistroActaScreen> createState() => _RegistroActaScreenState();
}

class _RegistroActaScreenState extends State<RegistroActaScreen> {
  String _nombre = '';
  String _dni = '';
  String _rol = 'personero';

  final _formKey = GlobalKey<FormState>();
  final _numeroActaController = TextEditingController();
  String? _lugarSeleccionado;

  final List<TextEditingController> _votosControllers = [];
  final _nulosController = TextEditingController();
  final _blancosController = TextEditingController();
  final _noVotantesController = TextEditingController();

  final List<Map<String, String>> _candidatos = [
    {
      'nombre': 'Marcos Enrique Ramos Bancayan',
      'partido': 'Alianza para el Progreso',
    },
    {
      'nombre': 'Juan Manuel Chamaya Silva',
      'partido': 'Partido Político Perú Primero',
    },
    {
      'nombre': 'Manuel Orlando Cruz Correa',
      'partido': 'Partido Democrático Somos Perú',
    },
    {'nombre': 'Victor Raul Hidalgo Lopez', 'partido': 'Podemos Perú'},
    {
      'nombre': 'Rafael Grisolle Alvarez Calderon',
      'partido': 'Movimiento Independiente Fuerza Regional',
    },
  ];

  final List<String> _lugares = [
    'Micaela Bastidas',
    'Tupac Amaru',
    'Alberto Pallete',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNombre();
    for (int i = 0; i < 5; i++) {
      _votosControllers.add(TextEditingController());
    }
    _preloadActa();
  }

  void _preloadActa() {
    final acta = widget.actaToEdit;
    if (acta == null) return;

    _numeroActaController.text = acta['numeroActa']?.toString() ?? '';
    _lugarSeleccionado = acta['lugar']?.toString();
    final items = (acta['items'] as List? ?? []).whereType<Map>().toList();
    final votos = acta['votos'] is Map
        ? Map<String, dynamic>.from(acta['votos'] as Map)
        : <String, dynamic>{};
    final candidatos = votos['candidatos'] is Map
        ? Map<String, dynamic>.from(votos['candidatos'] as Map)
        : <String, dynamic>{};

    for (var index = 0; index < _candidatos.length; index++) {
      final nombre = _candidatos[index]['nombre']!;
      final item = items.firstWhere(
        (item) => item['nombre']?.toString() == nombre,
        orElse: () => <String, dynamic>{},
      );
      _votosControllers[index].text = _aEntero(
        item['votos'] ?? candidatos[nombre],
      ).toString();
    }

    _nulosController.text = _conteoExistente(
      acta,
      items,
      votos,
      'nulos',
    ).toString();
    _blancosController.text = _conteoExistente(
      acta,
      items,
      votos,
      'blancos',
    ).toString();
    _noVotantesController.text = _conteoExistente(
      acta,
      items,
      votos,
      'noVotantes',
    ).toString();
  }

  int _conteoExistente(
    Map<String, dynamic> acta,
    List<Map> items,
    Map<String, dynamic> votos,
    String tipo,
  ) {
    final item = items.firstWhere(
      (item) => item['tipo']?.toString() == tipo,
      orElse: () => <String, dynamic>{},
    );
    return _aEntero(item['votos'] ?? votos[tipo] ?? acta[tipo]);
  }

  int _aEntero(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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

  @override
  void dispose() {
    _numeroActaController.dispose();
    _nulosController.dispose();
    _blancosController.dispose();
    _noVotantesController.dispose();
    for (var controller in _votosControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _guardarActa() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final candidatos = <String, int>{};
    for (int i = 0; i < 5; i++) {
      final votos = int.tryParse(_votosControllers[i].text) ?? 0;
      candidatos[_candidatos[i]['nombre']!] = votos;
    }

    final nulos = int.tryParse(_nulosController.text) ?? 0;
    final blancos = int.tryParse(_blancosController.text) ?? 0;
    final noVotantes = int.tryParse(_noVotantesController.text) ?? 0;
    final actaId = widget.actaToEdit?['id']?.toString();

    try {
      if (widget.actaToEdit != null) {
        if (actaId == null || actaId.isEmpty) {
          throw Exception('No se encontró el identificador del acta.');
        }
        await StorageService().updateActa(
          actaId: actaId,
          lugar: _lugarSeleccionado ?? '',
          candidatos: candidatos,
          nulos: nulos,
          blancos: blancos,
          noVotantes: noVotantes,
          dniUsuario: _dni,
        );
      } else {
        await StorageService().saveActa(
          numeroActa: _numeroActaController.text.trim(),
          lugar: _lugarSeleccionado ?? '',
          candidatos: candidatos,
          nulos: nulos,
          blancos: blancos,
          noVotantes: noVotantes,
          dniUsuario: _dni,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.actaToEdit == null
                  ? 'Acta guardada exitosamente'
                  : 'Acta actualizada exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, widget.actaToEdit != null);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        String errorMessage = 'Error al guardar acta';
        if (e.toString().contains('409')) {
          errorMessage = 'Ya existe un acta con este número';
        } else if (e.toString().contains('403')) {
          errorMessage =
              'Solo puedes registrar una acta. Contacta a un administrador.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildCandidateInput(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: TextFormField(
              controller: _votosControllers[index],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Votos',
                border: OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Req';
                final votos = int.tryParse(value);
                if (votos == null || votos < 0) return 'Inválido';
                return null;
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _candidatos[index]['nombre']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _candidatos[index]['partido']!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountInput(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Req';
        final count = int.tryParse(value);
        if (count == null || count < 0) return 'Inválido';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lugaresDisponibles = [..._lugares];
    if (_lugarSeleccionado != null &&
        !lugaresDisponibles.contains(_lugarSeleccionado)) {
      lugaresDisponibles.add(_lugarSeleccionado!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.actaToEdit == null
              ? 'Registrar conteo de Acta'
              : 'Editar Acta',
        ),
      ),
      body: Column(
        children: [
          UserProfileHeader(nombre: _nombre, dni: _dni, rol: _rol),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _numeroActaController,
                                  readOnly: widget.actaToEdit != null,
                                  decoration: const InputDecoration(
                                    labelText: 'Número de Acta',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.description),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese el número de acta';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: _lugarSeleccionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Local de Votación',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.location_on),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: lugaresDisponibles.map((String lugar) {
                                    return DropdownMenuItem<String>(
                                      value: lugar,
                                      child: Text(lugar),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _lugarSeleccionado = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Por favor seleccione el local de votación';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Conteo de Votos por Candidato',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columns = constraints.maxWidth >= 760
                                        ? 2
                                        : 1;
                                    final itemWidth = columns == 2
                                        ? (constraints.maxWidth - 16) / 2
                                        : constraints.maxWidth;
                                    return Wrap(
                                      spacing: 16,
                                      runSpacing: 12,
                                      children: List.generate(
                                        5,
                                        (index) => SizedBox(
                                          width: itemWidth,
                                          child: _buildCandidateInput(index),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Votos Nulos, en Blanco y No Votantes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 900
                                ? 3
                                : constraints.maxWidth >= 560
                                ? 2
                                : 1;
                            final fieldWidth =
                                (constraints.maxWidth - (columns - 1) * 16) /
                                columns;
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                SizedBox(
                                  width: fieldWidth,
                                  child: _buildCountInput(
                                    _nulosController,
                                    'Votos Nulos',
                                  ),
                                ),
                                SizedBox(
                                  width: fieldWidth,
                                  child: _buildCountInput(
                                    _blancosController,
                                    'Votos en Blanco',
                                  ),
                                ),
                                SizedBox(
                                  width: fieldWidth,
                                  child: _buildCountInput(
                                    _noVotantesController,
                                    'No Votantes',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _guardarActa,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    widget.actaToEdit == null
                                        ? 'Guardar Acta'
                                        : 'Actualizar Acta',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
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
