import 'package:book_store_2/models/order.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key, required List<Order> orders});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Stream<List<Order>> _ordersStream;
  Future<List<Order>>? _ordersFuture;
  bool _useStream = true; // Toggle between stream and future

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final orderService = Provider.of<OrderService>(context, listen: false);
    final userId = orderService.currentUserId;
    
    debugPrint('Initializing order data for user: $userId');
    
    if (_useStream) {
      _ordersStream = orderService.getUserOrdersStream(userId);
    } else {
      _refreshOrders();
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = Provider.of<OrderService>(context, listen: false)
          .getUserOrders(Provider.of<OrderService>(context).currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _useStream ? _initializeData : _refreshOrders,
          ),
          IconButton(
            icon: Icon(_useStream ? Icons.stream : Icons.list),
            onPressed: () {
              setState(() {
                _useStream = !_useStream;
                _initializeData();
              });
            },
            tooltip: _useStream ? 'Switch to list view' : 'Switch to real-time view',
          ),
        ],
      ),
      body: _useStream ? _buildStreamContent() : _buildFutureContent(),
    );
  }

  Widget _buildStreamContent() {
    return StreamBuilder<List<Order>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Order stream error: ${snapshot.error}');
          return _buildErrorWidget(context, snapshot.error.toString());
        }

        final orders = snapshot.data ?? [];
        debugPrint('Displaying ${orders.length} orders in stream');
        
        return _buildOrderContent(orders);
      },
    );
  }

  Widget _buildFutureContent() {
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(context, snapshot.error.toString());
          }

          final orders = snapshot.data ?? [];
          return _buildOrderContent(orders);
        },
      ),
    );
  }

  Widget _buildOrderContent(List<Order> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        debugPrint('Building order item: ${order.id}');
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              'Order #${order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMd().add_jm().format(order.date),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(
                order.status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              backgroundColor: _getStatusColor(order.status),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ...order.items.map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: item.book.coverUrl,
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.book, color: Colors.grey),
                              ),
                            ),
                          ),
                          title: Text(
                            item.book.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text('Qty: ${item.quantity}'),
                          trailing: Text(
                            '\$${(item.book.price * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )),
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${order.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading orders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.contains('permission-denied')
                ? 'Please sign in to view your orders'
                : 'An unexpected error occurred',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 16),
          if (error.contains('permission-denied'))
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Sign In'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your completed orders will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}