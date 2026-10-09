import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Set<String> _rolesPermitidos = {
    'personero',
    'coordinador',
    'admin',
  };

  final _dniController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final usuario = await ApiService.login(dni: _dniController.text.trim());
      final nombre = usuario['nombre'] as String;
      final rol = (usuario['rol'] as String).trim().toLowerCase();
      final dni = usuario['dni'] as String;

      if (!_rolesPermitidos.contains(rol)) {
        throw Exception('El usuario tiene un rol no permitido.');
      }

      final storage = StorageService();
      await storage.saveDni(dni);
      await storage.saveNombre(nombre);
      await storage.saveRol(rol);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.how_to_vote,
                            size: 80,
                            color: AppColors.primaryLight,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Con Personeros',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 48),
                          TextFormField(
                            controller: _dniController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'DNI',
                              hintText: 'Ingrese su número de DNI',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su DNI';
                              }
                              if (value.trim().length < 8) {
                                return 'El DNI debe tener al menos 8 dígitos';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryLight,
                                foregroundColor: Colors.white,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Ingresar',
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
          ),
        ),
      ),
    );
  }
}
