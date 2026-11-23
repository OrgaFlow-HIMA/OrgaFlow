import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/division_service.dart';

class DivisionNameText extends StatefulWidget {
  final String? divisionId;
  final String? prefix;
  final TextStyle? style;
  final DivisionNameLoader? divisionNameLoader;

  const DivisionNameText({
    super.key,
    required this.divisionId,
    this.prefix,
    this.style,
    this.divisionNameLoader,
  });

  @override
  State<DivisionNameText> createState() => _DivisionNameTextState();
}

class _DivisionNameTextState extends State<DivisionNameText> {
  late Future<String?> _divisionName;

  @override
  void initState() {
    super.initState();
    _loadDivisionName();
  }

  @override
  void didUpdateWidget(covariant DivisionNameText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.divisionId != widget.divisionId ||
        oldWidget.divisionNameLoader != widget.divisionNameLoader) {
      _loadDivisionName();
    }
  }

  void _loadDivisionName() {
    final divisionId = widget.divisionId?.trim();
    if (divisionId == null || divisionId.isEmpty) {
      _divisionName = Future.value(null);
      return;
    }

    _divisionName = (widget.divisionNameLoader ?? DivisionService())
        .getDivisionName(divisionId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _divisionName,
      builder: (context, snapshot) {
        final result = _resolveDisplayState(snapshot);
        final prefix = widget.prefix?.trim() ?? '';

        final label = prefix.isEmpty
            ? result.label
            : '$prefix • ${result.label}';

        return Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (widget.style ?? const TextStyle(fontSize: 12)).copyWith(
            color: widget.style?.color ?? result.color,
            fontWeight: widget.style?.fontWeight ?? result.fontWeight,
          ),
        );
      },
    );
  }

  // =========================================================
  // STATE RESOLVER
  // =========================================================

  _DivisionDisplayState _resolveDisplayState(AsyncSnapshot<String?> snapshot) {
    // 1) Division ID kosong / null
    final rawId = widget.divisionId?.trim() ?? '';
    if (rawId.isEmpty) {
      return const _DivisionDisplayState(
        label: 'Divisi belum ditentukan',
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w500,
      );
    }

    // 2) Error dari Firestore
    if (snapshot.hasError) {
      return _DivisionDisplayState(
        label: _errorMessage(snapshot.error),
        color: AppTheme.error,
        fontWeight: FontWeight.w500,
      );
    }

    // 3) Masih loading
    if (snapshot.connectionState != ConnectionState.done) {
      return const _DivisionDisplayState(
        label: 'Memuat divisi...',
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w500,
      );
    }

    // 4) Selesai — data ada atau tidak ditemukan
    final data = snapshot.data?.trim() ?? '';
    if (data.isEmpty) {
      return const _DivisionDisplayState(
        label: 'Divisi tidak ditemukan',
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w500,
      );
    }

    return _DivisionDisplayState(
      label: data,
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w600,
    );
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  String _errorMessage(Object? error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Akses Firestore untuk divisi ditolak';
      }
      return 'Gagal memuat divisi (${error.code})';
    }
    return 'Gagal memuat divisi';
  }
}

// =========================================================
// VALUE OBJECT
// =========================================================

class _DivisionDisplayState {
  final String label;
  final Color color;
  final FontWeight fontWeight;

  const _DivisionDisplayState({
    required this.label,
    required this.color,
    required this.fontWeight,
  });
}
