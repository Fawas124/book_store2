import 'package:book_store_2/models/order.dart' as models;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/order_service.dart' show DeliveryStatus, OrderService;

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key, required List<models.Order> orders});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Stream<List<models.Order>> _ordersStream;
  Future<List<models.Order>>? _ordersFuture;
  bool _useStream = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final orderService = Provider.of<OrderService>(context, listen: false);
    final userId = orderService.currentUserId;
    
    if (_useStream) {
      _ordersStream = orderService.getUserOrdersStream(userId);
    } else {
      _refreshOrders();
    }
  }

  Future<void> _refreshOrders() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    try {
      final orders = await Provider.of<OrderService>(context, listen: false)
          .getUserOrders(Provider.of<OrderService>(context).currentUserId);
      setState(() => _ordersFuture = Future.value(orders));
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const CircularProgressIndicator()
                : const Icon(Icons.refresh),
            onPressed: _useStream ? _initializeData : _refreshOrders,
          ),
          IconButton(
            icon: Icon(_useStream ? Icons.stream : Icons.list),
            onPressed: () => setState(() {
              _useStream = !_useStream;
              _initializeData();
            }),
            tooltip: _useStream ? 'Switch to list view' : 'Switch to real-time view',
          ),
        ],
      ),
      body: _useStream ? _buildStreamContent() : _buildFutureContent(),
    );
  }

  Widget _buildStreamContent() {
    return StreamBuilder<List<models.Order>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(context, snapshot.error.toString());
        }

        return _buildOrderContent(snapshot.data ?? []);
      },
    );
  }

  Widget _buildFutureContent() {
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: FutureBuilder<List<models.Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(context, snapshot.error.toString());
          }

          return _buildOrderContent(snapshot.data ?? []);
        },
      ),
    );
  }

  Widget _buildOrderContent(List<models.Order> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
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
              _buildDeliveryStatusSection(order),
              _buildOrderItemsSection(order),
              if (order.trackingNumber != null) _buildTrackingSection(order),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryStatusSection(models.Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DELIVERY STATUS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: models.DeliveryStatus.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = models.DeliveryStatus.values[index];
                final isActive = order.deliveryStatus == status;
                final isCompleted = _isStatusCompleted(order, status);
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted 
                          ? Colors.green 
                          : isActive 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[300],
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive ? Colors.black : Colors.grey,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (order.deliveryUpdates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Latest update: ${DateFormat.yMMMd().add_jm().format(order.deliveryUpdates.last.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  bool _isStatusCompleted(models.Order order, models.DeliveryStatus status) {
    final currentIndex = models.DeliveryStatus.values.indexOf(order.deliveryStatus as models.DeliveryStatus);
    final statusIndex = models.DeliveryStatus.values.indexOf(status);
    return statusIndex < currentIndex;
  }

  String _getStatusLabel(models.DeliveryStatus status) {
    return status.toString().split('.').last.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (Match m) => ' ${m.group(0)}',
    ).trim();
  }

  Widget _buildTrackingSection(models.Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRACKING INFORMATION',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.local_shipping),
            title: Text(order.carrier ?? 'Unknown carrier'),
            subtitle: Text('Tracking #: ${order.trackingNumber}'),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openTrackingWebsite(order),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTrackingWebsite(models.Order order) async {
    final carrier = order.carrier?.toLowerCase() ?? '';
    final trackingNumber = order.trackingNumber ?? '';
    String url;

    if (carrier.contains('fedex')) {
      url = 'https://www.fedex.com/fedextrack/?trknbr=$trackingNumber';
    } else if (carrier.contains('ups')) {
      url = 'https://www.ups.com/track?tracknum=$trackingNumber';
    } else if (carrier.contains('usps')) {
      url = 'https://tools.usps.com/go/TrackConfirmAction?tLabels=$trackingNumber';
    } else if (carrier.contains('dhl')) {
      url = 'https://www.dhl.com/en/express/tracking.html?AWB=$trackingNumber';
    } else {
      url = 'https://www.google.com/search?q=${order.carrier}+tracking+$trackingNumber';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildOrderItemsSection(models.Order order) {
    return Padding(
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
                const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
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