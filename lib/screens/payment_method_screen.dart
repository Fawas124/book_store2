import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final paymentMethods = authService.user?.paymentMethods ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = paymentMethods[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: Text('•••• •••• •••• ${method['last4']}'),
                      subtitle: Text('Expires ${method['expiry']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await authService.removePaymentMethod(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Add Payment Method'),
                    content: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _cardNameController,
                              decoration: const InputDecoration(
                                labelText: 'Name on Card',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the name on card';
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              controller: _cardNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Card Number',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a card number';
                                }
                                if (value.length < 16) {
                                  return 'Card number must be 16 digits';
                                }
                                return null;
                              },
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _expiryController,
                                    decoration: const InputDecoration(
                                      labelText: 'MM/YY',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter expiry date';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _cvvController,
                                    decoration: const InputDecoration(
                                      labelText: 'CVV',
                                    ),
                                    obscureText: true,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter CVV';
                                      }
                                      if (value.length < 3) {
                                        return 'CVV must be 3 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final newMethod = {
                              'cardName': _cardNameController.text,
                              'last4': _cardNumberController.text
                                  .substring(_cardNumberController.text.length - 4),
                              'expiry': _expiryController.text,
                            };
                            await authService.addPaymentMethod(newMethod);
                            Navigator.pop(context);
                            _cardNumberController.clear();
                            _expiryController.clear();
                            _cvvController.clear();
                            _cardNameController.clear();
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Add Payment Method'),
            ),
          ],
        ),
      ),
    );
  }
}