import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFormScreen extends StatefulWidget {
  @override
  _SupabaseFormScreenState createState() => _SupabaseFormScreenState();
}

class _SupabaseFormScreenState extends State<SupabaseFormScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Submits user data to Supabase
  Future<void> _submitForm() async {
    String name = _nameController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Insert data into Supabase
    await supabase.from('users').insert({
      'name': name,
      'password': password,
    });

    _nameController.clear();
    _passwordController.clear();
  }

  /// Function to update user name
  Future<void> _update(String id, String updatedName) async {
    await supabase.from('users').update({'name': updatedName}).eq('id', id);
  }

  /// Function to delete user
  Future<void> _delete(String id) async {
    await supabase.from('users').delete().eq('id', id);
  }

  /// Show Update Dialog
  void _showUpdateDialog(String id, String currentName) {
    TextEditingController updatedNameController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Name"),
          content: TextField(
            controller: updatedNameController,
            decoration: InputDecoration(labelText: "New Name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _update(id, updatedNameController.text);
                setState(() {
                  _buildUserList(); // Refresh the user list after updating
                });
                Navigator.pop(context); // Close dialog after updating
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  /// Builds a continuously updating user list
  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('users').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text("No users found.");
        }

        final users = snapshot.data!;
        return Column(
          children: users.map((user) {
            return Padding(
              padding: const EdgeInsets.all(2.0),
              child: Card(
                color: Colors.blue,
                child: ListTile(
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          _showUpdateDialog(
                              user['id'].toString(), user['name']);
                        },
                        icon: Icon(Icons.edit),
                      ),
                      IconButton(
                        onPressed: () {
                          _delete(user['id'].toString());
                          setState(() {
                            _buildUserList();
                          });
                        },
                        icon: Icon(Icons.delete),
                      ), // Refresh the user list after deleting
                    ],
                  ),
                  title: Text("Name: ${user['name']}"),
                  subtitle: Text("Password: ${user['password']}"),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Supabase Form")),
      body: Center(
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Submit'),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Live Data from Supabase:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildUserList(), // ✅ Real-time data from Supabase
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
