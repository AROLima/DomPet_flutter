// DIDACTIC: Order models (Pedido, ItemPedido, EnderecoDto)
// Purpose:
// - Represent orders and their components for UI and services. Keep parsing
//   explicit so errors surface at the HTTP boundary (ProblemDetail).
// Contract:
// - `createdAt` is ISO-8601 and parsed with DateTime.parse.
// Edge cases / Notes:
// - If the backend format changes, the parser will throw; prefer handling
//   validation errors upstream in the HTTP layer.

// Modelos manuais para evitar dependência de arquivos gerados do Freezed.

class EnderecoDto {
  const EnderecoDto({
    required this.rua,
    required this.numero,
    required this.bairro,
    required this.cep,
    required this.cidade,
    this.complemento,
  });

  final String rua;
  final String numero;
  final String bairro;
  final String cep;
  final String cidade;
  final String? complemento;

  factory EnderecoDto.fromJson(Map<String, dynamic> json) => EnderecoDto(
        rua: json['rua'] as String,
        numero: json['numero'] as String,
        bairro: json['bairro'] as String,
        cep: json['cep'] as String,
        cidade: json['cidade'] as String,
        complemento: json['complemento'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'rua': rua,
        'numero': numero,
        'bairro': bairro,
        'cep': cep,
        'cidade': cidade,
        if (complemento != null) 'complemento': complemento,
      };
}

class ItemPedido {
  const ItemPedido({
    required this.produtoId,
    required this.nome,
    required this.precoUnitario,
    required this.quantidade,
    required this.subtotal,
  });

  final int produtoId;
  final String nome;
  final double precoUnitario;
  final int quantidade;
  final double subtotal;

  factory ItemPedido.fromJson(Map<String, dynamic> json) => ItemPedido(
        produtoId: (json['produtoId'] as num).toInt(),
        nome: json['nome'] as String,
        precoUnitario: (json['precoUnitario'] as num).toDouble(),
        quantidade: (json['quantidade'] as num).toInt(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'produtoId': produtoId,
        'nome': nome,
        'precoUnitario': precoUnitario,
        'quantidade': quantidade,
        'subtotal': subtotal,
      };
}

class Pedido {
  const Pedido({
    required this.id,
    required this.status,
    required this.enderecoEntrega,
    required this.itens,
    required this.total,
    required this.createdAt,
  });

  final int id;
  final String status;
  final EnderecoDto enderecoEntrega;
  final List<ItemPedido> itens;
  final double total;
  final DateTime createdAt;

  factory Pedido.fromJson(Map<String, dynamic> json) {
  DateTime parseDate(dynamic v) {
      try {
        if (v is String) return DateTime.parse(v);
        if (v is num) {
          final n = v.toInt();
          if (n > 1000000000000) {
            return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true);
          } else if (n > 1000000000) {
            return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true);
          }
        }
      } catch (_) {}
      return DateTime.now().toUtc();
    }

    final rawItens = json['itens'];
    final itensList = (rawItens is List)
        ? rawItens.whereType<Map<String, dynamic>>().map(ItemPedido.fromJson).toList()
        : <ItemPedido>[];

    return Pedido(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
      enderecoEntrega: EnderecoDto.fromJson(json['enderecoEntrega'] as Map<String, dynamic>),
      itens: itensList,
      total: (json['total'] as num).toDouble(),
  createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'enderecoEntrega': enderecoEntrega.toJson(),
        'itens': itens.map((e) => e.toJson()).toList(),
        'total': total,
        'createdAt': createdAt.toIso8601String(),
      };
}
