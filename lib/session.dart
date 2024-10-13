import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class Therapy extends StatelessWidget {
  final String name;
  const Therapy({super.key, required this.name});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Theraphy'),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 500,
                height: 500,
                child: RiveAnimation.asset('images/pablo.riv'),  // Correct path
              ),
              Text(
                'Ye Sab Kuch Nai Hota h $name!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Padhle Chutiye! 😒',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
