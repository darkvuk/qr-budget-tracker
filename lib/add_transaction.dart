import 'package:flutter/material.dart';
import 'package:budget_tracker/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction;

  AddTransactionScreen({this.transaction});

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  String _type = 'expense';
  DateTime _date = DateTime.now();
  String _name = '';
  double _amount = 0.0;
  String _category = '';
  int? _transactionId;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

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
    if (widget.transaction != null) {
      _type = widget.transaction!['type'];
      _date = DateTime.parse(widget.transaction!['date']);
      _name = widget.transaction!['name'];
      _amount = widget.transaction!['amount'];
      _category = widget.transaction!['category'] ?? '';
      _transactionId = widget.transaction!['id'];

      _dateController.text = DateFormat('yyyy-MM-dd').format(_date);
      _amountController.text = _amount.toString();
    } else {
      _dateController.text = DateFormat('yyyy-MM-dd').format(_date);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    final regex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!regex.hasMatch(value)) {
      return 'Enter a valid amount (e.g., 5, 856, 56.19, 179.5)';
    }
    return null;
  }

  void _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final transaction = {
        'type': _type,
        'date': _date.toIso8601String(),
        'name': _name,
        'amount': _amount,
        'category': _category,
      };
      if (_transactionId == null) {
        await _dbHelper.insertTransaction(transaction);
      } else {
        transaction['id'] = _transactionId as Object;
        await _dbHelper.updateTransaction(transaction);
      }
      Navigator.pop(context, true);
    }
  }

  void _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRViewExample()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _type = 'expense';
        _date = result['dateQR'];
        _amount = result['priceQR'];
        _dateController.text = DateFormat('yyyy-MM-dd').format(_date);
        _amountController.text = _amount.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Expense'),
                      leading: Radio<String>(
                        value: 'expense',
                        groupValue: _type,
                        onChanged: (value) {
                          setState(() {
                            _type = value!;
                            _category = ''; // Reset category when type changes
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Income'),
                      leading: Radio<String>(
                        value: 'income',
                        groupValue: _type,
                        onChanged: (value) {
                          setState(() {
                            _type = value!;
                            _category = ''; // Reset category when type changes
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Date'),
                controller: _dateController,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setState(() {
                      _date = picked;
                      _dateController.text =
                          DateFormat('yyyy-MM-dd').format(_date);
                    });
                  }
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                initialValue: _name,
                onSaved: (value) {
                  _name = value!;
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Amount (€)'),
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onSaved: (value) {
                  _amount = double.parse(value!);
                },
                validator: _validateAmount,
              ),
              SizedBox(height: 20),
              Text('Category', style: TextStyle(fontSize: 16)),
              Wrap(
                spacing: 8.0,
                children:
                    (_type == 'income' ? _incomeCategories : _expenseCategories)
                        .map((category) => ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (selected) {
                                setState(() {
                                  _category = selected ? category : '';
                                });
                              },
                            ))
                        .toList(),
              ),
              if (_category.isEmpty &&
                  _formKey.currentState !=
                      null) // Display error if category is not selected
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please select a category',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _category.isEmpty
                    ? null
                    : _submitTransaction, // Disable button if category is not selected
                child: Text(widget.transaction == null ? 'Submit' : 'Update'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _scanQRCode,
                child: Text('Scan QR Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 200,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  controller?.pauseCamera();
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isScanned) {
        if (scanData.code != null) {
          isScanned = true;
          String url = scanData.code!;
          if (url.startsWith('https://mapr.tax.gov.me')) {
            String priceParameter = url.split('&prc=')[1].replaceAll(',', '.');
            double priceQR = double.parse(priceParameter);

            String dateParameter = url.split('&crtd=')[1].split('T')[0];
            var dateParts = dateParameter.split('-');
            int year = int.parse(dateParts[0]);
            int month = int.parse(dateParts[1]);
            int day = int.parse(dateParts[2]);
            DateTime dateQR = DateTime(year, month, day);

            Navigator.pop(context, {'dateQR': dateQR, 'priceQR': priceQR});
          } else {
            setState(() {
              isScanned = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid QR Code')),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
