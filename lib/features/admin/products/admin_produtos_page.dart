import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../src/features/products/products_service.dart';
import '../../../src/shared/models/page_result.dart';
import '../../../src/shared/models/product.dart';
import 'admin_produto_controller.dart';
import '../widgets/admin_drawer.dart';

// AdminProdutosPage — responsive list with edit/delete actions
// - Uses productsSearchProvider for data, keeps admin-only actions.
// - Per-item delete shows confirmation dialog and disables only that row button.

class AdminProdutosPage extends ConsumerStatefulWidget {
  const AdminProdutosPage({super.key});

  @override
  ConsumerState<AdminProdutosPage> createState() => _AdminProdutosPageState();
}

class _AdminProdutosPageState extends ConsumerState<AdminProdutosPage> {
  final _qCtrl = TextEditingController();
  String? _categoria;
  int _page = 0;
  Timer? _debouncer;
  bool _deleteSnackHandled = false;

  @override
  void initState() {
    super.initState();
    _qCtrl.addListener(() {
      _debouncer?.cancel();
      _debouncer = Timer(const Duration(milliseconds: 300), () {
        setState(() => _page = 0);
      });
    });

    // Show a one-time snackbar if returned with ?deleted=1, then strip the query.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_deleteSnackHandled || !mounted) return;
      _deleteSnackHandled = true;
      try {
        String? loc;
        final r = Router.maybeOf(context);
        if (r?.routeInformationProvider case final p?) {
          loc = p.value.location;
        }
        loc ??= Uri.base.toString();
        final uri = Uri.parse(loc);
        if (uri.queryParameters['deleted'] == '1') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto excluído')),
          );
          // Replace URL to avoid re-triggering on rebuilds
          context.replace('/admin/produtos');
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = ProductsQuery(nome: _qCtrl.text, categoria: _categoria, page: _page, size: 20);
    final pageAsync = ref.watch(productsSearchProvider(q));
    final catsAsync = ref.watch(categoriasProvider);
    final controller = ref.watch(adminProdutoControllerProvider);

  // Snackbar handling is done once in initState.

    return Scaffold(
  appBar: AppBar(
        leading: IconButton(
          tooltip: 'Início',
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Admin · Produtos'),
      ),
  drawer: const AdminDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/produtos/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      // Move the paginator to a bottom bar so it won't be covered by the FAB
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: pageAsync.when(
            data: (p) => _Paginator(
              page: p,
              onPrev: _page > 0 ? () => setState(() => _page -= 1) : null,
              onNext: !p.last ? () => setState(() => _page += 1) : null,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _qCtrl,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nome'),
                  onSubmitted: (_) => setState(() => _page = 0),
                ),
              ),
              const SizedBox(width: 8),
              catsAsync.when(
                data: (cats) => DropdownButton<String?>(
                  value: _categoria,
                  hint: const Text('Categoria'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                    ...cats.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() {
                    _categoria = v;
                    _page = 0;
                  }),
                ),
                loading: () => const SizedBox(width: 160, height: 24, child: LinearProgressIndicator()),
                error: (e, _) => const SizedBox(),
              ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: pageAsync.when(
                data: (page) => LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 900;
                    return wide ? _TableView(page: page, deletingId: controller.deletingId) : _CardsView(page: page, deletingId: controller.deletingId);
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Erro ao carregar: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Paginator extends StatelessWidget {
  const _Paginator({required this.page, this.onPrev, this.onNext});
  final PageResult<Produto> page;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Página ${page.number + 1} de ${page.totalPages}')
      , const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Tooltip(
              message: 'Anterior',
              child: IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
            ),
            Tooltip(
              message: 'Próxima',
              child: IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
            ),
          ]),
        ),
      ],
    );
  }
}

class _TableView extends ConsumerWidget {
  const _TableView({required this.page, required this.deletingId});
  final PageResult<Produto> page;
  final int? deletingId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = page.content.map((p) => DataRow(cells: [
          DataCell(p.imagemUrl != null ? Image.network(p.imagemUrl!, width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.image_not_supported)),
          DataCell(Text(p.nome)),
          DataCell(Text('R\$ ${p.preco.toStringAsFixed(2)}')),
          DataCell(Text(p.estoque.toString())),
          DataCell(_RowActions(produto: p, deleting: deletingId == p.id)),
        ])).toList();

    // Make the table scrollable in both directions
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Imagem')),
                DataColumn(label: Text('Nome')),
                DataColumn(label: Text('Preço')),
                DataColumn(label: Text('Estoque')),
                DataColumn(label: Text('Ações')),
              ],
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardsView extends ConsumerWidget {
  const _CardsView({required this.page, required this.deletingId});
  final PageResult<Produto> page;
  final int? deletingId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
  return ListView.separated(
      itemCount: page.content.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = page.content[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (p.imagemUrl != null)
                  Image.network(p.imagemUrl!, width: 56, height: 56, fit: BoxFit.cover)
                else
                  const Icon(Icons.image_not_supported),
                const SizedBox(width: 12),
                Expanded(child: Text(p.nome, style: Theme.of(context).textTheme.titleMedium)),
                Text('R\$ ${p.preco.toStringAsFixed(2)}'),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Text('Estoque: ${p.estoque}'),
                const Spacer(),
                _RowActions(produto: p, deleting: deletingId == p.id),
              ])
            ]),
          ),
        );
      },
    );
  }
}

class _RowActions extends ConsumerWidget {
  const _RowActions({required this.produto, required this.deleting});
  final Produto produto;
  final bool deleting;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(adminProdutoControllerProvider.notifier);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Tooltip(
          message: 'Editar',
          child: Semantics(
            label: 'Editar produto',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/admin/produtos/${produto.id}/editar'),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Excluir',
          child: Semantics(
            label: 'Excluir produto',
            button: true,
            child: IconButton(
              icon: deleting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete),
              onPressed: deleting ? null : () => context.push('/admin/produtos/${produto.id}/excluir'),
            ),
          ),
        ),
      ]),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return _ConfirmDialog(
          title: 'Excluir produto?',
          message: 'Esta ação pode ser irreversível. Deseja continuar?',
          confirmText: 'Excluir',
          cancelText: 'Cancelar',
        );
      },
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.title, required this.message, required this.confirmText, required this.cancelText});
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) {
            Navigator.of(context).pop(true);
            return null;
          }),
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (intent) {
            Navigator.of(context).pop(false);
            return null;
          }),
        },
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelText)),
            FilledButton.tonalIcon(icon: const Icon(Icons.delete), onPressed: () => Navigator.of(context).pop(true), label: Text(confirmText)),
          ],
        ),
      ),
    );
  }
}

// Drawer moved to shared AdminDrawer
