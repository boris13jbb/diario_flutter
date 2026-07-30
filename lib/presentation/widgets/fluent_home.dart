import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fluent_sidebar.dart';
import 'fluent_colors.dart';
import '../../core/constants/layout_breakpoints.dart';

/// Shell principal: sidebar redimensionable + contenido en pantallas anchas.
class FluentHomeScreen extends ConsumerStatefulWidget {
  final Widget content;
  final String? selectedEntryId;

  const FluentHomeScreen({
    super.key,
    required this.content,
    this.selectedEntryId,
  });

  @override
  ConsumerState<FluentHomeScreen> createState() => _FluentHomeScreenState();
}

class _FluentHomeScreenState extends ConsumerState<FluentHomeScreen> {
  static const _prefsKey = 'notaspro_sidebar_width';

  double? _sidebarWidth;
  bool _dragging = false;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadWidth();
  }

  Future<void> _loadWidth() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefsKey);
    if (!mounted) return;
    setState(() {
      if (saved != null) {
        _sidebarWidth = saved.clamp(
          LayoutBreakpoints.sidebarMin,
          LayoutBreakpoints.sidebarMax,
        );
      }
      _prefsLoaded = true;
    });
  }

  Future<void> _persistWidth(double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, width);
  }

  double _resolvedSidebarWidth(BuildContext context) {
    return (_sidebarWidth ?? LayoutBreakpoints.sidebarFor(context)).clamp(
      LayoutBreakpoints.sidebarMin,
      LayoutBreakpoints.sidebarMax,
    );
  }

  void _onDragUpdate(DragUpdateDetails details, double maxWidth) {
    final current = _resolvedSidebarWidth(context);
    final next = (current + details.delta.dx).clamp(
      LayoutBreakpoints.sidebarMin,
      // Deja al menos ~320px para el panel de detalle.
      (maxWidth - 320).clamp(
        LayoutBreakpoints.sidebarMin,
        LayoutBreakpoints.sidebarMax,
      ),
    );
    setState(() => _sidebarWidth = next.toDouble());
  }

  void _onDragEnd(DragEndDetails _) {
    setState(() => _dragging = false);
    _persistWidth(_resolvedSidebarWidth(context));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = LayoutBreakpoints.isCompact(context);

    if (isCompact) {
      return Scaffold(
        body: SafeArea(
          child: FluentSidebar(selectedEntryId: widget.selectedEntryId),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidebarWidth = _prefsLoaded
        ? _resolvedSidebarWidth(context)
        : LayoutBreakpoints.sidebarFor(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FluentSidebar(
                selectedEntryId: widget.selectedEntryId,
                width: sidebarWidth,
              ),
              _SidebarResizeHandle(
                isDark: isDark,
                active: _dragging,
                onDragStart: (_) => setState(() => _dragging = true),
                onDragUpdate: (d) => _onDragUpdate(d, constraints.maxWidth),
                onDragEnd: _onDragEnd,
                onDoubleTap: () {
                  final reset = LayoutBreakpoints.sidebarFor(context);
                  setState(() {
                    _sidebarWidth = reset;
                    _dragging = false;
                  });
                  _persistWidth(reset);
                },
              ),
              Expanded(
                child: ColoredBox(
                  color: isDark
                      ? FluentColors.surfaceDark
                      : FluentColors.surfaceLight,
                  child: widget.content,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Asa vertical para arrastrar y cambiar el ancho del panel de notas.
class _SidebarResizeHandle extends StatefulWidget {
  final bool isDark;
  final bool active;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onDoubleTap;

  const _SidebarResizeHandle({
    required this.isDark,
    required this.active,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDoubleTap,
  });

  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.active || _hovered;
    final lineColor = highlight
        ? FluentColors.primary
        : (widget.isDark ? FluentColors.borderDark : FluentColors.borderLight);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: widget.onDragStart,
        onHorizontalDragUpdate: widget.onDragUpdate,
        onHorizontalDragEnd: widget.onDragEnd,
        onDoubleTap: widget.onDoubleTap,
        child: SizedBox(
          width: 6,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: highlight ? 3 : 1,
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(FluentSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: textColor.withValues(alpha: 0.45),
            ),
            const SizedBox(height: FluentSpacing.lg),
            Text(
              'Selecciona una nota',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: FluentSpacing.sm),
            Text(
              'O crea una nueva con el botón +',
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FluentSpacing.lg),
            Text(
              'Arrastra el borde del panel de notas para redimensionarlo',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
