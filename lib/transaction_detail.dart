import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:budget_tracker/add_transaction.dart';
import 'package:budget_tracker/database_helper.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  TransactionDetailScreen({required this.transaction});

  void _deleteTransaction(BuildContext context) async {
    await _dbHelper.deleteTransaction(transaction['id']);
    Navigator.pop(context, true); // Return true to indicate deletion
  }

  void _editTransaction(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );
    if (result != null) {
      Navigator.pop(context, true); // Return true to indicate editing
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        DateFormat('yyyy-MM-dd').format(DateTime.parse(transaction['date']));
    String capitalizedType =
        transaction['type'][0].toUpperCase() + transaction['type'].substring(1);

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editTransaction(context),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteTransaction(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${transaction['name']}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Date: $formattedDate',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Type: $capitalizedType',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Category: ${transaction['category'] ?? 'No category'}',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${transaction['description'] ?? ''}',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${transaction['amount'].toStringAsFixed(2)} €',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
