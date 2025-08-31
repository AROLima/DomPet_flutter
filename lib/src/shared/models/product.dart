// Implementações manuais para evitar dependência de arquivos gerados do Freezed.

import 'package:flutter/foundation.dart';

class Produto {
  const Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.estoque,
    required this.ativo,
    this.categoria,
    this.imagemUrl,
    this.descricaoCurta,
  });

  final int id;
  final String nome;
  final double preco;
  final int estoque;
  final bool ativo;
  final String? categoria;
  final String? imagemUrl;
  final String? descricaoCurta;

  factory Produto.fromJson(Map<String, dynamic> json) {
    String? img = json['imagemUrl'] as String?;
    if (img != null) {
      try {
        final u = Uri.parse(img);
        if ((u.host == 'localhost' || u.host == '127.0.0.1') && !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android) {
          img = u.replace(host: '10.0.2.2').toString();
        }
      } catch (_) {}
    }
    return Produto(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      preco: (json['preco'] as num).toDouble(),
      estoque: (json['estoque'] as num).toInt(),
      ativo: json['ativo'] as bool,
      categoria: json['categoria'] as String?,
      imagemUrl: img,
      descricaoCurta: json['descricaoCurta'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'preco': preco,
        'estoque': estoque,
        'ativo': ativo,
        if (categoria != null) 'categoria': categoria,
        if (imagemUrl != null) 'imagemUrl': imagemUrl,
        if (descricaoCurta != null) 'descricaoCurta': descricaoCurta,
      };
}

class ProdutoDetalhe {
  const ProdutoDetalhe({
    required this.id,
    required this.nome,
    required this.preco,
    required this.estoque,
    required this.ativo,
  this.categoria,
    this.imagemUrl,
    this.descricao,
  this.sku,
  });

  final int id;
  final String nome;
  final double preco;
  final int estoque;
  final bool ativo;
  final String? categoria;
  final String? imagemUrl;
  final String? descricao;
  final String? sku;

  factory ProdutoDetalhe.fromJson(Map<String, dynamic> json) {
    String? img = json['imagemUrl'] as String?;
    if (img != null) {
      try {
        final u = Uri.parse(img);
        if ((u.host == 'localhost' || u.host == '127.0.0.1') && !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android) {
          img = u.replace(host: '10.0.2.2').toString();
        }
      } catch (_) {}
    }
    return ProdutoDetalhe(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      preco: (json['preco'] as num).toDouble(),
      estoque: (json['estoque'] as num).toInt(),
      ativo: json['ativo'] as bool,
      categoria: json['categoria'] as String?,
      imagemUrl: img,
  descricao: json['descricao'] as String?,
  sku: json['sku'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'preco': preco,
        'estoque': estoque,
        'ativo': ativo,
        if (categoria != null) 'categoria': categoria,
        if (imagemUrl != null) 'imagemUrl': imagemUrl,
        if (descricao != null) 'descricao': descricao,
    if (sku != null) 'sku': sku,
      };
}

class ProdutoSugestao {
  const ProdutoSugestao({
    required this.id,
    required this.nome,
  });

  final int id;
  final String nome;

  factory ProdutoSugestao.fromJson(Map<String, dynamic> json) => ProdutoSugestao(
        id: (json['id'] as num).toInt(),
        nome: json['nome'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
      };
}
