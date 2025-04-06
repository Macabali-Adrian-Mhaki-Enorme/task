import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('database');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _addTaskController = TextEditingController();
  final Box box = Hive.box('database');
  List<Map<String, dynamic>> todoList = [];
  bool selectionMode = false;
  Set<int> selectedIndices = {};

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
    if (selectionMode) {
      _toggleSelection(index);
    } else {
      setState(() {
        todoList[index]['status'] = !todoList[index]['status'];
        _saveToHive();
      });
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
    });
  }

  void _deleteTask(int index) {
    setState(() {
      todoList.removeAt(index);
      _saveToHive();
    });
  }

  void _deleteSelectedTasks() {
    setState(() {
      final sorted = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (var index in sorted) {
        todoList.removeAt(index);
      }
      selectedIndices.clear();
      selectionMode = false;
      _saveToHive();
    });
  }

  void _showDeleteSelectedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Selected Tasks'),
        content: Text(
          'Are you sure you want to delete ${selectedIndices.length} selected task${selectedIndices.length == 1 ? '' : 's'}?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedTasks();
            },
          ),
        ],
      ),
    );
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

  void _showDeveloperInfo() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Developer Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(height: 8),
              Text('App Name: To-Do List'),
              SizedBox(height: 8),
              Text('Developer:'),
              Text('                     Baligod, John Ivan'),
              Text('                     Culala, Kristel'),
              Text('                     Esguerra, Megan'),
              Text('                     Estacio, Luis Gabrielle'),
              Text('                     Macabali, Adrian Mhaki'),
              SizedBox(height: 8),
              Text('Version: 1.0.0'),
              SizedBox(height: 8),
              Text('Contact: ToDoList@gmail.com'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
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
          !(created.year == now.year &&
              created.month == now.month &&
              created.day == now.day);
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
            onLongPress: () {
              if (!selectionMode) {
                _showDeleteDialog(index);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.systemGrey4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0, top: 4),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        child: Icon(
                          selectedIndices.contains(index)
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.circle,
                          color: selectedIndices.contains(index)
                              ? CupertinoColors.systemBlue
                              : CupertinoColors.systemGrey,
                          size: 24,
                        ),
                        onPressed: () => _toggleSelection(index),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                        const SizedBox(height: 4),
                        Text(
                          formatDateTime(task['createdAt']),
                          style: const TextStyle(
                              fontSize: 12, color: CupertinoColors.systemGrey),
                        ),
                      ],
                    ),
                  ),
                  if (!selectionMode)
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
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showDeleteDialog(int index) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Task'),
        content:
        Text('Are you sure you want to delete "${todoList[index]['task']}"?'),
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

  @override
  Widget build(BuildContext context) {
    final todayTasks = getTodayTasks();
    final last7 = getPrevious7DaysTasks();
    final last30 = getPrevious30DaysTasks();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('All iCloud'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showDeveloperInfo,
          child: const Icon(CupertinoIcons.info),
        ),
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
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        selectionMode = !selectionMode;
                        selectedIndices.clear();
                      });
                    },
                    child: Icon(
                      selectionMode
                          ? CupertinoIcons.clear_circled
                          : CupertinoIcons.checkmark_circle,
                      color: selectionMode
                          ? CupertinoColors.destructiveRed
                          : CupertinoColors.activeBlue,
                    ),
                  ),
                  Text(
                    '${todoList.length} Task${todoList.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  selectionMode
                      ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: selectedIndices.isNotEmpty
                        ? _showDeleteSelectedDialog
                        : null,
                    child: Icon(
                      CupertinoIcons.delete,
                      color: selectedIndices.isNotEmpty
                          ? CupertinoColors.destructiveRed
                          : CupertinoColors.systemGrey,
                    ),
                  )
                      : CupertinoButton(
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
