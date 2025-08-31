import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ui/design_system.dart';
import '../products/products_service.dart';
import '../cart/cart_service.dart';
import 'widgets/featured_carousel.dart';
import 'widgets/category_shortcuts.dart';
import 'selected_category.dart';
import '../products/widgets/horizontal_products.dart';
import '../../../ui/widgets/responsive_scaffold.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final _searchCtrl = TextEditingController();
  Timer? _debouncer;
  List<String> _suggestions = [];
  bool _loading = false;

  Future<void> _loadSugs(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final sugs = await ref.read(productsServiceProvider).suggestions(q, limit: 6);
      setState(() => _suggestions = sugs.map((e) => e.nome).toList());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      _debouncer?.cancel();
      _debouncer = Timer(const Duration(milliseconds: 300), () => _loadSugs(_searchCtrl.text));
    });
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCat = ref.watch(selectedCategoryProvider);
    return ResponsiveScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              _BigSearch(
                controller: _searchCtrl,
                loading: _loading,
                suggestions: _suggestions,
                onSubmit: (q) => context.push('/produtos?q=${Uri.encodeComponent(q)}'),
              ),
              const SizedBox(height: 24),
              CategoryShortcuts(
                selected: selectedCat,
                onChanged: (cat) {
                  ref.read(selectedCategoryProvider.notifier).state = cat;
                },
              ),
              const SizedBox(height: 24),
              if (selectedCat != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Filtrando por', style: Theme.of(context).textTheme.labelLarge),
                      Chip(
                        label: Text(selectedCat),
                        onDeleted: () => ref.read(selectedCategoryProvider.notifier).state = null,
                      ),
                    ],
                  ),
                ),
              FeaturedCarousel(category: selectedCat),
              const SizedBox(height: 24),
              HorizontalProducts(title: 'Ofertas', sort: 'vendidos,desc', size: 12, category: selectedCat),
              const SizedBox(height: 24),
              HorizontalProducts(title: 'Mais vendidos', sort: 'vendidos,desc', size: 12, category: selectedCat),
              const SizedBox(height: 24),
              HorizontalProducts(title: 'Novidades', sort: 'id,desc', size: 12, category: selectedCat),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigSearch extends StatelessWidget {
  const _BigSearch({required this.controller, required this.suggestions, required this.onSubmit, required this.loading});
  final TextEditingController controller;
  final List<String> suggestions;
  final void Function(String) onSubmit;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          onSubmitted: onSubmit,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: loading ? const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : const Icon(Icons.qr_code_scanner),
            hintText: 'O que seu pet precisa?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              shrinkWrap: true,
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.search),
                title: Text(suggestions[i]),
                onTap: () => onSubmit(suggestions[i]),
              ),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: suggestions.length,
            ),
          ),
        ],
      ],
    );
  }
}
