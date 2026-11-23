import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<dynamic>> productosFuture;

  @override
  void initState() {
    super.initState();
    productosFuture = ApiService.obtenerProductos();
  }

  void recargarProductos() {
    setState(() {
      productosFuture = ApiService.obtenerProductos();
    });
  }

  Future<void> cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pop();
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
            onPressed: cerrarSesion,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
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
              final producto = productos[index] as Map<String, dynamic>;

              final nombre = producto['name']?.toString() ?? 'Sin nombre';
              final precio = producto['price']?.toString() ?? '0';
              final stock = producto['stock']?.toString() ?? '0';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(nombre),
                  subtitle: Text('Existencias: $stock'),
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
