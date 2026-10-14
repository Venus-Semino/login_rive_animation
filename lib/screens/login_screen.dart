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
  @override
  Widget build(BuildContext context) {
    // Obtiene el tamaño de la pantalla para usarlo en el diseño
   final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea (
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              SizedBox(
                width: screenSize.width,
                height: 250,
                child: RiveAnimation.asset('assets/login-bear-animation.riv')
                ),
                SizedBox(height: 10), // para separar elementos
                //correo
                TextField(
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
      ,)
    );
  }
}