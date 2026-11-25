import 'package:flutter/material.dart';
import 'package:login_rive_animation/widgets/login_robot.dart';

import 'dart:async'; // 3.1 importar variable

import 'package:firebase_auth/firebase_auth.dart';

import 'package:login_rive_animation/screens/products_screen.dart';
import 'package:login_rive_animation/screens/signup_screen.dart';
import 'package:login_rive_animation/widgets/password_reset_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.auth});

  final FirebaseAuth? auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //control para mostrar y ocultar contraseña
  bool _isObscure = true;

  final _robot = LoginRobotController();

  //3.2 timer para detener el recorrido de la mirada
  Timer? _typingDebounce;

  // 2.1 Crear variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode(); // focusNode, ciclo de vida de un widget

  /// 4.1 Controllers para manipular lo que escribe el usuario
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String? loginError;
  bool isLoading = false;

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;

  Future<void> _onLogin() async {
    if (isLoading) return;
    final email = emailCtrl.text.trim();
    final password = passCtrl.text;
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _robot.reset();

    // Login only checks presence. Firebase validates the credentials.
    if (email.isEmpty || password.isEmpty) {
      setState(() => loginError = 'Completa el correo y la contraseña.');
      return;
    }
    setState(() {
      isLoading = true;
      loginError = null;
    });
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loginError = 'Credenciales inválidas';
      });
      _robot.fail();
      return;
    }
    if (!mounted) return;
    _robot.succeed();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ProductsScreen(auth: widget.auth),
      ),
    );
  }

  Future<void> _openSignUp() async {
    if (isLoading) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => SignUpScreen(auth: widget.auth)),
    );
    if (!mounted || created != true) return;
    setState(() => loginError = null);
    passCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro exitoso. Inicia sesión para continuar.'),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    if (isLoading) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          PasswordResetDialog(auth: _auth, initialEmail: emailCtrl.text.trim()),
    );
  }

  // 2.2 Crear los oyentes (listeners)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      _typingDebounce?.cancel();
      if (_emailFocus.hasFocus) {
        _robot.focusEmail();
      } else {
        _robot.clearFocus();
      }
    });
    _passwordFocus.addListener(() {
      _typingDebounce?.cancel();
      if (_passwordFocus.hasFocus) {
        _robot.focusPassword(hidden: _isObscure);
      } else {
        _robot.clearFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtiene el tamaño de la pantalla para usarlo en el diseño
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                SizedBox(
                  width: screenSize.width,
                  height: 250,
                  child: LoginRobot(controller: _robot),
                ),
                const SizedBox(height: 10), // para separar elementos
                //correo
                TextField(
                  //4.8 Vincular el controller
                  controller: emailCtrl,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  //2.3 asignar el focus al TextField
                  focusNode: _emailFocus,
                  onChanged: (value) {
                    _robot.trackEmail(value.length);
                    _typingDebounce?.cancel();
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      if (!mounted) return;
                      _robot.reset();
                    });
                  },
                  decoration: InputDecoration(
                    //4.9 mostrar el error en la UI
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      //para redondear los bordes
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),

                const SizedBox(height: 10), // para separar elementos
                // contraseña
                TextField(
                  //4.8 Vincular el controller
                  controller: passCtrl,
                  enabled: !isLoading,
                  autofillHints: const [AutofillHints.password],
                  focusNode: _passwordFocus,
                  onChanged: (_) {
                    _robot.focusPassword(hidden: _isObscure);
                  },
                  obscureText: _isObscure, // para ocultar la contraseña
                  decoration: InputDecoration(
                    //4.9 mostrar el error en la UI
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      // --- LÓGICA CORREGIDA AQUÍ ---
                      onPressed: isLoading
                          ? null
                          : () {
                              //Refrescar el ícono
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                              // Actualizar la señal visual de contraseña oculta.
                              if (_passwordFocus.hasFocus) {
                                _robot.focusPassword(hidden: _isObscure);
                              }
                            },
                      icon: Icon(
                        //if ternario
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    border: OutlineInputBorder(
                      //para redondear los bordes
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),

                const SizedBox(height: 10), // para separar elementos
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : _forgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),

                if (loginError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      loginError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                const SizedBox(height: 10), // para separar elementos
                MaterialButton(
                  minWidth: screenSize.width,
                  height: 50,
                  color: const Color.fromARGB(255, 255, 139, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  onPressed: isLoading ? null : _onLogin,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: isLoading ? null : _openSignUp,
                        child: Text(
                          "Sign up",
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 139, 45),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    _robot.dispose();
    super.dispose();
  }
}
