import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_app/screens/stock.dart';
import 'dart:convert';
import 'login.dart'; // Import the LoginPage class for navigation

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _username = '';
  String _natID = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = ''; // New variable to store the confirm password
  bool samePassword = true;

  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print("youou");
      if (!samePassword) {
        print("in hereee");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Passwords do not match.")),
        );
        return;
      }

      // Register user logic here
      final url = Uri.parse('http://10.0.2.2:5262/api/User/register'); // Replace with your API endpoint
      final response = await http.post(
        url,
        headers: {"content-type": "application/json"},
        body: jsonEncode({
          'userName': _username,
          'natId': _natID,
          'email': _email,
          'password': _password,
        }),
      );
      print("tfff");

      if (response.statusCode == 200) {
        // Registration successful, navigate to LoginPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage
        );
      } else if (response.statusCode == 400) {
        //print the statuscode
        print("the status code is ${response.statusCode}");
        // User already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User already exists!")),
        );
      } else {
        // Registration failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to register.")),
        );
      }
    }
  }

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Image.asset(
                'assets/egidLogo.png', // Replace with actual logo path
                height: 200,
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _username = value ?? '';
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'National ID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'National ID is required.';
                  }
                  if (value.length != 14) {
                    return 'National ID must be 14 characters long.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _natID = value ?? '';
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required.';
                  }
                  if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(value)) {
                    return 'Invalid email format.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value ?? '';
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _password = value;
                    // Update samePassword flag
                    samePassword = _password == _confirmPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long.';
                  }
                  return null;
                },
                onSaved: (String? value) {
                  _password = value ?? ''; // Convert nullable value to non-nullable using the null-aware assignment operator
                  print("password is $_password");
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                controller: _confirmPasswordController,
                onChanged: (value) {
                  setState(() {
                    _confirmPassword = value;
                    // Update samePassword flag
                    samePassword = _password == _confirmPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm Password is required.';
                  }
                  if (!samePassword) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _confirmPassword = value ?? '';
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _registerUser,
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF0AB7CD),
                ),
                child: Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuccessPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Success')),
      body: Center(
        child: Text('Account created successfully!'),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: RegisterPage(),
  ));
}
