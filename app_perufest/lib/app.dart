import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/eventos_viewmodel.dart';
import 'viewmodels/actividades_viewmodel.dart';
import 'viewmodels/recuperacion_viewmodel.dart';
import 'viewmodels/stands_viewmodel.dart';
import 'viewmodels/comentarios_viewmodel.dart';
import 'views/login_view.dart';
import 'viewmodels/agenda_viewmodel.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => EventosViewModel()),
        ChangeNotifierProvider(create: (_) => ActividadesViewModel()),
        ChangeNotifierProvider(create: (_) => RecuperacionViewModel()),
        ChangeNotifierProvider(create: (_) => AgendaViewModel()),
        ChangeNotifierProvider(create: (_) => StandsViewModel()),
        ChangeNotifierProvider(create: (_) => ComentariosViewModel()),
      ],
      child: MaterialApp(
        title: 'PeruFest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        home: const LoginView(),
        routes: {'/login': (context) => const LoginView()},
      ),
    );
  }
}
