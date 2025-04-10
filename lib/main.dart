import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'folders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('notes_database');
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
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
      ),
      home: const FoldersScreen(totalNotesCount: 0),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final Box box = Hive.box('notes_database');
  List<Map<String, dynamic>> notesList = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isSelecting = false;
  List<String> _selectedNotes = [];

  final Color accentColor = const Color(0xFF007AFF); // iOS blue accent color

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    final stored = box.get('notes');
    if (stored != null) {
      setState(() {
        notesList = (stored as List).map<Map<String, dynamic>>((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
      });
    }
  }

  void _saveToHive() => box.put('notes', notesList);

  void _createNewNote() {
    final now = DateTime.now();
    final newNote = {
      'id': now.microsecondsSinceEpoch.toString(),
      'title': '',
      'content': '',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'isPinned': false,
      'folder': 'All iCloud'
    };

    setState(() {
      notesList.insert(0, newNote);
      _saveToHive();
    });

    _navigateToNoteEditor(newNote['id']?.toString() ?? '');
  }

  void _deleteSelectedNotes() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Notes'),
        content: Text(
          _selectedNotes.length == 1
              ? 'Are you sure you want to delete this note?'
              : 'Are you sure you want to delete these ${_selectedNotes.length} notes?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Delete', style: TextStyle(color: CupertinoColors.destructiveRed)),
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              setState(() {
                notesList.removeWhere((note) => _selectedNotes.contains(note['id']));
                _selectedNotes.clear();
                _isSelecting = false;
                _saveToHive();
              });
            },
          ),
        ],
      ),
    );
  }

  void _toggleNoteSelection(String noteId) {
    setState(() {
      if (_selectedNotes.contains(noteId)) {
        _selectedNotes.remove(noteId);
        if (_selectedNotes.isEmpty) {
          _isSelecting = false;
        }
      } else {
        _selectedNotes.add(noteId);
      }
    });
  }

  void _togglePin(int index) {
    setState(() {
      notesList[index]['isPinned'] = !notesList[index]['isPinned'];
      _saveToHive();
    });
  }

  void _updateNote(String id, String title, String content) {
    setState(() {
      final index = notesList.indexWhere((note) => note['id'] == id);
      if (index != -1) {
        notesList[index]['title'] = title;
        notesList[index]['content'] = content;
        notesList[index]['updatedAt'] = DateTime.now().toIso8601String();
        _saveToHive();
      }
    });
  }

  void _navigateToNoteEditor(String noteId) {
    if (_isSelecting) {
      _toggleNoteSelection(noteId);
      return;
    }

    final note = notesList.firstWhere((n) => n['id'] == noteId);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => NoteEditorScreen(
          noteId: noteId,
          initialTitle: note['title'],
          initialContent: note['content'],
          onSave: _updateNote,
        ),
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

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatTime(String isoDate) {
    return DateFormat('h:mm a').format(DateTime.parse(isoDate));
  }

  List<Map<String, dynamic>> get _filteredNotes {
    if (_searchQuery.isEmpty) {
      return notesList;
    }
    return notesList.where((note) {
      return note['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note['content'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _pinnedNotes {
    return _filteredNotes.where((note) => note['isPinned']).toList();
  }

  List<Map<String, dynamic>> get _unpinnedNotes {
    return _filteredNotes.where((note) => !note['isPinned']).toList();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _startSelectionMode() {
    setState(() {
      _isSelecting = true;
      _selectedNotes.clear();
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedNotes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF2F2F7),
        border: Border.all(color: Colors.transparent),
        padding: const EdgeInsetsDirectional.only(start: 4.0, end: 8.0),
        leading: _isSelecting
            ? CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _cancelSelectionMode,
          child: Text(
            'Cancel',
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
            ),
          ),
        )
            : CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) =>
                    FoldersScreen(totalNotesCount: notesList.length),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.back,
                color: accentColor,
                size: 22,
              ),
              const SizedBox(width: 4),
              Text(
                'Folders',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        middle: _isSelecting
            ? Text(
          '${_selectedNotes.length} Selected',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        )
            : const Text(
          'All iCloud',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        trailing: _isSelecting
            ? CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selectedNotes.isNotEmpty ? _deleteSelectedNotes : null,
          child: Icon(
            CupertinoIcons.delete,
            color: _selectedNotes.isNotEmpty ? accentColor : CupertinoColors.systemGrey,
            size: 24,
          ),
        )
            : CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showDeveloperInfo,
          child: Icon(
            CupertinoIcons.ellipsis_circle,
            color: accentColor,
            size: 24,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (!_isSelecting) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(
                        CupertinoIcons.search,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _searchController,
                          placeholder: 'Search',
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          placeholderStyle: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            border: Border(),
                          ),
                          padding: EdgeInsets.zero,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.mic_fill,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ],
            Expanded(
              child: notesList.isEmpty
                  ? _buildEmptyState()
                  : _buildNotesList(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFFF2F2F7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('       '),
                  Text('${notesList.length} Note${notesList.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 16)),
                  _isSelecting
                      ? const SizedBox(width: 24) // Placeholder to maintain layout
                      : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _createNewNote,
                    child: Icon(
                      CupertinoIcons.square_pencil,
                      color: accentColor,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 60,
            color: CupertinoColors.systemGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the pencil button to create a new note',
            style: TextStyle(
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView(
      children: [
        if (_pinnedNotes.isNotEmpty) ...[
          if (!_isSelecting) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Pinned',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          ..._pinnedNotes.map((note) => _buildNoteItem(note)).toList(),
          if (!_isSelecting) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'All Notes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
        ..._unpinnedNotes.map((note) => _buildNoteItem(note)).toList(),
      ],
    );
  }

  Widget _buildNoteItem(Map<String, dynamic> note) {
    final hasTitle = note['title']?.isNotEmpty ?? false;
    final hasContent = note['content']?.isNotEmpty ?? false;
    final updatedAt = note['updatedAt'] ?? note['createdAt'];
    final isSelected = _selectedNotes.contains(note['id']);

    return GestureDetector(
      onTap: () => _navigateToNoteEditor(note['id']),
      onLongPress: () {
        if (!_isSelecting) {
          _startSelectionMode();
          _toggleNoteSelection(note['id']);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.1)
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: accentColor, width: 1.5)
              : null,
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note['isPinned'] && !_isSelecting)
                    Icon(
                      CupertinoIcons.pin_fill,
                      color: accentColor,
                      size: 16,
                    ),
                  if (note['isPinned'] && !_isSelecting)
                    const SizedBox(width: 4),
                  if (_isSelecting)
                    Icon(
                      isSelected
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      color: isSelected ? accentColor : CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  if (_isSelecting)
                    const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasTitle ? note['title'] : 'New Note',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: hasTitle
                            ? (isSelected ? accentColor : CupertinoColors.black)
                            : CupertinoColors.systemGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!_isSelecting)
                    GestureDetector(
                      onTap: () {
                        final index = notesList.indexWhere((n) => n['id'] == note['id']);
                        if (index != -1) {
                          _togglePin(index);
                        }
                      },
                      child: Icon(
                        note['isPinned'] ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                        color: CupertinoColors.systemGrey,
                        size: 18,
                      ),
                    ),
                ],
              ),
              if (hasContent) ...[
                const SizedBox(height: 8),
                Text(
                  note['content'],
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected
                        ? accentColor
                        : CupertinoColors.systemGrey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _formatDate(updatedAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? accentColor
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(updatedAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? accentColor
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  final String noteId;
  final String initialTitle;
  final String initialContent;
  final Function(String, String, String) onSave;

  const NoteEditorScreen({
    super.key,
    required this.noteId,
    required this.initialTitle,
    required this.initialContent,
    required this.onSave,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final Color accentColor = const Color(0xFF007AFF);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      // Show alert if both title and content are empty
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Empty Note'),
          content: const Text('Please add some content before saving.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      // Save the note and pop the screen
      widget.onSave(
        widget.noteId,
        title,
        content,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text(
          _titleController.text.isEmpty ? 'New Note' : _titleController.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveNote,
          child: const Text('Done'),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _titleController,
                placeholder: 'Title',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const BoxDecoration(
                  border: Border(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              Expanded(
                child: CupertinoTextField(
                  controller: _contentController,
                  placeholder: 'Start typing...',
                  maxLines: null,
                  expands: true,
                  decoration: const BoxDecoration(
                    border: Border(),
                  ),
                  style: const TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}