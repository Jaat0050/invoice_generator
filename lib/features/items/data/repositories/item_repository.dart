import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item_model.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

class ItemRepository {
  final List<ItemModel> _mockItems = [
    const ItemModel(
      id: 1,
      businessId: 1,
      name: 'MacBook Pro 16" M3 Max',
      sku: 'APP-MBP-16',
      hsnSac: '84713010',
      unit: 'NOS',
      rate: 249900.0,
      taxRate: 18.0,
      itemType: 'product',
      description: 'Apple M3 Max Chip, 36GB RAM, 1TB SSD',
    ),
    const ItemModel(
      id: 2,
      businessId: 1,
      name: 'Dell UltraSharp 27" 4K Monitor',
      sku: 'DEL-U2723QE',
      hsnSac: '85285200',
      unit: 'NOS',
      rate: 54999.0,
      taxRate: 18.0,
      itemType: 'product',
      description: 'IPS Black technology, USB-C Hub',
    ),
    const ItemModel(
      id: 3,
      businessId: 1,
      name: 'Logitech MX Master 3S Wireless Mouse',
      sku: 'LOG-MX3S',
      hsnSac: '84716060',
      unit: 'NOS',
      rate: 8995.0,
      taxRate: 18.0,
      itemType: 'product',
      description: 'Quiet clicks, 8K DPI tracking',
    ),
    const ItemModel(
      id: 4,
      businessId: 1,
      name: 'Cloud Infrastructure Architecture & Consulting',
      sku: 'SRV-CLOUD-CNS',
      hsnSac: '998315',
      unit: 'HRS',
      rate: 7500.0,
      taxRate: 18.0,
      itemType: 'service',
      description: 'AWS / GCP Cloud deployment, security audit & optimization',
    ),
    const ItemModel(
      id: 5,
      businessId: 1,
      name: 'Mobile App Custom Development Retainer',
      sku: 'SRV-MOB-DEV',
      hsnSac: '998314',
      unit: 'HRS',
      rate: 4500.0,
      taxRate: 18.0,
      itemType: 'service',
      description: 'Flutter iOS & Android full-stack development service',
    ),
  ];

  Future<List<ItemModel>> getItems({String? searchQuery}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (searchQuery == null || searchQuery.isEmpty) {
      return List.unmodifiable(_mockItems);
    }
    final q = searchQuery.toLowerCase();
    return _mockItems.where((item) {
      return item.name.toLowerCase().contains(q) ||
          (item.hsnSac?.contains(q) ?? false) ||
          (item.sku?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<ItemModel> addItem(ItemModel item) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newItem = item.copyWith(id: _mockItems.length + 1);
    _mockItems.insert(0, newItem);
    return newItem;
  }
}
