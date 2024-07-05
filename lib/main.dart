import 'package:flutter/material.dart';
import 'package:budget_tracker/database_helper.dart';
import 'package:budget_tracker/add_transaction.dart';
import 'package:budget_tracker/transaction_detail.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  List<Map<String, dynamic>> transactions = [];
  DateTime? startDate;
  DateTime? endDate;
  String? selectedCategory;

  final List<String> _incomeCategories = [
    'Salary',
    'Investment',
    'Gift',
    'Freelance',
    'Other Income'
  ];

  final List<String> _expenseCategories = [
    'Housing',
    'Transportation',
    'Food',
    'Health',
    'Personal Care',
    'Entertainment',
    'Education',
    'Credit',
    'Pet',
    'Family',
    'Other Expenses'
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  void _fetchTransactions() async {
    List<Map<String, dynamic>> data = await _dbHelper.getTransactions();
    double income = 0.0;
    double expense = 0.0;

    for (var transaction in data) {
      if (transaction['type'] == 'income') {
        income += transaction['amount'];
      } else {
        expense += transaction['amount'];
      }
    }

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      transactions = data;
    });
  }

  void _filterTransactions(
      DateTime? start, DateTime? end, String? category) async {
    List<Map<String, dynamic>> data = await _dbHelper.getTransactions();
    double income = 0.0;
    double expense = 0.0;

    List<Map<String, dynamic>> filteredData = data.where((transaction) {
      DateTime date = DateTime.parse(transaction['date']);
      bool isAfterStart =
          start == null || date.isAfter(start.subtract(Duration(days: 1)));
      bool isBeforeEnd =
          end == null || date.isBefore(end.add(Duration(days: 1)));
      bool isCategoryMatch = category == null ||
          category.isEmpty ||
          transaction['category'] == category;
      return isAfterStart && isBeforeEnd && isCategoryMatch;
    }).toList();

    for (var transaction in filteredData) {
      if (transaction['type'] == 'income') {
        income += transaction['amount'];
      } else {
        expense += transaction['amount'];
      }
    }

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      transactions = filteredData;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        _filterTransactions(startDate, endDate, selectedCategory);
      });
    }
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      selectedCategory = category;
      _filterTransactions(startDate, endDate, selectedCategory);
    });
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );
    if (result == true) {
      _fetchTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalBalance = totalIncome - totalExpense;
    List<String> allCategories =
        ['All'] + _incomeCategories + _expenseCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Tracker'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text('Income',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                            SizedBox(height: 5),
                            Text('${totalIncome.toStringAsFixed(2)}€',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.blue)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Expense',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                            SizedBox(height: 5),
                            Text('${totalExpense.toStringAsFixed(2)}€',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.blue)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Balance',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                            SizedBox(height: 5),
                            Text('${totalBalance.toStringAsFixed(2)}€',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.blue)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  hint: Text('Filter by Category'),
                  value: selectedCategory,
                  onChanged: _onCategoryChanged,
                  items: allCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category == 'All' ? null : category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.filter_list),
                  label: Text('Filter by Date'),
                  onPressed: () => _selectDateRange(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Dismissible(
                  key: Key(transaction['id'].toString()),
                  direction: DismissDirection.horizontal,
                  onDismissed: (direction) async {
                    await _dbHelper.deleteTransaction(transaction['id']);
                    _fetchTransactions();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${transaction['name']} deleted')),
                    );
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
                    title: Text(transaction['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat.yMMMd()
                            .format(DateTime.parse(transaction['date']))),
                        Text(transaction['category'] ?? 'No category'),
                      ],
                    ),
                    trailing:
                        Text('${transaction['amount'].toStringAsFixed(2)}€'),
                    onTap: () => _showTransactionDetails(transaction),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionScreen()),
          );
          if (result == true) {
            _fetchTransactions();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
