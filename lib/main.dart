import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('database');
  runApp(const CupertinoApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _addTaskController = TextEditingController();
  final Box box = Hive.box('database');
  List<Map<String, dynamic>> todoList = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    final stored = box.get('todo');
    if (stored != null) {
      todoList = (stored as List).map<Map<String, dynamic>>((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    }
  }

  void _saveToHive() => box.put('todo', todoList);

  void _addTask(String task) {
    setState(() {
      todoList.add({
        'task': task,
        'status': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      _saveToHive();
    });
  }

  void _toggleStatus(int index) {
    setState(() {
      todoList[index]['status'] = !todoList[index]['status'];
      _saveToHive();
    });
  }

  void _deleteTask(int index) {
    setState(() {
      todoList.removeAt(index);
      _saveToHive();
    });
  }

  void _showAddTaskDialog() {
    _addTaskController.clear();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Add Task'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: _addTaskController,
            placeholder: 'Type your task...',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Add'),
            onPressed: () {
              final text = _addTaskController.text.trim();
              if (text.isNotEmpty) {
                _addTask(text);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${todoList[index]['task']}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              _deleteTask(index);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> getTodayTasks() {
    final now = DateTime.now();
    return todoList.where((task) {
      final created = DateTime.tryParse(task['createdAt'] ?? '') ?? DateTime(2000);
      return created.year == now.year &&
          created.month == now.month &&
          created.day == now.day;
    }).toList();
  }

  List<Map<String, dynamic>> getPrevious7DaysTasks() {
    final now = DateTime.now();
    return todoList.where((task) {
      final created = DateTime.tryParse(task['createdAt'] ?? '') ?? DateTime(2000);
      return created.isBefore(now) &&
          created.isAfter(now.subtract(const Duration(days: 7))) &&
          !(created.year == now.year && created.month == now.month && created.day == now.day);
    }).toList();
  }

  List<Map<String, dynamic>> getPrevious30DaysTasks() {
    final now = DateTime.now();
    return todoList.where((task) {
      final created = DateTime.tryParse(task['createdAt'] ?? '') ?? DateTime(2000);
      return created.isBefore(now.subtract(const Duration(days: 7))) &&
          created.isAfter(now.subtract(const Duration(days: 30)));
    }).toList();
  }

  String formatDateTime(String iso) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  Widget buildTaskSection(String title, List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 0, 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ...tasks.map((task) {
          final index = todoList.indexWhere((t) =>
          t['task'] == task['task'] && t['createdAt'] == task['createdAt']);
          return GestureDetector(
            onTap: () => _toggleStatus(index),
            onLongPress: () => _showDeleteDialog(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.systemGrey5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task['task'],
                          style: TextStyle(
                            fontSize: 18,
                            decoration: task['status']
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: task['status']
                                ? CupertinoColors.inactiveGray
                                : CupertinoColors.label,
                          ),
                        ),
                      ),
                      Icon(
                        task['status']
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.circle,
                        color: task['status']
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.systemGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDateTime(task['createdAt']),
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = getTodayTasks();
    final last7 = getPrevious7DaysTasks();
    final last30 = getPrevious30DaysTasks();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('All iCloud', style: TextStyle(color: CupertinoColors.black)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Center(
                child: Text(
                  'To-Do List',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  buildTaskSection("Today", todayTasks),
                  buildTaskSection("Previous 7 Days", last7),
                  buildTaskSection("Previous 30 Days", last30),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: CupertinoColors.systemGroupedBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('       '),
                  Text('${todoList.length} Task${todoList.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 16)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showAddTaskDialog,
                    child: const Icon(CupertinoIcons.square_pencil,
                        color: CupertinoColors.systemBlue),
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