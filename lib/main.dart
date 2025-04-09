import 'package:apk_gudang_supabase/pages/home_page.dart';
import 'package:apk_gudang_supabase/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dklmdeipbsaljavjxyzl.supabase.co',
    anonKey: 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrbG1kZWlwYnNhbGphdmp4eXpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEwNTcwNTMsImV4cCI6MjA1NjYzMzA1M30.BZtuulQRWkGixR9vc29g2D3UH3i0pj2xXmjbQ0wLP9U',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(    
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
