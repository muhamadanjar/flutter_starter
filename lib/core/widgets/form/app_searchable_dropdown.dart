import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_form_field_scaffold.dart';
import 'app_form_option.dart';

/// Signature for server-side option search. Called debounced as the user
/// types; an empty query is issued when the sheet opens.
typedef AppOptionSearch<T> = Future<List<AppFormOption<T>>> Function(
    String query);

/// Controlled searchable select: tap opens a modal bottom sheet with a
/// search box. Two modes, exactly one must be provided:
///
/// - [options]: local list, filtered in-memory (case-insensitive contains).
/// - [onSearch]: server-side query, debounced 400ms, with loading and
///   error/retry states in the sheet.
///
/// The value is the full [AppFormOption] (not just `T`) so the field can
/// always render the label of a preselected value in remote mode, where no
/// option list exists until the user searches.
class AppSearchableDropdown<T> extends StatelessWidget {
  const AppSearchableDropdown({
    super.key,
    this.label,
    this.hint,
    this.searchHint,
    required this.value,
    this.options,
    this.onSearch,
    this.onChanged,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.errorText,
    this.enabled = true,
  }) : assert(
          (options != null) ^ (onSearch != null),
          'Provide exactly one of options (local) or onSearch (remote)',
        );

  final String? label;
  final String? hint;
  final String? searchHint;
  final AppFormOption<T>? value;
  final List<AppFormOption<T>>? options;
  final AppOptionSearch<T>? onSearch;
  final ValueChanged<AppFormOption<T>?>? onChanged;
  final FormFieldValidator<AppFormOption<T>>? validator;
  final AutovalidateMode autovalidateMode;
  final String? errorText;
  final bool enabled;

  Future<void> _openSheet(
    BuildContext context,
    FormFieldState<AppFormOption<T>> field,
  ) async {
    final picked = await showModalBottomSheet<AppFormOption<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _SearchSheet<T>(
        title: label ?? hint ?? '',
        searchHint: searchHint,
        selected: value,
        options: options,
        onSearch: onSearch,
      ),
    );
    if (picked == null) return;

    field.didChange(picked);
    onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AppControlledFormField<AppFormOption<T>>(
      value: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      label: label,
      errorText: errorText,
      enabled: enabled,
      builder: (context, field) {
        final hasError = (errorText ?? field.errorText) != null;

        return AppFieldBox(
          hasError: hasError,
          enabled: enabled,
          onTap: () => _openSheet(context, field),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value?.label ?? hint ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: value != null
                      ? AppTypography.bodyLarge.copyWith(
                          color: enabled
                              ? context.colors.textPrimary
                              : context.colors.textDisabled,
                        )
                      : AppTypography.bodyMedium.copyWith(
                          color: context.colors.textHint,
                        ),
                ),
              ),
              Icon(
                Icons.search_rounded,
                size: 20,
                color: context.colors.textSecondary,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchSheet<T> extends StatefulWidget {
  const _SearchSheet({
    required this.title,
    this.searchHint,
    this.selected,
    this.options,
    this.onSearch,
  });

  final String title;
  final String? searchHint;
  final AppFormOption<T>? selected;
  final List<AppFormOption<T>>? options;
  final AppOptionSearch<T>? onSearch;

  @override
  State<_SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<_SearchSheet<T>> {
  static const _debounce = Duration(milliseconds: 400);

  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<AppFormOption<T>> _results = [];
  bool _loading = false;
  Object? _error;

  bool get _isRemote => widget.onSearch != null;

  @override
  void initState() {
    super.initState();
    if (_isRemote) {
      _search('');
    } else {
      _results = widget.options!;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (!_isRemote) {
      final lower = query.toLowerCase();
      setState(() {
        _results = widget.options!
            .where((o) => o.label.toLowerCase().contains(lower))
            .toList();
      });
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.onSearch!(query);
      if (!mounted) return;
      // Ignore stale responses: only apply if query still current
      if (query != _searchController.text.trim()) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (q) => _onQueryChanged(q.trim()),
                style: AppTypography.bodyLarge.copyWith(
                  color: context.colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? 'Search...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: context.colors.textHint,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.colors.textSecondary,
                  ),
                  filled: true,
                  fillColor: context.colors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: context.colors.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load options',
              style: AppTypography.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _search(_searchController.text.trim()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No results',
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.textHint,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final option = _results[index];
        final isSelected = widget.selected != null &&
            widget.selected!.value == option.value;

        return ListTile(
          enabled: option.enabled,
          leading: option.icon,
          title: Text(
            option.label,
            style: AppTypography.bodyLarge.copyWith(
              color: option.enabled
                  ? context.colors.textPrimary
                  : context.colors.textDisabled,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_rounded, color: context.colors.primary)
              : null,
          onTap: option.enabled
              ? () => Navigator.of(context).pop(option)
              : null,
        );
      },
    );
  }
}
