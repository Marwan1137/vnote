import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:vnote/core/theme/theme_provider.dart';
import 'package:vnote/core/utils/page_transitions.dart';
import 'package:vnote/presentation/auth/cubit/auth_cubit.dart';
import 'package:vnote/presentation/auth/cubit/auth_state.dart';
import 'package:vnote/presentation/auth/screens/account_details_screen.dart';

class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Theme toggle icon (only show if authenticated)
        if (authState is AuthAuthenticated)
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: themeProvider.themeMode == ThemeMode.dark
                ? 'Switch to light mode'
                : 'Switch to dark mode',
          ),
        // Account icon (only show if authenticated)
        if (authState is AuthAuthenticated)
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(context).push(
                SlidePageRoute(
                  page: BlocProvider.value(
                    value: authCubit,
                    child: const AccountDetailsScreen(),
                  ),
                ),
              );
            },
            tooltip: 'Account details',
          ),
      ],
    );
  }
}
