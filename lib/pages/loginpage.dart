import 'dart:convert';

import 'package:cleanroom/api/urlmanager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  final String? username;
  final int? privilegeLevel;

  final void Function(String username, int privilegeLevel)
      setUsernameAndPrivLevel;

  final void Function(String auth_token) setAuthToken;

  final void Function() getAuthToken;

  final void Function() clearLoggedInState;

  LoginPage({
    required this.setUsernameAndPrivLevel,
    required this.setAuthToken,
    required this.getAuthToken,
    required this.clearLoggedInState,
    this.username,
    this.privilegeLevel,
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  var _username_state;
  var _privilegeLevel_state;
  var _loginFailed = false;

  void updateLoginFailed(bool didFail) {
    setState(() {
      _loginFailed = didFail;
    });
  }

  @override
  Widget build(BuildContext context) {
    _username_state = widget.username;
    _privilegeLevel_state = widget.privilegeLevel;

    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color.fromARGB(255, 23, 8, 78),
        body: Center(
          child: _username_state != null && _privilegeLevel_state != null
              ? signedInScreen(context)
              : signInScreen(context),
        ),
      ),
    );
  }

  Widget signedInScreen(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Wrap(
        direction: Axis.vertical,
        children: [
          Text(
            'Username: ${widget.username}',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'Privilege Level: ${widget.privilegeLevel}',
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
          SizedBox(height: 8.0),
          ElevatedButton(
            onPressed: () {
              logout(widget.getAuthToken, widget.clearLoggedInState);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColorLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              'Log out',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget signInScreen(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            'images/logo.png',
            scale: 2,
          ),
          SizedBox(
            width: 400,
            child: TextField(
              controller: _usernameController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: 400,
            child: TextField(
              controller: _passwordController,
              style: TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          if (_loginFailed) // Show "Login failed" text conditionally
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Invalid Credentials',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              String username = _usernameController.text;
              String password = _passwordController.text;
              attemptLogin(username, password, widget.setUsernameAndPrivLevel,
                  widget.setAuthToken);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColorLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: Text(
              'Submit',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> logout(
      Function() getAuthToken, Function() clearLoggedInState) async {
    final url = Uri.parse('${UrlManager.baseUrl}/logout');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    final body = jsonEncode({'auth_token': getAuthToken()});

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        clearLoggedInState();
      } else {
        print('Logout Unsuccessful');
      }
    } catch (error) {
      print('Failed to connect to the server: $error');
    }
  }

  Future<void> attemptLogin(
      String username,
      String password,
      Function(String, int) setUsernameAndPrivLevel,
      Function(String) setAuthToken) async {
    final url = Uri.parse('${UrlManager.baseUrl}/login');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };

    final body = jsonEncode({'username': username, 'password': password});

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        print('Login Successful');
        Map<String, dynamic> decodedBody = json.decode(response.body);
        print("token: ${decodedBody['auth_token']}");
        setUsernameAndPrivLevel(
            username, decodedBody['privilege_level'] as int);
        setAuthToken(decodedBody['auth_token']);
        updateLoginFailed(false);
      } else {
        updateLoginFailed(true);
        print('Login Unsuccessful');
      }
    } catch (error) {
      print('Failed to connect to the server: $error');
    }
  }
}
