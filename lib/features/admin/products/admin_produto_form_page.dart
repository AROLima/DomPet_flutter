import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'admin_produto_controller.dart';
import 'widgets/currency_field.dart';
import '../../../src/core/http/api_client.dart';
import 'package:go_router/go_router.dart';
import '../../../src/core/http/problem_detail.dart';
import '../../../src/features/products/products_service.dart';
import '../../../src/shared/models/product.dart';
import '../widgets/admin_drawer.dart';

// DIDACTIC: AdminProdutoFormPage — admin UI for creating/editing products

// Purpose:
// - Provide a form to create or edit product data including price, stock and
//   description fields.
//
// Contract:
// - Inputs: optional `editarId` to prefill fields when editing.
// - Outputs: calls controller/repository to persist changes and navigates on success.
//
// Notes:
//   a composition of form fields and action buttons.

class AdminProdutoFormPage extends ConsumerStatefulWidget {
  const AdminProdutoFormPage({super.key, this.editarId});
  final int? editarId;

  @override
  ConsumerState<AdminProdutoFormPage> createState() => _AdminProdutoFormPageState();
}

class _AdminProdutoFormPageState extends ConsumerState<AdminProdutoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final nome = TextEditingController();
  final sku = TextEditingController();
  final preco = TextEditingController();
  final estoque = TextEditingController();
  final thumbnail = TextEditingController();
  final descricao = TextEditingController();
  String? categoria;
  String? _etag; // captured from GET headers via dio cache is internal; we fetch explicitly on edit

  @override
  void initState() {
  super.initState();
    Future.microtask(() async {
      await ref.read(adminProdutoControllerProvider.notifier).loadCategorias();
      if (widget.editarId != null) {
        await ref.read(adminProdutoControllerProvider.notifier).carregarParaEdicao(widget.editarId!);
        final init = ref.read(adminProdutoControllerProvider).initial;
        if (init != null) {
          nome.text = init['nome']?.toString() ?? '';
          sku.text = init['sku']?.toString() ?? '';
          preco.text = _formatFromNumber(init['preco']);
          estoque.text = (init['estoque'] ?? '').toString();
          thumbnail.text = init['thumbnailUrl']?.toString() ?? '';
          descricao.text = init['descricao']?.toString() ?? '';
          categoria = init['categoria']?.toString();
          // Fetch to capture latest ETag for edit mode
          try {
            final dio = ref.read(dioProvider);
            final res = await dio.get('/produtos/${widget.editarId!}');
            _etag = res.headers.value('etag');
          } catch (_) {}
          setState(() {});
        }
      }
    });
  }

  String _formatFromNumber(dynamic v) {
    if (v == null) return '';
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    final cents = (n * 100).round();
    final intPart = (cents ~/ 100).toString();
    final frac = (cents % 100).toString().padLeft(2, '0');
    return '$intPart,$frac';
  }

  double _parsePreco(String text) {
    // Remove R$, spaces, and handle comma/period decimal separators
    String cleaned = text.replaceAll(RegExp(r'[R$\s]'), '');
    
    // Handle different decimal formats (e.g., "79,90" or "79.90")
    if (cleaned.contains(',')) {
      // Replace comma with period for decimal
      cleaned = cleaned.replaceAll(',', '.');
    }
    
    // Remove any remaining non-numeric characters except decimal point
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9.]'), '');
    
    if (cleaned.isEmpty) return 0.0;
    return double.tryParse(cleaned) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProdutoControllerProvider);
    final errs = state.errors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Início',
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
        title: Text(widget.editarId == null ? 'Novo Produto' : 'Editar Produto #${widget.editarId}'),
      ),
      drawer: const AdminDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 16, runSpacing: 16, children: [
                      SizedBox(
                        width: 420,
                        child: TextFormField(
                          controller: nome,
                          decoration: InputDecoration(labelText: 'Nome', errorText: errs['nome']),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: TextFormField(
                          controller: sku,
                          decoration: InputDecoration(labelText: 'SKU', errorText: errs['sku']),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          value: categoria,
                          items: state.categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => categoria = v),
                          decoration: const InputDecoration(labelText: 'Categoria'),
                          validator: (v) => (v == null || v.isEmpty) ? 'Selecione a categoria' : null,
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: CurrencyField(controller: preco, errorText: errs['preco']),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: estoque,
                          decoration: InputDecoration(labelText: 'Estoque', errorText: errs['estoque']),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: 420,
                        child: TextFormField(
                          controller: thumbnail,
                          decoration: const InputDecoration(labelText: 'Thumbnail URL'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descricao,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      ElevatedButton.icon(
                        onPressed: state.loading ? null : _onSalvar,
                        icon: const Icon(Icons.save),
                        label: Text(widget.editarId == null ? 'Salvar' : 'Atualizar'),
                      ),
                      const SizedBox(width: 12),
                      if (thumbnail.text.isNotEmpty)
                        CircleAvatar(backgroundImage: NetworkImage(thumbnail.text), radius: 20),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSalvar() async {
    if (!_formKey.currentState!.validate()) return;
    
    final dto = <String, dynamic>{
      'nome': nome.text.trim(),
      'descricao': descricao.text.trim().isEmpty ? null : descricao.text.trim(),
      'preco': _parsePreco(preco.text),
      'estoque': int.tryParse(estoque.text),
      'imagemUrl': thumbnail.text.trim().isEmpty ? null : thumbnail.text.trim(),
      'categoria': categoria,
      'ativo': true, // mantém ativo ao editar, compatível com update parcial
      'sku': sku.text.trim().isEmpty ? null : sku.text.trim(),
    };
    
    final notifier = ref.read(adminProdutoControllerProvider.notifier);
    try {
      if (widget.editarId == null) {
        final id = await notifier.salvarNovo(dto);
        if (!mounted) return;
  _showSnack('Produto criado (#$id)');
  context.go('/produto/$id');
      } else {
        try {
          final id = await notifier.salvarEdicao(widget.editarId!, dto, etag: _etag);
          if (!mounted) return;
          _showSnack('Produto atualizado (#$id)');
          // Invalidate providers to refresh data
          ref.invalidate(productDetailProvider(widget.editarId!));
          // Navigate to detail page
          if (mounted) context.go('/produto/${widget.editarId}');
        } on ProblemDetail catch (p) {
          if (!mounted) return;
          final sc = p.status ?? 0;
          if (sc == 409 || sc == 412) {
            final reload = await _showConflictDialog(context);
            if (reload == true && mounted) {
              // Reload data and ETag, stay on form for retry
              try {
                final dio = ref.read(dioProvider);
                final res = await dio.get('/produtos/${widget.editarId!}');
                _etag = res.headers.value('etag');
                final detail = ProdutoDetalhe.fromJson(res.data as Map<String, dynamic>);
                nome.text = detail.nome;
                sku.text = detail.sku ?? '';
                categoria = detail.categoria;
                preco.text = _formatFromNumber(detail.preco);
                estoque.text = detail.estoque.toString();
                thumbnail.text = detail.imagemUrl ?? '';
                descricao.text = detail.descricao ?? '';
                setState(() {});
              } catch (e) {
                _showSnack('Erro ao recarregar dados: $e');
              }
            }
          } else {
            // For other errors, show message and don't retry
            _showSnack('Erro ao salvar: ${p.title ?? p.detail ?? 'Erro desconhecido'}');
          }
        } catch (e) {
          if (!mounted) return;
          _showSnack('Erro ao salvar: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erro ao salvar: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool?> _showConflictDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflito de atualização'),
        content: const Text('O produto foi atualizado por outra pessoa. Recarregar e tentar novamente?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Fechar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Recarregar')),
        ],
      ),
    );
  }
}
