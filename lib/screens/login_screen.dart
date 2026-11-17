import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'dart:async'; // 3.1 importar variable

import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //control para mostrar y ocultar contraseña
  bool _isObscure = true;

  // 1.1 MÁQUINA ESTADOS / cerebro de la animación
  StateMachineController?
  _controller; // nullsafety, sirve par evitar que el programma falle (?)
  //StateMachineInput
  SMIBool? _isChecking; // para controlar el estado de la animación
  SMIBool? _isHandsUp; // para controlar el estado de la animación
  SMITrigger? _trigSuccess; // para controlar el estado de la animación
  SMITrigger? _trigFail; // para controlar el estado de la animación
  SMINumber? _numLook; // para controlar el estado de la

  //3.2 timer para detener el recorrido de la mirada
  Timer? _typingDebounce;

  // 2.1 Crear variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode(); // focusNode, ciclo de vida de un widget

  /// 4.1 Controllers para manipular lo que escribe el usuario
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  //4.2 Errores para mostrar en la UI
  String? emailError;
  String? passError;
  //para que se conecte
  String? loginError;
  bool isLoading = false;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  //4.4 Acción del botón

  Future<void> _onLogin() async {
    if (isLoading) return;

    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    // Validar el formato con Regex.
    final emailTypedError = isValidEmail(email) ? null : 'Email inválido';

    final passTypedError = isValidPassword(pass) ? null : 'Contraseña inválida';

    setState(() {
      emailError = emailTypedError;
      passError = passTypedError;
      loginError = null;
    });

    // Cerrar teclado y regresar el osito a estado neutro.
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // Si el formato es incorrecto, no consultar Firebase.
    if (emailTypedError != null || passTypedError != null) {
      _trigFail?.fire();
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Comprobar las credenciales reales en Firebase.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (!mounted) return;

      // Firebase confirmó que las credenciales son correctas.
      _trigSuccess?.fire();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inicio de sesión exitoso')));

      // Después conectaremos aquí la pantalla de productos.
    } on FirebaseAuthException {
      if (!mounted) return;

      setState(() {
        loginError = 'Correo o contraseña incorrectos';
      });

      _trigFail?.fire();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loginError = 'No se pudo iniciar sesión. Intenta de nuevo.';
      });

      _trigFail?.fire();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 2.2 Crear los oyentes (listeners)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        _isHandsUp?.change(false);
        _isChecking?.change(true); // Activar modo chismoso al tocar
        //3.3 mirada neutral
        _numLook?.value = 50.0;
      } else {
        _isChecking?.change(false); // Desactivar si pierde el foco
      }
    });

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus) {
        _isChecking?.change(false);
        //Manos arriba SOLO si la contraseña está oculta
        _isHandsUp?.change(_isObscure);
      } else {
        _isHandsUp?.change(false); // Bajar manos al perder el foco
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
                  child: RiveAnimation.asset(
                    'assets/login-bear-animation.riv',
                    stateMachines: const ['Login Machine'],
                    // 1.2 vincular la animacion
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );
                      //1.3 verificar que inicio bien
                      if (_controller == null) return;
                      // agregar el controlador al escenario
                      artboard.addController(_controller!);
                      // 1.4 vincular las variables
                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),
                const SizedBox(height: 10), // para separar elementos
                //correo
                TextField(
                  //4.8 Vincular el controller
                  controller: emailCtrl,
                  //2.3 asignar el focus al TextField
                  focusNode: _emailFocus,
                  onChanged: (value) {
                    _isHandsUp?.change(false);
                    _isChecking?.change(true); //activa el modo chismoso

                    //3.4 Implementar recorrido de mirada
                    // ajuste de mi límite de 0 a 100
                    //80 medida de calibración
                    final look = (value.length / 80.0 * 100.0).clamp(
                      0.0,
                      100.0,
                    );
                    _numLook?.value = look;

                    // 3.5 Debounce: si vuelve a teclear, reinicia el contador
                    _typingDebounce?.cancel();
                    //crear nuevo timer
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      //si secierra la pantalla, termina la ejecución
                      if (!mounted) return;
                      //mirada neutra
                      _isChecking?.change(false);
                    });
                  },
                  decoration: InputDecoration(
                    //4.9 mostrar el error en la UI
                    errorText: emailError,
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
                  focusNode: _passwordFocus,
                  onChanged: (value) {
                    _isChecking?.change(false);
                    _isHandsUp?.change(
                      _isObscure,
                    ); // Se tapa los ojos si está oculto
                  },
                  obscureText: _isObscure, // para ocultar la contraseña
                  decoration: InputDecoration(
                    //4.9 mostrar el error en la UI
                    errorText: passError,
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      // --- LÓGICA CORREGIDA AQUÍ ---
                      onPressed: () {
                        //Refrescar el ícono
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                        // Si estás enfocado en la contraseña, actualiza las manos
                        if (_passwordFocus.hasFocus) {
                          _isHandsUp?.change(_isObscure);
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
                SizedBox(
                  width: screenSize.width,
                  child: const Text(
                    "Forgot password?",
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
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
                        onPressed: () {},
                        child: Text(
                          "Register",
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
  @override
  void dispose() {
    _typingDebounce?.cancel();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    _controller?.dispose();
    super.dispose();
  }
}
