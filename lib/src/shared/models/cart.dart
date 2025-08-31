// Implementação manual para evitar arquivos gerados do Freezed.

class ItemCarrinho {
  const ItemCarrinho({
    required this.itemId,
    required this.produtoId,
    required this.nome,
    required this.precoUnitario,
    required this.quantidade,
    required this.subtotal,
  });

  final int itemId; // no remoto; local pode usar hash negativo
  final int produtoId;
  final String nome;
  final double precoUnitario;
  final int quantidade;
  final double subtotal;

  ItemCarrinho copyWith({
    int? itemId,
    int? produtoId,
    String? nome,
    double? precoUnitario,
    int? quantidade,
    double? subtotal,
  }) =>
      ItemCarrinho(
        itemId: itemId ?? this.itemId,
        produtoId: produtoId ?? this.produtoId,
        nome: nome ?? this.nome,
        precoUnitario: precoUnitario ?? this.precoUnitario,
        quantidade: quantidade ?? this.quantidade,
        subtotal: subtotal ?? this.subtotal,
      );

  factory ItemCarrinho.fromJson(Map<String, dynamic> json) => ItemCarrinho(
        itemId: (json['itemId'] as num).toInt(),
        produtoId: (json['produtoId'] as num).toInt(),
        nome: json['nome'] as String,
        precoUnitario: ((json['precoUnitario'] ?? json['preco']) as num).toDouble(),
        quantidade: (json['quantidade'] as num).toInt(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'produtoId': produtoId,
        'nome': nome,
        'precoUnitario': precoUnitario,
        'quantidade': quantidade,
        'subtotal': subtotal,
      };
}

class Carrinho {
  const Carrinho({
    required this.itens,
    required this.total,
  });

  final List<ItemCarrinho> itens;
  final double total;

  factory Carrinho.fromJson(Map<String, dynamic> json) => Carrinho(
        itens: (json['itens'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(ItemCarrinho.fromJson)
                .toList() ??
            const [],
        total: (json['total'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'itens': itens.map((e) => e.toJson()).toList(),
        'total': total,
      };
}
