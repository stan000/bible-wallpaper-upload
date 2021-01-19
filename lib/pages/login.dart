import 'package:bible_wallpaper_upload/pages/upload.dart';
import 'package:bible_wallpaper_upload/services/authenticationService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isAuth = false;

  login() {
    print('Login clicked');
    Provider.of<AuthenticationService>(context, listen: false)
        .signinWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    return isAuth
        ? Upload()
        : Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  end: Alignment.topLeft,
                  begin: Alignment.bottomRight,
                  colors: [
                    Colors.indigo,
                    Colors.blueAccent,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: MaterialButton(
                color: Colors.white.withOpacity(0.85),
                textColor: Colors.blue[900],
                splashColor: Colors.blue[400],
                padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                onPressed: login,
                child: Text('LOGIN'),
              ),
            ),
          );
  }
}
