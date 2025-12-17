import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyrol/constants/app_constants.dart';
import 'package:moneyrol/constants/hive_constants.dart';
import 'package:moneyrol/dashboard/controller/dashboard_controller.dart';
import 'package:moneyrol/dashboard/model/company_model.dart';
import 'package:moneyrol/dashboard/model/company_transation_model.dart';
import 'package:moneyrol/dashboard/model/currency_model.dart';
import 'package:moneyrol/dashboard/model/transation_model.dart';
import 'package:moneyrol/dashboard/view/dashboard_screen.dart';
import 'package:moneyrol/splash/view/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(CompanyAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(CompanyTransactionAdapter());
  Hive.registerAdapter(CurrencyAdapter());

  // Open boxes
  await Hive.openBox<Company>(HiveConstants.companyBox);
  await Hive.openBox<Transaction>(HiveConstants.transactionBox);
  await Hive.openBox<CompanyTransaction>(HiveConstants.companyTransactionBox);
  await Hive.openBox(HiveConstants.settingsBox);
  await Hive.openBox<Currency>(HiveConstants.currencyBox);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HR Expense Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
      ),
      home: SplashScreen(),
    );
  }
}
