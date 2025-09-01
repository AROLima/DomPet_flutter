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
import '../../../ui/design_system.dart';
import '../../../ui/widgets/responsive_scaffold.dart';

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
  int? _sortColumnIndex; // 1=Nome, 2=Preço, 3=Estoque
  bool _sortAsc = true;
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
  // Map column index to backend sort field
  String? sortField;
  if (_sortColumnIndex == 1) sortField = 'nome';
  if (_sortColumnIndex == 2) sortField = 'preco';
  if (_sortColumnIndex == 3) sortField = 'estoque';
  final sortParam = sortField != null ? '$sortField,${_sortAsc ? 'asc' : 'desc'}' : null;
  final q = ProductsQuery(nome: _qCtrl.text, categoria: _categoria, page: _page, size: 20, sort: sortParam);
    final pageAsync = ref.watch(productsSearchProvider(q));
    final catsAsync = ref.watch(categoriasProvider);
    final controller = ref.watch(adminProdutoControllerProvider);

  // Snackbar handling is done once in initState.

    return ResponsiveScaffold(
      title: const Text('Admin · Produtos'),
      drawer: const AdminDrawer(),
      fab: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/produtos/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= AppBreakpoints.sm;
                if (wide) {
                  return Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _qCtrl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar por nome',
                        ),
                        onSubmitted: (_) => setState(() => _page = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: catsAsync.when(
                        data: (cats) => DropdownButtonFormField<String?>(
                          isExpanded: true,
                          value: _categoria,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            prefixIcon: Icon(Icons.category_outlined),
                            labelText: 'Categoria',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                            ...cats.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                          ],
                          onChanged: (v) => setState(() {
                            _categoria = v;
                            _page = 0;
                          }),
                        ),
                        loading: () => const SizedBox(height: 24, child: LinearProgressIndicator(minHeight: 4)),
                        error: (e, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ]);
                }
                // Narrow: stack vertically to avoid overflow
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _qCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar por nome',
                      ),
                      onSubmitted: (_) => setState(() => _page = 0),
                    ),
                    const SizedBox(height: 8),
                    catsAsync.when(
                      data: (cats) => DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: _categoria,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          hintText: 'Categoria',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                          ...cats.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                        ],
                        onChanged: (v) => setState(() {
                          _categoria = v;
                          _page = 0;
                        }),
                      ),
                      loading: () => const SizedBox(height: 24, child: LinearProgressIndicator(minHeight: 4)),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pageAsync.when(
                data: (page) => LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= AppBreakpoints.sm;
                    return wide ? _TableView(page: page, deletingId: controller.deletingId) : _CardsView(page: page, deletingId: controller.deletingId);
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Erro ao carregar: $e')),
              ),
            ),
            const SizedBox(height: 8),
            // Paginator inside body so it stays visible across breakpoints
            pageAsync.when(
              data: (p) => _Paginator(
                page: p,
                onPrev: _page > 0 ? () => setState(() => _page -= 1) : null,
                onNext: !p.last ? () => setState(() => _page += 1) : null,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
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
    final scheme = Theme.of(context).colorScheme;
    final rows = <DataRow>[];
    for (var i = 0; i < page.content.length; i++) {
      final p = page.content[i];
      final bg = i.isEven ? scheme.surfaceContainerHighest.withOpacity(0.06) : Colors.transparent;
      rows.add(
        DataRow(
          color: MaterialStatePropertyAll<Color>(bg),
          cells: [
            DataCell(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: p.imagemUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          p.imagemUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => const Icon(Icons.pets),
                        ),
                      )
                    : const Icon(Icons.pets),
              ),
            ),
            DataCell(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(p.nome, overflow: TextOverflow.ellipsis),
              ),
            ),
            DataCell(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Align(alignment: Alignment.centerRight, child: Text(formatBrl(p.preco))),
              ),
            ),
            DataCell(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Chip(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    label: Text(p.estoque.toString()),
                    backgroundColor: p.estoque > 0 ? scheme.secondaryContainer : scheme.errorContainer,
                    labelStyle: TextStyle(
                      color: p.estoque > 0 ? scheme.onSecondaryContainer : scheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            DataCell(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _RowActions(produto: p, deleting: deletingId == p.id),
              ),
            ),
          ],
        ),
      );
    }

    // Make the table scrollable in both directions
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: SingleChildScrollView(
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 68,
              columnSpacing: 32,
              headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              sortColumnIndex: context.findAncestorStateOfType<_AdminProdutosPageState>()?._sortColumnIndex,
              sortAscending: context.findAncestorStateOfType<_AdminProdutosPageState>()?._sortAsc ?? true,
              columns: [
                const DataColumn(label: Text('Imagem')),
                DataColumn(
                  label: const Text('Nome'),
                  onSort: (i, asc) {
                    final s = context.findAncestorStateOfType<_AdminProdutosPageState>();
                    s?.setState(() {
                      s._sortColumnIndex = i;
                      s._sortAsc = asc;
                      s._page = 0;
                    });
                  },
                ),
                DataColumn(
                  numeric: true,
                  label: const Text('Preço'),
                  onSort: (i, asc) {
                    final s = context.findAncestorStateOfType<_AdminProdutosPageState>();
                    s?.setState(() {
                      s._sortColumnIndex = i;
                      s._sortAsc = asc;
                      s._page = 0;
                    });
                  },
                ),
                DataColumn(
                  numeric: true,
                  label: const Text('Estoque'),
                  onSort: (i, asc) {
                    final s = context.findAncestorStateOfType<_AdminProdutosPageState>();
                    s?.setState(() {
                      s._sortColumnIndex = i;
                      s._sortAsc = asc;
                      s._page = 0;
                    });
                  },
                ),
                const DataColumn(label: Text('Ações')),
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
  final scheme = Theme.of(context).colorScheme;
  return ListView.separated(
      itemCount: page.content.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = page.content[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (p.imagemUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      p.imagemUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const Icon(Icons.pets),
                    ),
                  )
                else
                  const Icon(Icons.pets),
                const SizedBox(width: 14),
                Expanded(child: Text(p.nome, style: Theme.of(context).textTheme.titleMedium)),
                Text(formatBrl(p.preco), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Chip(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  label: Text('Estoque: ${p.estoque}'),
                  backgroundColor: p.estoque > 0 ? scheme.secondaryContainer : scheme.errorContainer,
                  labelStyle: TextStyle(
                    color: p.estoque > 0 ? scheme.onSecondaryContainer : scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
  const SizedBox(width: 10),
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
