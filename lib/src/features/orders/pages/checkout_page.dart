// DIDACTIC: CheckoutPage — checkout orchestration UI
//
// Purpose:
// - Collect shipping/payment choices and call OrdersService to place an order.
//
// Contract:
// - Inputs: cart state, selected address/payment method.
// - Outputs: order creation request and navigation to order confirmation.
// - Error modes: handle validation errors and surface friendly messages.
//
// Notes:
// - Keep sensitive payment logic minimal in the client; delegate to secure
//   payment providers when possible.

// Checkout page UI and form.
// Contract:
// - Collects address fields and posts them to `ordersServiceProvider.checkout`.
// - On success navigates to the order detail page.
// Edge cases:
// - Form validations are minimal; rely on server-side validation and
//   ProblemDetail for user-friendly errors.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/order.dart';
import '../orders_service.dart';

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
  final _complemento = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _rua.dispose();
    _numero.dispose();
    _bairro.dispose();
    _cep.dispose();
    _cidade.dispose();
    _complemento.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final endereco = EnderecoDto(
        rua: _rua.text,
        numero: _numero.text,
        bairro: _bairro.text,
        cep: _cep.text,
        cidade: _cidade.text,
        complemento: _complemento.text.isEmpty ? null : _complemento.text,
      );
      final pedido = await ref.read(ordersServiceProvider).checkout(endereco: endereco);
      if (!mounted) return;
      context.go('/pedidos/${pedido.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no checkout: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(controller: _rua, decoration: const InputDecoration(labelText: 'Rua'), validator: _req),
                  TextFormField(controller: _numero, decoration: const InputDecoration(labelText: 'Número'), validator: _req),
                  TextFormField(controller: _bairro, decoration: const InputDecoration(labelText: 'Bairro'), validator: _req),
                  TextFormField(controller: _cep, decoration: const InputDecoration(labelText: 'CEP'), validator: _req),
                  TextFormField(controller: _cidade, decoration: const InputDecoration(labelText: 'Cidade'), validator: _req),
                  TextFormField(controller: _complemento, decoration: const InputDecoration(labelText: 'Complemento (opcional)')),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Finalizar pedido'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.isEmpty) ? 'Obrigatório' : null;
}
