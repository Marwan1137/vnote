// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/di/di.dart';
import 'package:vnote/domain/entities/note.dart';
import 'package:vnote/presentation/cubit/notes/notes_cubit.dart';
import 'package:vnote/presentation/cubit/notes/notes_state.dart';
import 'package:vnote/presentation/screens/home_screen/widgets/note_card.dart';
import 'package:vnote/presentation/screens/home_screen/widgets/empty_state.dart';
import 'package:vnote/presentation/screens/home_screen/widgets/filter_chips.dart';
import 'package:vnote/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:vnote/presentation/screens/recording/recording_screen.dart';
import 'package:vnote/presentation/cubit/recording/recording_cubit.dart';
import 'package:vnote/presentation/widgets/unified_mic_fab.dart';
import 'package:vnote/core/utils/page_transitions.dart';
import 'package:vnote/presentation/widgets/app_bar_actions.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<NotesCubit>().loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<NotesCubit>().searchNotes('');
      }
    });
  }

  void _onSearchChanged(String query) {
    context.read<NotesCubit>().searchNotes(query);
  }

  void _onFilterChanged(NotesFilter filter) {
    context.read<NotesCubit>().applyFilter(filter);
  }

  void _onNoteTap(Note note) {
    Navigator.push(
      context,
      SlidePageRoute(page: NoteDetailScreen(note: note)),
    ).then((_) {
      if (mounted) {
        context.read<NotesCubit>().loadNotes();
      }
    });
  }

  void _onStartRecording() {
    Navigator.push(
      context,
      FadePageRoute(
        page: BlocProvider(
          create: (context) => getIt<RecordingCubit>(),
          child: const RecordingScreen(),
        ),
      ),
    ).then((noteCreated) {
      if (noteCreated == true && mounted) {
        context.read<NotesCubit>().loadNotes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  style: AppTypography.bodyLarge,
                  onChanged: _onSearchChanged,
                )
              : Text(
                  'Notes',
                  style: AppTypography.h3.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: AppTypography.bold,
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: _toggleSearch,
            ),
            const AppBarActions(),
          ],
        ),
        body: BlocBuilder<NotesCubit, NotesState>(
          builder: (context, state) {
            if (state is NotesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: AppTypography.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<NotesCubit>().loadNotes(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is NotesEmpty) {
              return const EmptyState();
            }

            if (state is NotesLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<NotesCubit>().refreshNotes();
                },
                child: Column(
                  children: [
                    FilterChips(
                      currentFilter: state.filter,
                      onFilterChanged: _onFilterChanged,
                    ),
                    Expanded(
                      child: state.filteredNotes.isEmpty
                          ? EmptyState(
                              message: state.searchQuery != null
                                  ? 'No notes found for "${state.searchQuery}"'
                                  : 'No notes in this category',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.filteredNotes.length,
                              itemBuilder: (context, index) {
                                final note = state.filteredNotes[index];
                                return NoteCard(
                                  note: note,
                                  onTap: () => _onNoteTap(note),
                                  onFavoriteToggle: () {
                                    context.read<NotesCubit>().toggleFavorite(
                                      note,
                                    );
                                  },
                                  onDelete: () {
                                    _showDeleteDialog(context, note);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: UnifiedMicFab(
          onPressed: _onStartRecording,
          heroTag: 'mic_fab',
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<NotesCubit>().deleteNote(note.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
