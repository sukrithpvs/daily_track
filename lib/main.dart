import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DailyTrackApp());
}

class DailyTrackApp extends StatelessWidget {
  const DailyTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: MaterialApp(
        title: 'DailyTrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          scaffoldBackgroundColor: const Color(
            0xFFF5F7FA,
          ), // Soft off-white blue
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFFFFF),
            foregroundColor: Color(0xFF2D3748), // Slate gray
            elevation: 0.5,
            centerTitle: true,
            shadowColor: Color(0x10000000),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFF2D3748)),
            bodyMedium: TextStyle(color: Color(0xFF4A5568)),
            titleLarge: TextStyle(
              color: Color(0xFF1A202C),
              fontWeight: FontWeight.bold,
            ),
            titleMedium: TextStyle(
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.w600,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 1,
            shadowColor: const Color(0x08000000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5568), // Soft slate
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0x20000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4A5568), width: 2),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
