class Videogame {
  const Videogame({
    required this.gameId,
    required this.title,
    required this.price,
    this.consoleId,
    this.stock,
    this.category,
  });

  final int gameId;
  final String title;
  final num price;
  final int? consoleId;
  final int? stock;
  final String? category;

  factory Videogame.fromJson(Map<String, dynamic> json) {
    final id = json['gameId'];
    final title = json['title'];
    final price = json['price'];
    final consoleId = json['consoleId'];
    final stock = json['stock'];
    final category = json['category'];
    if (id is! int ||
        title is! String ||
        title.trim().isEmpty ||
        price is! num ||
        !price.isFinite ||
        (consoleId != null && consoleId is! int) ||
        (stock != null && stock is! int) ||
        (category != null && category is! String)) {
      throw const FormatException('Contrato de videojuego inválido.');
    }
    return Videogame(
      gameId: id,
      title: title,
      price: price,
      consoleId: consoleId as int?,
      stock: stock as int?,
      category: category as String?,
    );
  }
}
