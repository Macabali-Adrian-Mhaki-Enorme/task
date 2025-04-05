import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('database');

  // Uncomment below line ONLY ONCE to clear malformed data, then comment it again
  // await Hive.box('database').clear();

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

enum FilterType { today, last7days, last30days, all }

class _MyAppState extends State<MyApp> {
  final TextEditingController _addTaskController = TextEditingController();
  final Box box = Hive.box('database');
  List<Map<String, dynamic>> todoList = [];
  FilterType currentFilter = FilterType.all;

  @override
  void initState() {
    super.initState();
    _loadTodoList();
  }

  void _loadTodoList() {
    final stored = box.get('todo');
    if (stored is List) {
      todoList = stored
          .whereType<Map>()
          .map<Map<String, dynamic>>((item) {
        final task = item['task']?.toString() ?? '';
        final status = item['status'] == true;
        final createdAt = item['createdAt']?.toString() ?? DateTime.now().toIso8601String();

        return {
          'task': task,
          'status': status,
          'createdAt': createdAt,
        };
      }).toList();
    } else {
      todoList = [];
    }
  }

  void _saveToHive() {
    if (box.isOpen) {
      box.put('todo', todoList);
    }
  }

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

  List<Map<String, dynamic>> getFilteredTasks() {
    final now = DateTime.now();
    return todoList.where((task) {
      if (task['createdAt'] == null || task['createdAt'].toString().isEmpty) return false;

      DateTime created;
      try {
        created = DateTime.parse(task['createdAt']);
      } catch (e) {
        return false;
      }

      switch (currentFilter) {
        case FilterType.today:
          return created.year == now.year &&
              created.month == now.month &&
              created.day == now.day;
        case FilterType.last7days:
          return created.isAfter(now.subtract(const Duration(days: 7)));
        case FilterType.last30days:
          return created.isAfter(now.subtract(const Duration(days: 30)));
        case FilterType.all:
          return true;
      }
    }).toList();
  }

  Widget buildFilterButton(String label, FilterType type) {
    final isSelected = currentFilter == type;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
      borderRadius: BorderRadius.circular(8),
      onPressed: () {
        setState(() {
          currentFilter = type;
        });
      },
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? CupertinoColors.white : CupertinoColors.black,
          fontSize: 14,
        ),
      ),
    );
  }

  String formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = getFilteredTasks();

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildFilterButton('Today', FilterType.today),
                  buildFilterButton('Last 7 Days', FilterType.last7days),
                  buildFilterButton('Last 30 Days', FilterType.last30days),
                  buildFilterButton('All', FilterType.all),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredTasks.isEmpty
                  ? const Center(
                child: Text(
                  'No tasks found.',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              )
                  : ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  final realIndex = todoList.indexWhere((t) =>
                  t['task'] == task['task'] &&
                      t['createdAt'] == task['createdAt']);
                  final createdTime = formatDateTime(task['createdAt']);

                  return GestureDetector(
                    onTap: () => _toggleStatus(realIndex),
                    onLongPress: () => _showDeleteDialog(realIndex),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: CupertinoColors.systemGrey5)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: CupertinoColors.systemGroupedBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('       '),
                  Text('${filteredTasks.length} Task${filteredTasks.length == 1 ? '' : 's'}',
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
