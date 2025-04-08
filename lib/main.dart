import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'folders_screen.dart';

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
        brightness: Brightness.light, // 🔆 Force light mode
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
      ),
      home: const FoldersScreen(totalTaskCount: 0),
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
  final TextEditingController _searchController = TextEditingController();
  final Box box = Hive.box('database');
  List<Map<String, dynamic>> todoList = [];

  final Color iconColor = const Color(0xFFE4AF0A);

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
                '                     Baligod, John Ivan',
                textAlign: TextAlign.left,
              ),
              Text(
                '                     Culala, Kristel',
                textAlign: TextAlign.left,
              ),
              Text(
                '                     Esguerra, Megan',
                textAlign: TextAlign.left,
              ),
              Text(
                '                     Estacio, Luis Gabrielle',
                textAlign: TextAlign.left,
              ),
              Text(
                '                     Macabali, Adrian Mhaki',
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
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, itemIndex) {
              final task = tasks[itemIndex];
              final index = todoList.indexWhere((t) =>
              t['task'] == task['task'] &&
                  t['createdAt'] == task['createdAt']);

              return GestureDetector(
                onTap: () => _toggleStatus(index),
                onLongPress: () => _showDeleteDialog(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            task['status']
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                            color: task['status'] ? iconColor : CupertinoColors.systemGrey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              task['task'],
                              style: TextStyle(
                                fontSize: 16,
                                decoration: task['status']
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: task['status']
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          formatDateTime(task['createdAt']),
                          style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = getTodayTasks();
    final last7 = getPrevious7DaysTasks();
    final last30 = getPrevious30DaysTasks();

    final searchBarBgColor = Color(0xFFE3E3E8);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF2F2F7),
        border: Border.all(color: Colors.transparent),
        padding: const EdgeInsetsDirectional.only(start: 4.0, end: 8.0),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // Updated to pass task count to FoldersScreen
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => FoldersScreen(totalTaskCount: todoList.length),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.back,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 4),
              Text(
                'Folders',
                style: TextStyle(
                  color: iconColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        middle: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showDeveloperInfo,
          child: Icon(
            CupertinoIcons.ellipsis_circle,
            color: iconColor,
            size: 24,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'All iCloud',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: searchBarBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.search,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CupertinoTextField(
                        controller: _searchController,
                        placeholder: 'Search',
                        placeholderStyle: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.transparent),
                        ),
                        padding: EdgeInsets.zero,
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.mic_fill,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
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
              color: const Color(0xFFF2F2F7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('       '),
                  Text('${todoList.length} Task${todoList.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 16)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showAddTaskDialog,
                    child: Icon(
                      CupertinoIcons.square_pencil,
                      color: iconColor,
                      size: 22,
                    ),
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