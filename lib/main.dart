import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pablotheraphy/pablo_theraphy.dart';

void main() async {
  await dotenv.load();
  runApp(const PablosTheraphyApp());
}
