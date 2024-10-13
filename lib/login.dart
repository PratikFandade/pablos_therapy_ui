import 'package:flutter/material.dart';
import 'session.dart';

class NameDialog extends StatefulWidget {
  const NameDialog({super.key});

  @override
  _NameDialogState createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  final TextEditingController _nameController = TextEditingController(); // Controller to capture the text

  @override
  void dispose() {
    _nameController.dispose(); // Dispose the controller when not needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: const ButtonStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Color(0xFF1A1A1A)),
      ),
      child: const Text('Start my Therapy'),
      onPressed: () => showDialog<String>(
        context: context,
        builder: (BuildContext context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 40),
                Text(
                  'Start my Therapy',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Your Name',
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                FilledButton(
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(Color(0xFF1A1A1A)),
                  ),
                  child: const Text('Start my Therapy'),
                  onPressed: () {
                    String enteredName = _nameController.text;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Therapy(name: enteredName),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
