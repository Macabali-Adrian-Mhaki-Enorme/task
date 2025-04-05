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
  Set<int> selectedIndexes = {};
  bool isSelectAll = false;

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
      selectedIndexes.remove(index);
      if (todoList.isEmpty) {
        selectedIndexes.clear();
        isSelectAll = false;
      } else {
        // Recalculate selection based on new indexes
        selectedIndexes = selectedIndexes
            .where((i) => i < todoList.length)
            .toSet();
        isSelectAll = selectedIndexes.length == todoList.length;
      }
      _saveToHive();
    });
  }

  void _deleteSelectedTasks() {
    setState(() {
      todoList = todoList
          .asMap()
          .entries
          .where((entry) => !selectedIndexes.contains(entry.key))
          .map((e) => e.value)
          .toList();
      selectedIndexes.clear();
      isSelectAll = false;
      _saveToHive();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (todoList.isEmpty) {
        selectedIndexes.clear();
        isSelectAll = false;
        return;
      }
      if (selectedIndexes.length == todoList.length) {
        selectedIndexes.clear();
        isSelectAll = false;
      } else {
        selectedIndexes =
        Set<int>.from(List.generate(todoList.length, (i) => i));
        isSelectAll = true;
      }
    });
  }


  void _showDeleteSelectedDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Are you sure you want to delete ${selectedIndexes.length} selected task(s)?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              _deleteSelectedTasks();
              Navigator.pop(context);
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
            crossAxisAlignment: CrossAxisAlignment.start, // Align left
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(height: 8),
              Text(
                'App Name: To-Do List',
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 8),
              Text(
                'Developer:',
                textAlign: TextAlign.left,
              ),
              Text(
                '                      Baligod, John Ivan',
                textAlign: TextAlign.left,
              ),
              Text(
                '                      Culala, Kristel',
                textAlign: TextAlign.left,
              ),
              Text(
                '                      Esguerra, Megan',
                textAlign: TextAlign.left,
              ),
              Text(
                '                      Estacio, Luis Gabrielle',
                textAlign: TextAlign.left,
              ),
              Text(
                '                      Macabali, Adrian Mhaki',
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 8),
              Text(
                'Version: 1.0.0',
                textAlign: TextAlign.left,
              ),
              SizedBox(height: 8),
              Text(
                'Contact: ToDoList@gmail.com',
                textAlign: TextAlign.left,
              ),
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



  String formatDateTime(String iso) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  Widget buildTaskList() {
    return Column(
      children: todoList.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        final isSelected = selectedIndexes.contains(index);
        return GestureDetector(
          onLongPress: selectedIndexes.isNotEmpty
              ? _showDeleteSelectedDialog
              : () => _toggleStatus(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CupertinoColors.systemGrey4),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedIndexes.remove(index);
                      } else {
                        selectedIndexes.add(index);
                      }
                      isSelectAll = selectedIndexes.length == todoList.length;
                    });
                  },
                  child: Icon(
                    isSelected
                        ? CupertinoIcons.check_mark_circled_solid
                        : CupertinoIcons.circle,
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  buildTaskList(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: CupertinoColors.systemGroupedBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _toggleSelectAll,
                    child: Icon(
                      (todoList.isNotEmpty && selectedIndexes.length == todoList.length)
                          ? CupertinoIcons.check_mark_circled_solid
                          : CupertinoIcons.circle,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  Text(
                    '${todoList.length} Task${todoList.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 16),
                  ),
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
