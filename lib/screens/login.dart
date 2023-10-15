import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/screens/orders.dart';
import 'package:test_app/screens/stock.dart';
import 'package:test_app/logged_in_layout.dart'; // Import the LoggedInLayout class
import 'register.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _username = '';
  String _password = '';

  Future<void> _handleSubmitted() async {
    final form = _formKey.currentState;
    if (form?.validate() == true) {
      form!.save();

      ApiResponse apiResponse = await getUserDetails(_username, _password);

      if (apiResponse.success) {
        // Store the JWT token in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('jwtToken', apiResponse.token);
        prefs.setString('username', _username); // Save the username here

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavBar()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid username or password")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Form(
              autovalidateMode: AutovalidateMode.always,
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/egidLogo.png', // Replace with actual logo path
                    height: 200,
                  ),
                  const SizedBox(height: 20.0),
                  TextFormField(
                    key: Key("_username"),
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (String? value) {
                      _username = value ?? '';
                    },
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10.0),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    onSaved: (String? value) {
                      _password = value ?? '';
                    },
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: _handleSubmitted,
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFF0AB7CD),
                    ),
                    child: Text('Sign in'),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Not Registered? ",
                        style: TextStyle(color: Colors.black),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterPage()), // Replace with the actual RegisterPage class
                          );
                        },
                        child: Text(
                          "Create an Account",
                          style: TextStyle(color: Color(0xFF0AB7CD)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ApiResponse {
  bool success;
  String errorMessage;
  String token;

  ApiResponse({this.success = false, this.errorMessage = "", this.token = ""});
}

Future<ApiResponse> getUserDetails(String email, String password) async {
  try {
    var url = Uri.parse('http://10.0.2.2:5262/api/User/login');

    try {
      var response = await http.post(url, body: jsonEncode({'userName': email, 'password': password}), headers: {
        "Accept": "application/json",
        "content-type": "application/json"
      });
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        // Successful login
        return ApiResponse(success: true, token: responseBody['token']);
      } else if (response.statusCode == 400) {
        return ApiResponse(success: false, errorMessage: "Invalid username or password");
      } else if (response.statusCode == 500) {
        return ApiResponse(success: false, errorMessage: "Internal server error");
      } else if (response.statusCode == 401) {
        return ApiResponse(success: false, errorMessage: "Unauthorized");
      } else if (response.statusCode == 404) {
        return ApiResponse(success: false, errorMessage: "Not found");
      } else {
        return ApiResponse(success: false, errorMessage: "Failed to login with status code ${response.statusCode}");
      }
    } catch (e) {
      print('Error during HTTP request: $e');
      return ApiResponse(success: false, errorMessage: "Failed to process HTTP request");
    }
  } on SocketException {
    return ApiResponse(success: false, errorMessage: "No internet connection");
  } catch (e) {
    print("Catching error: $e");
    return ApiResponse(success: false, errorMessage: "Failed to login");
  }
}

class SuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Success')),
      body: Center(
        child: Text('Logged in successfully!'),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Failure')),
      body: Center(
        child: Text('Failed to login!'),
      ),
    );
  }
}
