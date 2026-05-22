import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fluent_sidebar.dart';
import 'fluent_colors.dart';
import '../../core/constants/layout_breakpoints.dart';

/// Shell principal: sidebar + contenido en pantallas anchas.
class FluentHomeScreen extends ConsumerWidget {
  final Widget content;
  final String? selectedEntryId;

  const FluentHomeScreen({
    super.key,
    required this.content,
    this.selectedEntryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = LayoutBreakpoints.isCompact(context);

    if (isCompact) {
      return Scaffold(
        body: SafeArea(child: FluentSidebar(selectedEntryId: selectedEntryId)),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          FluentSidebar(selectedEntryId: selectedEntryId),
          Expanded(
            child: Container(
              color: isDark ? FluentColors.surfaceDark : FluentColors.surfaceLight,
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel vacío en escritorio cuando no hay nota seleccionada.
class FluentHomePlaceholder extends StatelessWidget {
  const FluentHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? FluentColors.textSecondaryDark : FluentColors.textSecondaryLight;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: textColor.withOpacity(0.5)),
          const SizedBox(height: FluentSpacing.lg),
          Text(
            'Selecciona una nota',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: FluentSpacing.sm),
          Text(
            'O crea una nueva con el botón +',
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
