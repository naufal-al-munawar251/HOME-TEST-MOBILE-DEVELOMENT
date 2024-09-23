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
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ToDoListScreen(),
    );
  }
}

class ToDoListScreen extends StatefulWidget {
  @override
  _ToDoListScreenState createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  final TextEditingController taskController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
    searchController.addListener(_filterTasks);
  }

  Future<void> _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      List<dynamic> jsonTasks = json.decode(tasksString);
      tasks = jsonTasks.map((task) => Map<String, dynamic>.from(task)).toList();
      _filterTasks(); // Update filtered tasks initially
    }
    setState(() {});
  }

  Future<void> _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tasksString = json.encode(tasks);
    prefs.setString('tasks', tasksString);
  }

  void _addTask(String description) {
    if (description.isNotEmpty) {
      setState(() {
        tasks.add({
          'description': description,
          'isCompleted': false,
          'dueDate': DateTime.now().add(Duration(days: 1)), // Example due date
        });
        _saveTasks();
        _filterTasks(); // Update the filtered tasks list
      });
      taskController.clear();
    }
  }

  void _filterTasks() {
    setState(() {
      filteredTasks = tasks.where((task) {
        return task['description'].toLowerCase().contains(searchController.text.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search tasks',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Checkbox(
                      value: filteredTasks[index]['isCompleted'],
                      onChanged: (bool? value) {
                        setState(() {
                          filteredTasks[index]['isCompleted'] = value!;
                          _saveTasks();
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
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add, color: Colors.white,),
        backgroundColor: Colors.pink,
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
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
                _addTask(taskController.text);
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
  }
}
