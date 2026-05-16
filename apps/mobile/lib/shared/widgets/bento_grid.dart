import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Asymmetric Bento-style grid (CSS-grid spirit, Flutter idiom).
///
/// Place [BentoTile]s with a column/row span on a fixed [columns]-wide grid.
/// The grid auto-flows: each tile is placed in the first row that has
/// enough space for its `colSpan × rowSpan`.
///
/// ```dart
/// BentoGrid(
///   columns: 4,
///   rowHeight: 96,
///   gap: 12,
///   children: [
///     BentoTile(colSpan: 4, rowSpan: 2, child: HeroWeather()),
///     BentoTile(colSpan: 2, child: KpiParcels()),
///     BentoTile(colSpan: 2, child: KpiAlerts()),
///     BentoTile(colSpan: 4, child: KpiObservations()),
///   ],
/// )
/// ```
class BentoGrid extends StatelessWidget {
  const BentoGrid({
    super.key,
    required this.children,
    this.columns = 4,
    this.rowHeight = 96,
    this.gap = AppSpacing.md,
  });

  final List<BentoTile> children;
  final int columns;
  final double rowHeight;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final cellWidth = (totalWidth - gap * (columns - 1)) / columns;

        // Auto-flow placement on a virtual grid of [columns] wide.
        final List<List<bool>> grid = [];
        final List<_PlacedTile> placed = [];

        for (final tile in children) {
          final colSpan = tile.colSpan.clamp(1, columns);
          final rowSpan = tile.rowSpan.clamp(1, 99);

          int row = 0;
          int col = 0;
          bool found = false;
          while (!found) {
            // Ensure grid has enough rows.
            while (grid.length < row + rowSpan) {
              grid.add(List<bool>.filled(columns, false));
            }
            // Try to find a free col on current row.
            for (col = 0; col <= columns - colSpan; col++) {
              bool free = true;
              for (int dr = 0; dr < rowSpan && free; dr++) {
                for (int dc = 0; dc < colSpan && free; dc++) {
                  if (grid[row + dr][col + dc]) free = false;
                }
              }
              if (free) {
                found = true;
                break;
              }
            }
            if (!found) row++;
          }

          // Mark cells as occupied.
          for (int dr = 0; dr < rowSpan; dr++) {
            for (int dc = 0; dc < colSpan; dc++) {
              grid[row + dr][col + dc] = true;
            }
          }

          placed.add(_PlacedTile(
            tile: tile,
            row: row,
            col: col,
            colSpan: colSpan,
            rowSpan: rowSpan,
          ));
        }

        final totalRows = grid.length;
        final totalHeight =
            totalRows * rowHeight + (totalRows - 1).clamp(0, 999) * gap;

        return SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(
            children: placed.map((p) {
              final left = p.col * (cellWidth + gap);
              final top = p.row * (rowHeight + gap);
              final width = p.colSpan * cellWidth + (p.colSpan - 1) * gap;
              final height = p.rowSpan * rowHeight + (p.rowSpan - 1) * gap;
              return Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: p.tile.child,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class BentoTile {
  const BentoTile({
    required this.child,
    this.colSpan = 1,
    this.rowSpan = 1,
  });

  final Widget child;
  final int colSpan;
  final int rowSpan;
}

class _PlacedTile {
  const _PlacedTile({
    required this.tile,
    required this.row,
    required this.col,
    required this.colSpan,
    required this.rowSpan,
  });

  final BentoTile tile;
  final int row;
  final int col;
  final int colSpan;
  final int rowSpan;
}
