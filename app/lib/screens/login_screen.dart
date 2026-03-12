import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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
                      if (!_isLogin) ...[
                        // Name field (registration only)
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontFamily: 'Inconsolata',
                            fontSize: 14,
                            color: AppTheme.text,
                          ),
                          decoration: InputDecoration(
                            labelText: 'NAME',
                            labelStyle: const TextStyle(
                              fontFamily: 'Inconsolata',
                              fontSize: 10,
                              color: AppTheme.textDim,
                              letterSpacing: 1,
                            ),
                          ),
                          validator: (value) {
                            if (!_isLogin && (value == null || value.isEmpty)) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontFamily: 'Inconsolata',
                          fontSize: 14,
                          color: AppTheme.text,
                        ),
                        decoration: InputDecoration(
                          labelText: 'EMAIL',
                          labelStyle: const TextStyle(
                            fontFamily: 'Inconsolata',
                            fontSize: 10,
                            color: AppTheme.textDim,
                            letterSpacing: 1,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
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
                          if (!_isLogin && value.length < 6) {
                            return 'Password must be at least 6 characters';
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
                                _isLogin ? 'LOGIN' : 'REGISTER',
                                style: const TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontSize: 12,
                                  letterSpacing: 3,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // Toggle login/register
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? "Don't have an account? Register"
                              : 'Already have an account? Login',
                          style: const TextStyle(
                            fontFamily: 'Inconsolata',
                            fontSize: 10,
                            color: AppTheme.textDim,
                            letterSpacing: 1,
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
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLogin) {
      auth.login(email, password).then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
      final name = _nameController.text.trim();
      auth.register(name, email, password).then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }
}
