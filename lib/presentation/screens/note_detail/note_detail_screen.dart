// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/domain/entities/note.dart';
import 'package:vnote/presentation/cubit/notes/notes_cubit.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late List<String> _tags;
  late bool _isFavorite;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _tagController = TextEditingController();
    _tags = List<String>.from(widget.note.tags);
    _isFavorite = widget.note.isFavorite;

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
        _tagController.clear();
        _hasChanges = true;
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      _hasChanges = true;
    });
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      // If both are empty, just go back
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final note = Note(
      id: widget.note.id,
      userId: widget.note.userId,
      title: title.isEmpty ? 'Untitled' : title,
      content: content,
      tags: _tags,
      createdAt: widget.note.createdAt,
      updatedAt: now,
      isFavorite: _isFavorite,
      wordCount: content
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length,
    );

    final cubit = context.read<NotesCubit>();
    await cubit.updateNote(note);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      Navigator.pop(context);
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<NotesCubit>().deleteNote(widget.note.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to save?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      await _saveNote();
    }

    return shouldSave != null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges && mounted) {
          final shouldSave = await _onWillPop();
          if (shouldSave == true && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Note', style: AppTypography.h6),
          actions: [
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
              color: _isFavorite ? AppColors.red : null,
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteNote,
            ),
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              onPressed: _isSaving ? null : _saveNote,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  hintStyle: AppTypography.h3.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                style: AppTypography.h3.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: null,
              ),
              const SizedBox(height: 16),
              // Tags section
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              // Add tag field
              TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Add tag (press Enter)',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.tag),
                ),
                style: AppTypography.bodyMedium,
                onSubmitted: _addTag,
              ),
              const Divider(),
              const SizedBox(height: 8),
              // Content field
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  hintText: 'Start writing...',
                  border: InputBorder.none,
                ),
                style: AppTypography.bodyLarge.copyWith(height: 1.6),
                maxLines: null,
                minLines: 10,
                textAlignVertical: TextAlignVertical.top,
              ),
              // Note info
              const SizedBox(height: 24),
              Divider(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              Text(
                'Created: ${_formatDate(widget.note.createdAt)}',
                style: AppTypography.caption.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Updated: ${_formatDate(widget.note.updatedAt)}',
                style: AppTypography.caption.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              if (widget.note.wordCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Words: ${widget.note.wordCount}',
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
