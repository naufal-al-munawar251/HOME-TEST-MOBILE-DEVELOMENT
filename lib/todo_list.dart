import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do App',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();

  void _login(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', usernameController.text); // Simulate login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ToDoListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class ToDoListScreen extends StatefulWidget {
  @override
  _ToDoListScreenState createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  List<Map<String, dynamic>> tasks = [];
  final TextEditingController taskController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Load tasks when initializing
    searchController.addListener(_filterTasks); // Listen to search changes
  }

  Future<void> _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      List<dynamic> jsonTasks = json.decode(tasksString);
      tasks = jsonTasks.map((task) => Map<String, dynamic>.from(task)).toList();
    }
    filteredTasks = tasks; // Initialize with loaded tasks
    setState(() {});
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tasksString = json.encode(tasks);
    prefs.setString('tasks', tasksString);
  }

  void _filterTasks() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredTasks = tasks.where((task) {
        return task['description'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _addTask() {
    if (taskController.text.isNotEmpty) {
      setState(() {
        tasks.add({
          'description': taskController.text,
          'isCompleted': false,
          'dueDate': DateTime.now().add(Duration(days: 1)), // Example due date
        });
        taskController.clear();
        filteredTasks = tasks; // Update filtered tasks
        _saveTasks(); // Save tasks after adding
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose(); // Dispose of the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        backgroundColor: Colors.pink,
        titleTextStyle: TextStyle(color: Colors.white), // Title text color
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink, width: 2.0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // Task List
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(child: Text('No tasks found!', style: TextStyle(fontSize: 18)))
                : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Checkbox(
                      value: filteredTasks[index]['isCompleted'],
                      activeColor: Colors.pink,
                      onChanged: (value) {
                        setState(() {
                          filteredTasks[index]['isCompleted'] = value!;
                          _saveTasks(); // Save tasks after completion state change
                        });
                      },
                    ),
                    title: Text(
                      filteredTasks[index]['description'],
                      style: TextStyle(
                        decoration: filteredTasks[index]['isCompleted']
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text('Due: ${filteredTasks[index]['dueDate'].toString().split(' ')[0]}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Add Task'),
                content: TextField(
                  controller: taskController,
                  decoration: InputDecoration(hintText: 'Enter task description'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _addTask();
                      Navigator.of(context).pop();
                    },
                    child: Text('Add'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add, color: Colors.white), // Icon color
        backgroundColor: Colors.pink, // FAB background color
      ),
    );
  }
}
