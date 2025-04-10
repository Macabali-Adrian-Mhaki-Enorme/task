import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main.dart';

class FoldersScreen extends StatefulWidget {
  final int totalNotesCount;

  const FoldersScreen({
    Key? key,
    required this.totalNotesCount,
  }) : super(key: key);

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final Color accentColor = const Color(0xFF007AFF);
  final TextEditingController _folderNameController = TextEditingController();
  bool _showFolders = true;
  bool _showTags = false;
  late final Box box;
  List<Map<String, dynamic>> folders = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    box = await Hive.openBox('notes_database');
    _loadFolders();
  }

  void _loadFolders() {
    try {
      final stored = box.get('folders');
      if (stored != null) {
        setState(() {
          folders = List<Map<String, dynamic>>.from(
              (stored as List).map((item) => Map<String, dynamic>.from(item)));

          final allICloudIndex = folders.indexWhere((folder) => folder['name'] == 'All iCloud');
          if (allICloudIndex != -1) {
            folders[allICloudIndex]['count'] = widget.totalNotesCount;
          }
        });
      } else {
        setState(() {
          folders = [
            {'name': 'All iCloud', 'count': widget.totalNotesCount, 'isSelected': true},
            {'name': 'Personal', 'count': 0, 'isSelected': false},
            {'name': 'Work', 'count': 0, 'isSelected': false},
            {'name': 'Ideas', 'count': 0, 'isSelected': false},
            {'name': 'Journal', 'count': 0, 'isSelected': false},
          ];
          _saveToHive();
        });
      }
    } catch (e) {
      debugPrint('Error loading folders: $e');
      setState(() {
        folders = [
          {'name': 'All iCloud', 'count': widget.totalNotesCount, 'isSelected': true},
          {'name': 'Personal', 'count': 0, 'isSelected': false},
          {'name': 'Work', 'count': 0, 'isSelected': false},
          {'name': 'Ideas', 'count': 0, 'isSelected': false},
          {'name': 'Journal', 'count': 0, 'isSelected': false},
        ];
        _saveToHive();
      });
    }
  }

  void _saveToHive() {
    try {
      box.put('folders', folders);
    } catch (e) {
      debugPrint('Error saving folders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const CupertinoPageScaffold(
        backgroundColor: Color(0xFFF2F2F7),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF2F2F7),
        border: null,
        padding: const EdgeInsetsDirectional.only(end: 8.0),
        leading: Container(),
        middle: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showEditDialog,
          child: Text(
            'Edit',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 16,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                'Folders',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showFolders = !_showFolders;
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'iCloud',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Icon(
                      _showFolders ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (_showFolders)
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
                        itemCount: folders.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              if (folders[index]['name'] == 'All iCloud') {
                                Navigator.pushReplacement(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => const NotesScreen(),
                                  ),
                                );
                              } else {
                                _showComingSoonDialog();
                              }
                            },
                            onLongPress: () => _showDeleteFolderDialog(index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.folder,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      folders[index]['name'],
                                      style: const TextStyle(
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${folders[index]['count']}',
                                    style: const TextStyle(
                                      color: CupertinoColors.systemGrey,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: CupertinoColors.systemGrey,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Tags section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showTags = !_showTags;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tags',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Icon(
                            _showTags ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_showTags)
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
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "No tags available yet.",
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFFF2F2F7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showNewFolderDialog,
                    child: Icon(
                      CupertinoIcons.folder_badge_plus,
                      color: Colors.amber,
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

  void _showEditDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Edit Mode'),
        content: const Text('Edit mode is not available in this demo.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showNewFolderDialog() {
    _folderNameController.clear();
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('New Folder'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: _folderNameController,
            placeholder: 'Folder Name',
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
              final text = _folderNameController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  folders.add({
                    'name': text,
                    'count': 0,
                    'isSelected': false,
                  });
                  _saveToHive();
                });
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(int index) {
    if (folders[index]['name'] == 'All iCloud') {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text('The All iCloud folder cannot be deleted.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folders[index]['name']}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              setState(() {
                folders.removeAt(index);
                _saveToHive();
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('This folder will be available in a future update.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}