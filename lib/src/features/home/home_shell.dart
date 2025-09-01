// DIDACTIC: HomeShell — top-level home screen composition
//
// Purpose:
// - Compose the home experience: search, featured carousel, category
//   shortcuts and several product sections. This widget orchestrates UI
//   state (search text, suggestions) and delegates data-fetching to
//   providers/services.
//
// Contract:
// - Inputs: user search input, selected category state.
// - Outputs: navigation events (push/search) and UI rendering.
// - Error modes: data fetching errors are handled by child providers and
//   surfaced as simple placeholders or messages.
//
// Implementation note:
// - Keep heavy async logic in providers/services; use local controllers only
//   for ephemeral UI state (debounce timers, controllers).

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
import '../../../ui/widgets/home_app_drawer.dart';

// Home shell combines search, shortcuts, featured carousel and several
// horizontal product sections. It keeps local search/autocomplete state and
// pushes navigation events to the product listing page with query params.
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
    // Show access denied toast if redirected here with ?denied=1
    try {
      final r = Router.maybeOf(context);
      String? loc;
      if (r?.routeInformationProvider case final p?) {
        loc = p.value.location;
      }
      loc ??= Uri.base.toString();
      final uri = Uri.parse(loc);
      if (uri.queryParameters['denied'] == '1') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acesso restrito')));
        });
      }
    } catch (_) {}
    return ResponsiveScaffold(
      drawer: const HomeAppDrawer(),
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
              if (selectedCat != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Filtrando por', style: Theme.of(context).textTheme.labelLarge),
                      Chip(
                        label: Text(
                          selectedCat,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        onDeleted: () => ref.read(selectedCategoryProvider.notifier).state = null,
                        deleteIcon: const Icon(Icons.close),
                        deleteIconColor: Theme.of(context).colorScheme.onSecondaryContainer,
                        side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              CategoryShortcuts(
                selected: selectedCat,
                onChanged: (cat) {
                  ref.read(selectedCategoryProvider.notifier).state = cat;
                },
              ),
              const SizedBox(height: 24),
              FeaturedCarousel(category: selectedCat),
              const SizedBox(height: 24),
              // Use supported sort field; 'vendidos' doesn't exist on backend entity
              HorizontalProducts(title: 'Ofertas', sort: 'id,desc', size: 12, category: selectedCat),
              const SizedBox(height: 24),
              HorizontalProducts(title: 'Mais vendidos', sort: 'id,desc', size: 12, category: selectedCat),
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
