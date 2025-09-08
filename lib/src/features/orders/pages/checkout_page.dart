import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/order.dart';
import '../orders_service.dart';
import '../../cart/cart_service.dart';
import '../../../shared/models/cart.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _rua = TextEditingController();
  final _numero = TextEditingController();
  final _bairro = TextEditingController();
  final _cep = TextEditingController();
  final _cidade = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _rua.dispose();
    _numero.dispose();
    _bairro.dispose();
    _cep.dispose();
    _cidade.dispose();
    super.dispose();
  }

  Future<void> _finalizar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final endereco = EnderecoDto(
        rua: _rua.text,
        numero: _numero.text,
        bairro: _bairro.text,
        cep: _cep.text,
        cidade: _cidade.text,
      );
      final pedido = await ref.read(ordersServiceProvider).checkout(endereco: endereco);
      // Atualiza o carrinho globalmente após checkout
      ref.read(cartRefreshTickProvider.notifier).state++;
      if (!mounted) return;
      context.go('/pedidos/${pedido.id}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao finalizar pedido')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(cartRefreshTickProvider); // refetch cart when bumped
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Resumo do carrinho
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<Carrinho>(
                  future: ref.read(cartControllerProvider).fetchCart(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      if (snap.hasError) return const Text('Erro ao carregar carrinho');
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    final cart = snap.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.shopping_cart_outlined),
                            SizedBox(width: 8),
                            Text('Resumo do carrinho', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (cart.itens.isEmpty)
                          const Text('Seu carrinho está vazio')
                        else ...[
                          ...cart.itens.map((i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(i.nome, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 12),
                                    Text('x${i.quantidade}  R\$ ${i.subtotal.toStringAsFixed(2)}'),
                                  ],
                                ),
                              )),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Flexible(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'R\$ ${cart.total.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Endereço de entrega
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 640;
                      if (isWide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.local_shipping_outlined),
                                SizedBox(width: 8),
                                Text('Endereço de entrega', style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _field(_rua, 'Rua', icon: Icons.home_outlined, action: TextInputAction.next),
                            Row(
                              children: [
                                Expanded(
                                  child: _field(
                                    _numero,
                                    'Número',
                                    keyboard: TextInputType.number,
                                    formatters: [FilteringTextInputFormatter.digitsOnly],
                                    icon: Icons.confirmation_number_outlined,
                                    action: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _field(
                                    _cep,
                                    'CEP',
                                    keyboard: TextInputType.number,
                                    formatters: [FilteringTextInputFormatter.digitsOnly],
                                    maxLength: 8,
                                    icon: Icons.pin_drop_outlined,
                                    action: TextInputAction.next,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _field(
                                    _bairro,
                                    'Bairro',
                                    icon: Icons.map_outlined,
                                    action: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _field(
                                    _cidade,
                                    'Cidade',
                                    icon: Icons.location_city_outlined,
                                    action: TextInputAction.done,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      // Narrow layout
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.local_shipping_outlined),
                              SizedBox(width: 8),
                              Text('Endereço de entrega', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _field(_rua, 'Rua', icon: Icons.home_outlined, action: TextInputAction.next),
                          _field(
                            _numero,
                            'Número',
                            keyboard: TextInputType.number,
                            formatters: [FilteringTextInputFormatter.digitsOnly],
                            icon: Icons.confirmation_number_outlined,
                            action: TextInputAction.next,
                          ),
                          _field(
                            _cep,
                            'CEP',
                            keyboard: TextInputType.number,
                            formatters: [FilteringTextInputFormatter.digitsOnly],
                            maxLength: 8,
                            icon: Icons.pin_drop_outlined,
                            action: TextInputAction.next,
                          ),
                          _field(_bairro, 'Bairro', icon: Icons.map_outlined, action: TextInputAction.next),
                          _field(_cidade, 'Cidade', icon: Icons.location_city_outlined, action: TextInputAction.done),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botão finalizar
            FutureBuilder<Carrinho>(
              future: ref.read(cartControllerProvider).fetchCart(),
              builder: (context, snap) {
                final total = snap.data?.total;
                final isEmpty = snap.data?.itens.isEmpty == true;
                return SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: (_submitting || isEmpty == true) ? null : _finalizar,
                      icon: _submitting
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check),
                      label: Text('Finalizar${total != null ? ' — R\$ ${total.toStringAsFixed(2)}' : ''}'),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    int? maxLength,
    IconData? icon,
    TextInputAction action = TextInputAction.next,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        textInputAction: action,
        keyboardType: keyboard,
        inputFormatters: formatters,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          counterText: maxLength != null ? '' : null,
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        validator: required ? (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null : null,
      ),
    );
  }
}
