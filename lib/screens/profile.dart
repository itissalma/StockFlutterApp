import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/screens/login.dart';


class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = ''; // Change userEmail to userName
  String email = '';

  @override
  void initState() {
    super.initState();
    getUserName(); // Change getUserEmail to getUserName
  }

  Future<void> getUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('username') ?? '';
    print("email is $email");

    final apiUrl = 'http://10.0.2.2:5262/api/User/email/$email'; // API endpoint
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final dynamic userData = json.decode(response.body);
      final String username = userData['userName'] ?? ''; // Extract username from response

      setState(() {
        userName = username;
      });
    } else {
      print("Failed to load user data");
      throw Exception('Failed to load user data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFF221E1F),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 100,
              color: Color(0xFF0AB7CD),
            ),
            SizedBox(height: 20),
            Text(
              userName, // Change userEmail to userName
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              email,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF0AB7CD),
              ),
              onPressed: () async {
                await _performLogout();
              },
              child: Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performLogout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Remove the JWT token from SharedPreferences
    prefs.remove('jwtToken');

    // Navigate to the login page and replace the current stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Replace LoginPage with your actual login page
          (Route<dynamic> route) => false,
    );
  }

}

