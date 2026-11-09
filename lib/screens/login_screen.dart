import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'dart:async'; // 3.1 importar variable 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); 

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //control para mostrar y ocultar contraseña
  bool _isObscure = true;

  // 1.1 MÁQUINA ESTADOS / cerebro de la animación
  StateMachineController? _controller; // nullsafety, sirve par evitar que el programma falle (?)
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
  void _onLogin(){
    //recortar espacios en blanco accidentales
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    // Recalicular erorores
    final emailTypedError = isValidEmail(email) ? null : 'Email inválido';
    final passTypedError = isValidPassword(pass) ? null : 'Contraseña inválida';

    //4.5 Para mostrar el cambio
    setState(() {
      emailError = emailTypedError;
      passError = passTypedError;
    });

    //4.6 Cerrar el teclado y oso neutro
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    //4.7 Activar triggers
    if (emailTypedError == null && passTypedError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }

  }

  // 2.2 Crear los oyentes (listeners)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener((){
      if (_emailFocus.hasFocus){
        _isHandsUp?.change(false);
        _isChecking?.change(true); // Activar modo chismoso al tocar
        //3.3 mirada neutral
        _numLook?.value = 50.0;
      } else {
        _isChecking?.change(false); // Desactivar si pierde el foco
      }
    });

    _passwordFocus.addListener((){
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
        child: SafeArea (
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
                    onInit: (artboard){
                      _controller = StateMachineController.fromArtboard(
                        artboard, 
                        'Login Machine'
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
                    onChanged:(value){
                      _isHandsUp?.change(false);
                      _isChecking?.change(true); //activa el modo chismoso

                      //3.4 Implementar recorrido de mirada
                      // ajuste de mi límite de 0 a 100
                      //80 medida de calibración
                      final look = (value.length / 80.0 * 100.0).clamp(
                        0.0, 
                        100.0
                      );
                      _numLook?.value = look;

                      // 3.5 Debounce: si vuelve a teclear, reinicia el contador
                      _typingDebounce?.cancel();
                      //crear nuevo timer 
                      _typingDebounce = Timer(const Duration(seconds: 3),(){
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
                    )
                  ),
        
                  const SizedBox(height: 10), // para separar elementos
        
                  // contraseña
                  TextField(
                    //4.8 Vincular el controller
                    controller: passCtrl,
                    focusNode: _passwordFocus,
                    onChanged:(value){
                      _isChecking?.change(false);
                      _isHandsUp?.change(_isObscure); // Se tapa los ojos si está oculto
                    },
                    obscureText: _isObscure, // para ocultar la contraseña
                    decoration: InputDecoration(
                      //4.9 mostrar el error en la UI
                      errorText: passError,
                      hintText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        // --- LÓGICA CORREGIDA AQUÍ ---
                        onPressed: (){
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
                          _isObscure ? Icons.visibility : Icons.visibility_off
                        )
                        ),
                      border: OutlineInputBorder(
                        //para redondear los bordes
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    )
                  ),

                  const SizedBox(height: 10), // para separar elementos
                  SizedBox(
                    width: screenSize.width,
                    child: const Text(
                      "Forgot password?",
                      textAlign: TextAlign.right,
                      style: TextStyle(decoration: TextDecoration.underline)
                      ),
                 ),

                 const SizedBox(height: 10), // para separar elementos
                 MaterialButton(
                  minWidth: screenSize.width,
                  height: 50,
                  color: const Color.fromARGB(255, 255, 139, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)
                  ),
                  onPressed: _onLogin,
                  child: Text(
                  "Login",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
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
                      TextButton(onPressed: (){}, child: Text("Register",
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 139, 45),
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline
                      ),
                  ),
                ),
                    ],
                  )
                )
              ],
            ),
          )
        ,),
      )
    );
  }

  @override
  void dispose() {
    // 2.4 liberar memoria/recurso en los focusNode
    _emailFocus.dispose();
    _passwordFocus.dispose();
    //3.5 liberar timer 
    _typingDebounce?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}