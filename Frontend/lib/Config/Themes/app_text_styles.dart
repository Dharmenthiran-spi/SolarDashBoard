import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle headline1(Color color) => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: color,
  );

  static TextStyle headline2(Color color) => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle title(Color color) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle bodyText(Color color) => GoogleFonts.inter(
    fontSize: 16,
    color: color,
  );

  static TextStyle bodyText2(Color color) => GoogleFonts.inter(
    fontSize: 14,
    color: color,
  );

  static TextStyle buttonText(Color color) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle defaultHeader1() => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle defaultBody1() => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle defaultBody2() => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle editableBody1() => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  );
}
