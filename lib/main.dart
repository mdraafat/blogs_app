import 'package:blogs_app/firebase/firebase_options.dart';
import 'package:blogs_app/pages/login_page.dart';
import 'package:blogs_app/services/auth_email_service.dart';
import 'package:blogs_app/services/auth_google_service.dart';
import 'package:blogs_app/services/blog_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/blog/blog_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => EmailSignInService()),
        RepositoryProvider(create: (_) => GoogleSignInService()),
        RepositoryProvider(create: (_) => BlogService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              emailService: context.read<EmailSignInService>(),
              googleService: context.read<GoogleSignInService>(),
            ),
          ),
          BlocProvider(
            create: (context) => BlogBloc(
              blogService: context.read<BlogService>(),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Personal Blogs App',
          theme: ThemeData(useMaterial3: true),
          home: const LoginPage(),
        ),
      ),
    );
  }
}
