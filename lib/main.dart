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
    final stored = box.get('todo');
    todoList = stored != null ? List<Map<String, dynamic>>.from(stored) : [];
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

  Map<String, List<Map<String, dynamic>>> groupTasksByDateRange() {
    final now = DateTime.now();
    List<Map<String, dynamic>> today = [];
    List<Map<String, dynamic>> last7 = [];
    List<Map<String, dynamic>> last30 = [];

    for (var task in todoList) {
      if (task['createdAt'] == null) continue;
      DateTime created;
      try {
        created = DateTime.parse(task['createdAt']);
      } catch (_) {
        continue;
      }

      if (isSameDay(created, now)) {
        today.add(task);
      } else if (created.isAfter(now.subtract(const Duration(days: 7)))) {
        last7.add(task);
      } else if (created.isAfter(now.subtract(const Duration(days: 30)))) {
        last30.add(task);
      }
    }

    return {
      'Today': today,
      'Previous 7 Days': last7,
      'Previous 30 Days': last30,
    };
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  Widget buildTaskTile(Map<String, dynamic> task) {
    final createdTime = formatDateTime(task['createdAt']);
    final realIndex = todoList.indexWhere((t) =>
    t['task'] == task['task'] && t['createdAt'] == task['createdAt']);

    return GestureDetector(
      onTap: () => _toggleStatus(realIndex),
      onLongPress: () => _showDeleteDialog(realIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: CupertinoColors.systemGrey5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      : CupertinoColors.systemGrey2,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              createdTime,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedTasks = groupTasksByDateRange();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('All iCloud', style: TextStyle(color: CupertinoColors.black)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                  for (final section in ['Today', 'Previous 7 Days', 'Previous 30 Days'])
                    if (groupedTasks[section]!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 0, 4),
                        child: Text(section,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.black)),
                      ),
                      ...groupedTasks[section]!.map(buildTaskTile).toList(),
                    ],
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
