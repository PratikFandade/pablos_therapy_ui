import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pablo Therapy',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Geist',
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Pablo Therapy'
          ),
        ),
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'images/home.svg',
                  width: 200,
                  height: 200,
                ),
                Padding(
                  padding: const EdgeInsets.all(31),
                  child: Builder(
                    builder: (context) => FilledButton(
                      child: const Text('Start my Therapy'),
                      onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Therapy()
                          ),
                        ),
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(const Color(0xFF1A1A1A)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImageSection extends StatelessWidget {
  const ImageSection({super.key, required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      image,
      width: 601,
      height: 241,
      fit: BoxFit.cover,
    );
  }
}

class Therapy extends StatelessWidget {
  const Therapy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Theraphy'),
      ),
      body: Container(
        color: Colors.white,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ye Sab Kuch Nai Hota h Bhai!'),
              Text('Padhle Chutiye! 😒'),
            ],
          ),
        ),
      ),
    );
  }
}
