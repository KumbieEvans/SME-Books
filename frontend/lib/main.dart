import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/dashboard/ui/dashboard_screen.dart';

// TODO: Replace with local Supabase URL and Anon Key when running
const supabaseUrl = 'https://nrtoqpoycbcniniemwhu.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5ydG9xcG95Y2JjbmluaWVtd2h1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1MTY2NDksImV4cCI6MjA5OTA5MjY0OX0.wBWLxWAtN-5BPVsXdqoX5rD6pDJMJiNiKz0Mg--AvUM';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const SmeBooksApp());
}

class SmeBooksApp extends StatelessWidget {
  const SmeBooksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(supabaseClient: Supabase.instance.client),
      child: MaterialApp(
        title: 'SME Books',
        theme: AppTheme.lightTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}

