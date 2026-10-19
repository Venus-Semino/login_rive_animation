import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const new({super.key});

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
  SMINumber? _numLook; // para controlar el estado de la animación

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
                    stateMachines: ['Login Machine'],
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
                  SizedBox(height: 10), // para separar elementos
                  //correo
                  TextField(
                    //1.5 vincular al campo de texto
                    onChanged:(value){
                      if (_isHandsUp != null){
                        //no tapes los ojos al ver el email
                        _isHandsUp!.change(false);
                      }
                      // si isChecking es null
                      if (_isChecking == null) return;
                      //activa el modo chismoso
                      _isChecking!.change(true);
                    },
                    decoration: InputDecoration(
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
                    //1.5 vincular al campo de texto
                    onChanged:(value){
                      if (_isChecking != null){
                        //no tapes los ojos al ver el email
                        _isChecking!.change(false);
                      }
                      // si isChecking es null
                      if (_isHandsUp == null) return;
                      //activa el modo chismoso
                      _isHandsUp!.change(true);
                    },
                    obscureText: _isObscure, // para ocultar la contraseña
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: (){
                          //Refrescar el ícono
                          setState(() {
                            _isObscure = !_isObscure;
                          });
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
              ],
            ),
          )
        ,),
      )
    );
  }
}