import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/suggestion_model.dart';
import '../utils/currency_formatter.dart';

class SmartSuggestionsScreen extends ConsumerStatefulWidget {
  const SmartSuggestionsScreen({super.key});

  @override
  ConsumerState<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends ConsumerState<SmartSuggestionsScreen> {
  final List<String> _watchlist = [];
  SuggestionType? _selectedFilter;

  void _addToWatchlist(String suggestionId) {
    setState(() {
      if (!_watchlist.contains(suggestionId)) {
        _watchlist.add(suggestionId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Suggestion added to watchlist'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _watchlist.remove(suggestionId);
                });
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suggestion is already in watchlist')),
        );
      }
    });
  }

  void _removeFromWatchlist(String suggestionId) {
    setState(() {
      _watchlist.remove(suggestionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suggestion removed from watchlist')),
      );
    });
  }

  void _viewSuggestionDetails(Suggestion suggestion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        suggestion.category,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPriorityColor(suggestion.priority).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getPriorityText(suggestion.priority),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getPriorityColor(suggestion.priority),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              suggestion.description,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Savings/Gain Display
            if (suggestion.potentialSavings != null || suggestion.potentialGain != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: suggestion.type == SuggestionType.cutExpense
                      ? const Color(0xFF27AE60).withOpacity(0.1)
                      : const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      suggestion.type == SuggestionType.cutExpense
                          ? Icons.savings_rounded
                          : Icons.trending_up_rounded,
                      color: suggestion.type == SuggestionType.cutExpense
                          ? const Color(0xFF27AE60)
                          : const Color(0xFF4A90E2),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.type == SuggestionType.cutExpense
                                ? 'Potential Savings'
                                : 'Potential Gain',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(suggestion.potentialSavings ?? suggestion.potentialGain ?? 0, ref.read(currencyProvider)),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: suggestion.type == SuggestionType.cutExpense
                                  ? const Color(0xFF27AE60)
                                  : const Color(0xFF4A90E2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Action Steps
            Text(
              'Action Steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            ...suggestion.actionSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: suggestion.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: suggestion.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_watchlist.contains(suggestion.id)) {
                    _removeFromWatchlist(suggestion.id);
                  } else {
                    _addToWatchlist(suggestion.id);
                  }
                },
                icon: Icon(
                  _watchlist.contains(suggestion.id)
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 18,
                ),
                label: Text(
                  _watchlist.contains(suggestion.id)
                      ? 'Remove from Watchlist'
                      : 'Add to Watchlist',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return const Color(0xFFE74C3C);
      case Priority.medium:
        return const Color(0xFFF39C12);
      case Priority.low:
        return const Color(0xFF27AE60);
    }
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 'High Priority';
      case Priority.medium:
        return 'Medium Priority';
      case Priority.low:
        return 'Low Priority';
    }
  }

  List<Suggestion> _filterSuggestions(List<Suggestion> suggestions) {
    if (_selectedFilter == null) return suggestions;
    return suggestions.where((s) => s.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(allSuggestionsProvider);
    final filteredSuggestions = _filterSuggestions(suggestions);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF4A90E2),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Smart Suggestions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (_watchlist.isNotEmpty)
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.bookmark_rounded, color: Colors.white),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                title: const Text(
                                  'Watchlist',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _watchlist.length,
                                    itemBuilder: (context, index) {
                                      final suggestionId = _watchlist[index];
                                      final suggestion = suggestions.firstWhere(
                                        (s) => s.id == suggestionId,
                                        orElse: () => suggestions.isNotEmpty 
                                          ? suggestions.first 
                                          : Suggestion(
                                              id: suggestionId,
                                              title: 'Unknown',
                                              description: 'Suggestion not found',
                                              category: 'Other',
                                              type: SuggestionType.cutExpense,
                                              priority: Priority.low,
                                              icon: Icons.info_outline,
                                              color: Colors.grey,
                                              actionSteps: [],
                                            ),
                                      );
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              suggestion.icon,
                                              color: suggestion.color,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                suggestion.title,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close_rounded, size: 18),
                                              onPressed: () {
                                                setState(() {
                                                  _watchlist.removeAt(index);
                                                });
                                                Navigator.of(context).pop();
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text(
                                      'Close',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE74C3C),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${_watchlist.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Filter Tabs
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cut Expenses', SuggestionType.cutExpense),
                    const SizedBox(width: 8),
                    _buildFilterChip('Increase Income', SuggestionType.increaseIncome),
                    const SizedBox(width: 8),
                    _buildFilterChip('Investments', SuggestionType.invest),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: filteredSuggestions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No suggestions available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFilter == null
                                ? 'Add transactions to see personalized suggestions'
                                : 'No ${_getFilterLabel(_selectedFilter!)} suggestions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = filteredSuggestions[index];
                        return _buildSuggestionCard(suggestion);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, SuggestionType? filter) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? filter : null;
        });
      },
      selectedColor: const Color(0xFF4A90E2),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _getFilterLabel(SuggestionType type) {
    switch (type) {
      case SuggestionType.cutExpense:
        return 'cut expense';
      case SuggestionType.increaseIncome:
        return 'increase income';
      case SuggestionType.invest:
        return 'investment';
    }
  }

  Widget _buildSuggestionCard(Suggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewSuggestionDetails(suggestion),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: suggestion.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    suggestion.icon,
                    color: suggestion.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              suggestion.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (_watchlist.contains(suggestion.id))
                            const Icon(
                              Icons.bookmark_rounded,
                              color: Color(0xFF4A90E2),
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(suggestion.priority).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getPriorityText(suggestion.priority),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getPriorityColor(suggestion.priority),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            suggestion.category,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              suggestion.description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Savings/Gain
            if (suggestion.potentialSavings != null || suggestion.potentialGain != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: suggestion.type == SuggestionType.cutExpense
                      ? const Color(0xFF27AE60).withOpacity(0.1)
                      : const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      suggestion.type == SuggestionType.cutExpense
                          ? Icons.savings_rounded
                          : Icons.trending_up_rounded,
                      color: suggestion.type == SuggestionType.cutExpense
                          ? const Color(0xFF27AE60)
                          : const Color(0xFF4A90E2),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      suggestion.type == SuggestionType.cutExpense
                          ? 'Save up to ${CurrencyFormatter.format(suggestion.potentialSavings ?? 0, ref.read(currencyProvider))}/month'
                          : 'Potential gain: ${CurrencyFormatter.format(suggestion.potentialGain ?? 0, ref.read(currencyProvider))}/month',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: suggestion.type == SuggestionType.cutExpense
                            ? const Color(0xFF27AE60)
                            : const Color(0xFF4A90E2),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Action Steps Preview
            Text(
              '${suggestion.actionSteps.length} action steps',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _viewSuggestionDetails(suggestion),
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: suggestion.color.withOpacity(0.5),
                    width: 1.5,
                  ),
                  foregroundColor: suggestion.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
