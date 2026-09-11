import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

class CustomerRepository {
  final List<CustomerModel> _mockCustomers = [
    CustomerModel(
      id: 1,
      businessId: 1,
      name: 'Rahul Verma',
      companyName: 'ABC Enterprises Pvt Ltd',
      email: 'rahul@abcenterprises.com',
      phone: '+91 98220 12345',
      gstin: '27AAACA4567D1Z2',
      pan: 'AAACA4567D',
      billingAddress: '45, Nariman Point, Marine Drive',
      billingCity: 'Mumbai',
      billingState: 'Maharashtra',
      billingStateCode: '27',
      billingPincode: '400021',
      totalSales: 500000.0,
      totalPaid: 400000.0,
      outstandingAmount: 100000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    CustomerModel(
      id: 2,
      businessId: 1,
      name: 'Priya Sharma',
      companyName: 'TechVision Infotech',
      email: 'priya@techvision.io',
      phone: '+91 98450 98765',
      gstin: '29BBBCB8910E1Z9',
      pan: 'BBBCB8910E',
      billingAddress: '12th Cross, Indiranagar',
      billingCity: 'Bengaluru',
      billingState: 'Karnataka',
      billingStateCode: '29',
      billingPincode: '560038',
      totalSales: 250000.0,
      totalPaid: 250000.0,
      outstandingAmount: 0.0,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    CustomerModel(
      id: 3,
      businessId: 1,
      name: 'Vikram Mehta',
      companyName: 'Mehta Logistics & Supply',
      email: 'vikram@mehtalogistics.in',
      phone: '+91 99100 54321',
      gstin: '07CCCCM1122F1Z8',
      pan: 'CCCCM1122F',
      billingAddress: 'Plot 88, Okhla Industrial Area Phase 3',
      billingCity: 'New Delhi',
      billingState: 'Delhi',
      billingStateCode: '07',
      billingPincode: '110020',
      totalSales: 750000.0,
      totalPaid: 600000.0,
      outstandingAmount: 150000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  Future<List<CustomerModel>> getCustomers({String? searchQuery}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (searchQuery == null || searchQuery.isEmpty) {
      return List.unmodifiable(_mockCustomers);
    }
    final q = searchQuery.toLowerCase();
    return _mockCustomers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.companyName?.toLowerCase().contains(q) ?? false) ||
          c.phone.contains(q);
    }).toList();
  }

  Future<CustomerModel> getCustomerById(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockCustomers.firstWhere((c) => c.id == id);
  }

  Future<CustomerModel> addCustomer(CustomerModel customer) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newCustomer = customer.copyWith(
      id: _mockCustomers.length + 1,
      createdAt: DateTime.now(),
    );
    _mockCustomers.insert(0, newCustomer);
    return newCustomer;
  }
}
