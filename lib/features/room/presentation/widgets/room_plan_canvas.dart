import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:table_master_mobile/core/responsive/breakpoints.dart';
import 'package:table_master_mobile/features/room/data/models/room_point.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_in.dart';
import 'package:table_master_mobile/features/table/data/models/table_entity_out.dart';

class RoomPlanCanvas extends StatefulWidget {
  final List<RoomPoint> boundaryPoints;
  final List<TableEntityIn> tables;
  final bool isEditing;
  final int? selectedTableId;
  final TableEntityIn? selectedDraftTable;
  final Map<int, String> tableStatuses;
  final Map<int, int> pendingBadgeCounts;
  final Map<int, int> validatedBadgeCounts;
  final bool disableUnavailableTables;
  final ValueChanged<TableEntityIn>? onTableSelected;
  final void Function(TableEntityIn table, double x, double y)? onTableMoved;
  final void Function(int index, double x, double y)? onBoundaryPointMoved;

  /// Aspect ratio interne du canvas (largeur / hauteur). 1.25 par défaut.
  final double aspectRatio;

  /// Active la barre d'outils de zoom (visible sur tablet/desktop par défaut).
  final bool showZoomToolbar;

  const RoomPlanCanvas({
    super.key,
    required this.boundaryPoints,
    required this.tables,
    this.isEditing = false,
    this.selectedTableId,
    this.selectedDraftTable,
    this.tableStatuses = const {},
    this.pendingBadgeCounts = const {},
    this.validatedBadgeCounts = const {},
    this.disableUnavailableTables = true,
    this.onTableSelected,
    this.onTableMoved,
    this.onBoundaryPointMoved,
    this.aspectRatio = 1.25,
    this.showZoomToolbar = true,
  });

  @override
  State<RoomPlanCanvas> createState() => _RoomPlanCanvasState();
}

class _RoomPlanCanvasState extends State<RoomPlanCanvas> {
  final TransformationController _controller = TransformationController();
  static const double _minScale = 0.6;
  static const double _maxScale = 4.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setScale(double scale) {
    final clamped = scale.clamp(_minScale, _maxScale).toDouble();
    _controller.value = Matrix4.identity()..scale(clamped);
  }

  double get _currentScale {
    return _controller.value.getMaxScaleOnAxis();
  }

  void _zoomIn() => _setScale(_currentScale * 1.25);
  void _zoomOut() => _setScale(_currentScale / 1.25);
  void _reset() {
    _controller.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Taille cible : on borne en pixels pour éviter un canvas géant sur grand écran,
    // et on garde une lisibilité correcte sur mobile.
    final maxWidth = context.valueByScreen<double>(
      mobile: double.infinity,
      tablet: 720,
      desktop: 900,
      wide: 1080,
    );

    // En édition, le pan global est désactivé : on laisse le drag d'objets prendre la priorité.
    // L'utilisateur peut quand même zoomer via la toolbar (+/-/reset).
    final allowPan = !widget.isEditing;
    final showToolbar = widget.showZoomToolbar && !context.isMobile;

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final effectiveMaxWidth = maxWidth == double.infinity
            ? outerConstraints.maxWidth
            : math.min(maxWidth, outerConstraints.maxWidth);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showToolbar) _ZoomToolbar(
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onReset: _reset,
                  isEditing: widget.isEditing,
                ),
                AspectRatio(
                  aspectRatio: widget.aspectRatio,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);

                      final innerCanvas = DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                          border: Border.all(color: colors.outlineVariant),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Builder(
                          builder: (canvasContext) {
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _RoomPainter(
                                      boundaryPoints: widget.boundaryPoints,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                                ...widget.tables.map(
                                  (table) => _buildTable(context, table, size),
                                ),
                                if (widget.isEditing)
                                  ...widget.boundaryPoints.asMap().entries.map(
                                    (entry) => _buildBoundaryHandle(
                                      entry.key,
                                      entry.value,
                                      size,
                                      colors,
                                      canvasContext,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      );

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: InteractiveViewer(
                          transformationController: _controller,
                          minScale: _minScale,
                          maxScale: _maxScale,
                          panEnabled: allowPan,
                          scaleEnabled: true,
                          boundaryMargin: const EdgeInsets.all(40),
                          child: innerCanvas,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(BuildContext context, TableEntityIn table, Size size) {
    final colors = Theme.of(context).colorScheme;
    final id = table is TableEntityOut ? table.id : null;
    final status = id == null ? 'Disponible' : widget.tableStatuses[id] ?? '';
    final pendingCount = id == null ? 0 : widget.pendingBadgeCounts[id] ?? 0;
    final validatedCount = id == null ? 0 : widget.validatedBadgeCounts[id] ?? 0;
    final hasBadge = pendingCount > 0 || validatedCount > 0;
    final isAvailable = !widget.disableUnavailableTables ||
        status == 'Disponible' ||
        widget.isEditing;
    final isSelected = widget.selectedDraftTable == table ||
        (id != null && widget.selectedTableId == id);
    final statusColor = pendingCount > 0
        ? Colors.orange
        : validatedCount > 0
            ? Colors.blue
            : colors.outline;
    final left =
        (table.positionX * size.width).clamp(0.0, size.width - 32).toDouble();
    final top =
        (table.positionY * size.height).clamp(0.0, size.height - 32).toDouble();
    final width = (table.width * size.width).clamp(48.0, size.width).toDouble();
    final height =
        (table.height * size.height).clamp(48.0, size.height).toDouble();

    final tooltipMessage = !context.isMobile && status.isNotEmpty
        ? 'Table ${table.tableNumber} • ${table.numberOfSeats} places\n$status'
        : null;
    final semanticParts = <String>[
      'Table ${table.tableNumber}',
      '${table.numberOfSeats} place${table.numberOfSeats > 1 ? 's' : ''}',
      if (status.isNotEmpty) status,
      if (pendingCount > 0)
        '$pendingCount réservation${pendingCount > 1 ? 's' : ''} en attente',
      if (validatedCount > 0)
        '$validatedCount réservation${validatedCount > 1 ? 's' : ''} validée${validatedCount > 1 ? 's' : ''}',
    ];
    final semanticOnTap = isAvailable && widget.onTableSelected != null
        ? () => widget.onTableSelected!(table)
        : null;

    final visualTable = _TouchPriority(
        enabled: widget.isEditing,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: widget.isEditing && isAvailable
              ? (_) => widget.onTableSelected?.call(table)
              : null,
          onPointerMove: widget.isEditing
              ? (event) {
                  final nextX =
                      (table.positionX + event.delta.dx / size.width / _currentScale)
                          .clamp(0.0, 0.98)
                          .toDouble();
                  final nextY =
                      (table.positionY + event.delta.dy / size.height / _currentScale)
                          .clamp(0.0, 0.98)
                          .toDouble();
                  widget.onTableMoved?.call(table, nextX, nextY);
                }
              : null,
          child: MouseRegion(
            cursor: widget.isEditing && isAvailable
                ? SystemMouseCursors.grab
                : (isAvailable ? SystemMouseCursors.click : SystemMouseCursors.basic),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: !widget.isEditing && isAvailable
                  ? () => widget.onTableSelected?.call(table)
                  : null,
              child: Transform.rotate(
                angle: table.rotationDegrees * math.pi / 180,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tableColor(
                      colors,
                      isSelected,
                      pendingCount,
                      validatedCount,
                      isAvailable,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : hasBadge
                              ? statusColor
                              : isAvailable
                                  ? colors.outline
                                  : colors.outlineVariant,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: table.shape == TableShape.circle
                        ? BorderRadius.circular(999)
                        : BorderRadius.circular(
                            table.shape == TableShape.square ? 6 : 4,
                          ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'T${table.tableNumber}',
                                  style: TextStyle(
                                    color: isAvailable
                                        ? colors.onSurface
                                        : colors.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${table.numberOfSeats}p',
                                  style: TextStyle(
                                    color: isAvailable
                                        ? colors.onSurfaceVariant
                                        : colors.outline,
                                    fontSize: 11,
                                  ),
                                ),
                                if (status.isNotEmpty && status != 'Disponible')
                                  Text(
                                    status,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (pendingCount > 0)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: _CanvasBadge(
                            text: pendingCount.toString(),
                            color: Colors.orange,
                            icon: Icons.pending_actions,
                          ),
                        ),
                      if (validatedCount > 0)
                        Positioned(
                          left: -5,
                          top: -5,
                          child: _CanvasBadge(
                            text: validatedCount.toString(),
                            color: Colors.blue,
                            icon: Icons.event,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    final inner = Semantics(
      label: semanticParts.join(', '),
      button: semanticOnTap != null,
      enabled: isAvailable,
      selected: isSelected,
      onTap: semanticOnTap,
      excludeSemantics: true,
      child: visualTable,
    );

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: tooltipMessage != null
          ? Tooltip(message: tooltipMessage, child: inner)
          : inner,
    );
  }

  Color _tableColor(
    ColorScheme colors,
    bool isSelected,
    int pendingCount,
    int validatedCount,
    bool isAvailable,
  ) {
    if (isSelected) return colors.primaryContainer;
    if (pendingCount > 0) return Colors.orange.withValues(alpha: 0.12);
    if (validatedCount > 0) return Colors.blue.withValues(alpha: 0.12);
    return isAvailable ? colors.surface : colors.surfaceContainerHighest;
  }

  Widget _buildBoundaryHandle(
    int index,
    RoomPoint point,
    Size size,
    ColorScheme colors,
    BuildContext canvasContext,
  ) {
    void movePoint(Offset globalPosition) {
      final renderBox = canvasContext.findRenderObject();
      if (renderBox is! RenderBox) return;

      final local = renderBox.globalToLocal(globalPosition);
      final nextX = (local.dx / renderBox.size.width).clamp(0.0, 1.0).toDouble();
      final nextY = (local.dy / renderBox.size.height).clamp(0.0, 1.0).toDouble();
      widget.onBoundaryPointMoved?.call(index, nextX, nextY);
    }

    final handleSize = context.isMobile ? 48.0 : 28.0;
    final dotSize = context.isMobile ? 20.0 : 14.0;

    return Positioned(
      left: point.x * size.width - handleSize / 2,
      top: point.y * size.height - handleSize / 2,
      width: handleSize,
      height: handleSize,
      child: _TouchPriority(
        enabled: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => movePoint(event.position),
            onPointerMove: (event) => movePoint(event.position),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.onPrimary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.18),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: SizedBox(width: dotSize, height: dotSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomToolbar extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;
  final bool isEditing;

  const _ZoomToolbar({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Mode édition',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton.filledTonal(
            tooltip: 'Réinitialiser le zoom',
            onPressed: onReset,
            icon: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: 'Zoom arrière',
            onPressed: onZoomOut,
            icon: const Icon(Icons.zoom_out),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: 'Zoom avant',
            onPressed: onZoomIn,
            icon: const Icon(Icons.zoom_in),
          ),
        ],
      ),
    );
  }
}

class _CanvasBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _CanvasBadge({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: Colors.white),
            const SizedBox(width: 2),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TouchPriority extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _TouchPriority({required this.enabled, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return RawGestureDetector(
      gestures: {
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              () => EagerGestureRecognizer(),
              (_) {},
            ),
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _RoomPainter extends CustomPainter {
  final List<RoomPoint> boundaryPoints;
  final Color color;

  _RoomPainter({required this.boundaryPoints, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (boundaryPoints.length < 3) return;

    final path = Path()
      ..moveTo(
        boundaryPoints.first.x * size.width,
        boundaryPoints.first.y * size.height,
      );
    for (final point in boundaryPoints.skip(1)) {
      path.lineTo(point.x * size.width, point.y * size.height);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.08));
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RoomPainter oldDelegate) {
    return oldDelegate.boundaryPoints != boundaryPoints ||
        oldDelegate.color != color;
  }
}
