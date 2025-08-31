import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'admin_produto_controller.dart';
import 'widgets/currency_field.dart';

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
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0.0;
    final cents = int.parse(digits);
    return cents / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProdutoControllerProvider);
    final errs = state.errors;

    return Scaffold(
      appBar: AppBar(title: Text(widget.editarId == null ? 'Novo Produto' : 'Editar Produto #${widget.editarId}')),
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
      'sku': sku.text.trim().isEmpty ? null : sku.text.trim(),
      'categoria': categoria,
      'preco': _parsePreco(preco.text),
      'estoque': int.tryParse(estoque.text) ?? 0,
      'descricao': descricao.text.trim().isEmpty ? null : descricao.text.trim(),
      'imagemUrl': thumbnail.text.trim().isEmpty ? null : thumbnail.text.trim(),
    };
    final notifier = ref.read(adminProdutoControllerProvider.notifier);
    try {
      if (widget.editarId == null) {
        final id = await notifier.salvarNovo(dto);
        if (!mounted) return;
        _showSnack('Produto criado (#$id)');
      } else {
        final id = await notifier.salvarEdicao(widget.editarId!, dto);
        if (!mounted) return;
        _showSnack('Produto atualizado (#$id)');
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Erro ao salvar');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
