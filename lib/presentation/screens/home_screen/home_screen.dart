import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_strings.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/di/di.dart';
import 'package:vnote/presentation/cubit/events/events_cubit.dart';
import 'package:vnote/presentation/cubit/notes/notes_cubit.dart';
import 'package:vnote/presentation/cubit/notes/notes_state.dart';
import 'package:vnote/presentation/cubit/payments/payments_cubit.dart';
import 'package:vnote/core/utils/page_transitions.dart';
import 'package:vnote/presentation/screens/events/events_screen.dart';
import 'package:vnote/presentation/screens/home_screen/widgets/feature_card.dart';
import 'package:vnote/presentation/screens/notes/notes_screen.dart';
import 'package:vnote/presentation/screens/payments/payments_screen.dart';
import 'package:vnote/presentation/widgets/app_bar_actions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotesCubit>().loadNotes();
  }

  void _navigateToNotes() {
    Navigator.push(context, SlidePageRoute(page: const NotesScreen()));
  }

  void _navigateToPayments() {
    Navigator.push(
      context,
      SlidePageRoute(
        page: BlocProvider(
          create: (context) => getIt<PaymentsCubit>(),
          child: const PaymentsScreen(),
        ),
      ),
    );
  }

  void _navigateToEvents() {
    Navigator.push(
      context,
      SlidePageRoute(
        page: BlocProvider(
          create: (context) => getIt<EventsCubit>(),
          child: const EventsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.appFirstName} ${AppStrings.appSecondName}',
                style: AppTypography.h3.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          actions: const [AppBarActions()],
        ),
        body: BlocBuilder<NotesCubit, NotesState>(
          builder: (context, state) {
            String notesCount = '0';
            if (state is NotesLoaded) {
              notesCount = state.notes.length.toString();
            } else if (state is NotesEmpty) {
              notesCount = '0';
            }

            return Column(
              children: [
                Expanded(
                  child: FeatureCard(
                    title: 'Notes',
                    subtitle: 'Speak your thoughts, we write them down',
                    icon: Icons.note,
                    color: AppColors.purple,
                    onTap: _navigateToNotes,
                    count: notesCount,
                  ),
                ),
                Expanded(
                  child: FeatureCard(
                    title: 'Payments',
                    subtitle: 'Voice-controlled payments made simple',
                    icon: Icons.payment,
                    color: AppColors.red,
                    onTap: _navigateToPayments,
                  ),
                ),
                Expanded(
                  child: FeatureCard(
                    title: 'Events',
                    subtitle: 'Never miss a moment, stay organized',
                    icon: Icons.event,
                    color: AppColors.green,
                    onTap: _navigateToEvents,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
