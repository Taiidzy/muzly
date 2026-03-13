import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/api_config.dart';

/// Login Screen
///
/// Provides login and registration functionality
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _serverController.text = ApiConfig.baseUrl;
  }

  @override
  void dispose() {
    _serverController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                const SizedBox(height: 48),
                Text(
                  'MUZLY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inconsolata',
                    fontSize: 32,
                    letterSpacing: 8,
                    color: AppTheme.text,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '夜の音楽',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Noto Serif JP',
                    fontSize: 14,
                    color: AppTheme.textDim,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 64),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Server URL
                      TextFormField(
                        controller: _serverController,
                        keyboardType: TextInputType.url,
                        style: const TextStyle(
                          fontFamily: 'Inconsolata',
                          fontSize: 14,
                          color: AppTheme.text,
                        ),
                        decoration: InputDecoration(
                          labelText: 'SERVER URL',
                          labelStyle: const TextStyle(
                            fontFamily: 'Inconsolata',
                            fontSize: 10,
                            color: AppTheme.textDim,
                            letterSpacing: 1,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Server URL is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Username field
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(
                          fontFamily: 'Inconsolata',
                          fontSize: 14,
                          color: AppTheme.text,
                        ),
                        decoration: InputDecoration(
                          labelText: 'USERNAME',
                          labelStyle: const TextStyle(
                            fontFamily: 'Inconsolata',
                            fontSize: 10,
                            color: AppTheme.textDim,
                            letterSpacing: 1,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontFamily: 'Inconsolata',
                          fontSize: 14,
                          color: AppTheme.text,
                        ),
                        decoration: InputDecoration(
                          labelText: 'PASSWORD',
                          labelStyle: const TextStyle(
                            fontFamily: 'Inconsolata',
                            fontSize: 10,
                            color: AppTheme.textDim,
                            letterSpacing: 1,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: AppTheme.textDim,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Submit button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surface,
                          foregroundColor: AppTheme.text,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.text,
                                  ),
                                ),
                              )
                            : Text(
                                'LOGIN',
                                style: const TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontSize: 12,
                                  letterSpacing: 3,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Error message
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    if (auth.error != null) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCF6679).withAlpha(26),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: const Color(0xFFCF6679).withAlpha(77),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          auth.error!,
                          style: const TextStyle(
                            fontFamily: 'Inconsolata',
                            fontSize: 10,
                            color: Color(0xFFCF6679),
                            letterSpacing: 1,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final serverUrl = _serverController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    auth.setServerUrl(serverUrl).then((_) {
      auth.login(email, password).then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    });
  }
}
