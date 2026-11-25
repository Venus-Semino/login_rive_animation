import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/api_service.dart';
import '../models/videogame.dart';
import 'login_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, this.auth, this.apiService});

  final FirebaseAuth? auth;
  final ApiService? apiService;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ApiService _api;
  late Future<List<Videogame>> productosFuture;
  bool _closingSession = false;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService(auth: widget.auth);
    productosFuture = _api.obtenerProductos();
  }

  void recargarProductos() {
    setState(() {
      productosFuture = _api.obtenerProductos();
    });
  }

  Future<void> cerrarSesion() async {
    if (_closingSession) return;
    setState(() => _closingSession = true);
    try {
      await (widget.auth ?? FirebaseAuth.instance).signOut();
    } catch (_) {
      if (!mounted) return;
      setState(() => _closingSession = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar sesión. Intenta nuevamente.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(auth: widget.auth)),
      (_) => false,
    );
  }

  @override
  void dispose() {
    if (widget.apiService == null) _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: const Color.fromARGB(255, 255, 139, 45),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: recargarProductos,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _closingSession ? null : cerrarSesion,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<Videogame>>(
        future: productosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudieron cargar los productos.\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: recargarProductos,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final productos = snapshot.data ?? [];

          if (productos.isEmpty) {
            return const Center(child: Text('No hay productos disponibles'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              final nombre = producto.title;
              final precio = producto.price.toStringAsFixed(2);
              final stock = producto.stock?.toString() ?? 'No informado';
              final categoria = producto.category?.trim();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(nombre),
                  subtitle: Text(
                    'Existencias: $stock\nCategoría: ${categoria == null || categoria.isEmpty ? 'No informada' : categoria}',
                  ),
                  trailing: Text('\$$precio'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
