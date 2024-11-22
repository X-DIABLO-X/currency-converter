import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16.0),
        ),
      ),
      home: const RootPage(),
    );
  }
}

const List<Map<String, String>> countries = [
  {"name": "USD", "flag": "assets/us_flag.png"},
  {"name": "EUR", "flag": "assets/eur_flag.png"},
  {"name": "JPY", "flag": "assets/jpy_flag.png"},
  {"name": "GBP", "flag": "assets/gbp_flag.png"},
  {"name": "CAD", "flag": "assets/cad_flag.png"},
  {"name": "CHF", "flag": "assets/chf_flag.png"},
  {"name": "INR", "flag": "assets/inr_flag.png"},
  {"name": "BRL", "flag": "assets/blr_flag.png"},
];

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  late TextEditingController _textEditingController;

  String selectedCurrency1 = countries.first['name']!;
  String selectedCurrency2 = countries[1]['name']!;
  double inputAmount = 0.0;
  double convertedAmount = 0.0;
  bool isLoading = false;

  final List<Map<String, String>> sortedCountries = List<Map<String, String>>.from(countries)
    ..sort((a, b) => a['name']!.compareTo(b['name']!));

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void convertCurrency() async {
    const apiUrl = 'https://api.exchangerate-api.com/v4/latest/'; // Base API URL

    if (selectedCurrency1 == selectedCurrency2) {
      setState(() {
        convertedAmount = inputAmount;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$apiUrl$selectedCurrency1'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = data['rates'][selectedCurrency2];

        setState(() {
          convertedAmount = inputAmount * rate;
        });
      } else {
        throw Exception('Failed to fetch conversion rate');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        convertedAmount = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch conversion rates. Try again later.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void resetInputs() {
    setState(() {
      _textEditingController.clear();
      selectedCurrency1 = countries.first['name']!;
      selectedCurrency2 = countries[1]['name']!;
      inputAmount = 0.0;
      convertedAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Select Currencies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CurrencyDropdown(
                      label: 'From',
                      selectedCurrency: selectedCurrency1,
                      countries: sortedCountries,
                      onChanged: (value) {
                        setState(() {
                          selectedCurrency1 = value ?? selectedCurrency1;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    CurrencyDropdown(
                      label: 'To',
                      selectedCurrency: selectedCurrency2,
                      countries: sortedCountries,
                      onChanged: (value) {
                        setState(() {
                          selectedCurrency2 = value ?? selectedCurrency2;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Enter Amount',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _textEditingController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter the amount',
                        labelText: 'Amount',
                      ),
                      onChanged: (value) {
                        setState(() {
                          inputAmount = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: inputAmount > 0 ? convertCurrency : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: const Text(
                              'Convert',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                    const SizedBox(height: 20),
                    Text(
                      'Converted Amount: ${convertedAmount.toStringAsFixed(2)} $selectedCurrency2',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            IconButton(
              onPressed: resetInputs,
              icon: const Icon(Icons.refresh, color: Colors.teal),
              tooltip: 'Reset',
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyDropdown extends StatelessWidget {
  final String label;
  final String selectedCurrency;
  final List<Map<String, String>> countries;
  final ValueChanged<String?> onChanged;

  const CurrencyDropdown({
    super.key,
    required this.label,
    required this.selectedCurrency,
    required this.countries,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: selectedCurrency,
          onChanged: onChanged,
          isExpanded: true,
          items: countries.map<DropdownMenuItem<String>>((country) {
            return DropdownMenuItem<String>(
              value: country['name'],
              child: Row(
                children: [
                  Image.asset(
                    country['flag']!,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(country['name']!),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
