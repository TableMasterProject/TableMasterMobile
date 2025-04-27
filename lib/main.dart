import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _user;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() {
        _user = account;
      });
    });
    _googleSignIn.signInSilently();
  }

  // Fonction pour se connecter avec Google
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      setState(() {
        _user = account;
      });
    } catch (error) {
      print("Error signing in with Google: $error");
    }
  }

  // Fonction pour se déconnecter
  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _user == null
                ? const Text('Please sign in to continue:')
                : Column(
              children: [
                Text('Signed in as: ${_user?.displayName}'),
                Text('Email: ${_user?.email}'),
                Text('ID: ${_user?.id}')
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
