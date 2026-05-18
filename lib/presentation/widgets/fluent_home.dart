import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fluent_sidebar.dart';
import 'fluent_colors.dart';

/// Pantalla principal con layout de tres paneles estilo Notion
class FluentHomeScreen extends ConsumerWidget {
  final Widget content;
  
  const FluentHomeScreen({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar izquierda
          const FluentSidebar(),
          
          // Área de contenido principal
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
