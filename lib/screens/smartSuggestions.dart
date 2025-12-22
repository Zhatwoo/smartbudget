import 'package:flutter/material.dart';

class SmartSuggestionsScreen extends StatefulWidget {
  const SmartSuggestionsScreen({super.key});

  @override
  State<SmartSuggestionsScreen> createState() => _SmartSuggestionsScreenState();
}

class _SmartSuggestionsScreenState extends State<SmartSuggestionsScreen> {
  final List<Suggestion> _suggestions = [
    Suggestion(
      id: '1',
      itemName: 'Rice',
      currentPrice: 55.00,
      currentStore: 'SM Supermarket',
      alternatives: [
        Alternative(
          storeName: 'Puregold',
          price: 52.00,
          distance: '2.5 km',
          address: '123 Main Street, Quezon City',
          savings: 3.00,
        ),
        Alternative(
          storeName: 'Robinsons',
          price: 53.50,
          distance: '1.8 km',
          address: '456 EDSA, Mandaluyong',
          savings: 1.50,
        ),
        Alternative(
          storeName: 'Metro Market',
          price: 51.00,
          distance: '3.2 km',
          address: '789 Ayala Avenue, Makati',
          savings: 4.00,
        ),
      ],
      icon: Icons.rice_bowl,
      color: const Color(0xFFE74C3C),
    ),
    Suggestion(
      id: '2',
      itemName: 'Milk',
      currentPrice: 85.00,
      currentStore: 'SM Supermarket',
      alternatives: [
        Alternative(
          storeName: 'Puregold',
          price: 82.00,
          distance: '2.5 km',
          address: '123 Main Street, Quezon City',
          savings: 3.00,
        ),
        Alternative(
          storeName: 'Metro Market',
          price: 80.00,
          distance: '3.2 km',
          address: '789 Ayala Avenue, Makati',
          savings: 5.00,
        ),
      ],
      icon: Icons.local_drink,
      color: const Color(0xFF4A90E2),
    ),
    Suggestion(
      id: '3',
      itemName: 'Eggs',
      currentPrice: 8.50,
      currentStore: 'SM Supermarket',
      alternatives: [
        Alternative(
          storeName: 'Robinsons',
          price: 8.00,
          distance: '1.8 km',
          address: '456 EDSA, Mandaluyong',
          savings: 0.50,
        ),
        Alternative(
          storeName: 'Puregold',
          price: 7.80,
          distance: '2.5 km',
          address: '123 Main Street, Quezon City',
          savings: 0.70,
        ),
      ],
      icon: Icons.egg,
      color: const Color(0xFFF39C12),
    ),
    Suggestion(
      id: '4',
      itemName: 'Gasoline',
      currentPrice: 65.50,
      currentStore: 'Shell Station',
      alternatives: [
        Alternative(
          storeName: 'Petron',
          price: 64.00,
          distance: '1.2 km',
          address: '321 Ortigas Avenue, Pasig',
          savings: 1.50,
        ),
        Alternative(
          storeName: 'Caltex',
          price: 63.50,
          distance: '2.1 km',
          address: '654 Shaw Boulevard, Mandaluyong',
          savings: 2.00,
        ),
      ],
      icon: Icons.local_gas_station,
      color: const Color(0xFF27AE60),
    ),
  ];

  final List<String> _watchlist = [];

  void _addToWatchlist(String itemName) {
    setState(() {
      if (!_watchlist.contains(itemName)) {
        _watchlist.add(itemName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName added to watchlist'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _watchlist.remove(itemName);
                });
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName is already in watchlist')),
        );
      }
    });
  }

  void _removeFromWatchlist(String itemName) {
    setState(() {
      _watchlist.remove(itemName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$itemName removed from watchlist')),
      );
    });
  }

  void _openMap(Alternative alternative) {
    // TODO: Open map with store location
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alternative.storeName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${alternative.address}'),
            const SizedBox(height: 8),
            Text('Distance: ${alternative.distance}'),
            const SizedBox(height: 8),
            Text('Price: ₱${alternative.price.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              'You save: ₱${alternative.savings.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Open actual map application
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening map to ${alternative.storeName}...')),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('Open Map'),
          ),
        ],
      ),
    );
  }

  void _viewStoreInfo(Alternative alternative, Suggestion suggestion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alternative.storeName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion.itemName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Price Comparison
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Store',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${suggestion.currentPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          Text(
                            suggestion.currentStore,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Alternative',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${alternative.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          Text(
                            alternative.storeName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.savings,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'You save ₱${alternative.savings.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Store Details
            _buildDetailRow(Icons.location_on, 'Address', alternative.address),
            _buildDetailRow(Icons.straighten, 'Distance', alternative.distance),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openMap(alternative);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Open Map'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _addToWatchlist(suggestion.itemName);
                    },
                    icon: Icon(
                      _watchlist.contains(suggestion.itemName)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                    label: Text(
                      _watchlist.contains(suggestion.itemName)
                          ? 'In Watchlist'
                          : 'Add to Watchlist',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back Button and Watchlist
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  if (_watchlist.isNotEmpty)
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.bookmark, color: Colors.grey),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Watchlist'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _watchlist.length,
                                    itemBuilder: (context, index) {
                                      final item = _watchlist[index];
                                      return ListTile(
                                        title: Text(item),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            setState(() {
                                              _watchlist.removeAt(index);
                                            });
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
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
                              color: Colors.red,
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
            Expanded(
              child: _suggestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No suggestions available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                final bestAlternative = suggestion.alternatives.reduce(
                  (a, b) => a.price < b.price ? a : b,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: suggestion.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                suggestion.icon,
                                color: suggestion.color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          suggestion.itemName,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (_watchlist.contains(suggestion.itemName))
                                        Icon(
                                          Icons.bookmark,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Currently at ${suggestion.currentStore}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price Comparison
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Price',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₱${suggestion.currentPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Best Alternative',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₱${bestAlternative.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.savings,
                                      color: Theme.of(context).colorScheme.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Save up to ₱${bestAlternative.savings.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Alternatives List
                        Text(
                          'Cheaper Alternatives (${suggestion.alternatives.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...suggestion.alternatives.map((alternative) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _viewStoreInfo(alternative, suggestion),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              alternative.storeName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                            if (alternative.price == bestAlternative.price)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'BEST',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              alternative.distance,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₱${alternative.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                      Text(
                                        'Save ₱${alternative.savings.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.map_outlined),
                                    onPressed: () => _openMap(alternative),
                                    tooltip: 'Open Map',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        // Action Buttons
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _addToWatchlist(suggestion.itemName),
                                icon: Icon(
                                  _watchlist.contains(suggestion.itemName)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                ),
                                label: Text(
                                  _watchlist.contains(suggestion.itemName)
                                      ? 'In Watchlist'
                                      : 'Add to Watchlist',
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
              ),
            ],
          ),
        ),
      );    
  }
}

// Models
class Suggestion {
  final String id;
  final String itemName;
  final double currentPrice;
  final String currentStore;
  final List<Alternative> alternatives;
  final IconData icon;
  final Color color;

  Suggestion({
    required this.id,
    required this.itemName,
    required this.currentPrice,
    required this.currentStore,
    required this.alternatives,
    required this.icon,
    required this.color,
  });
}

class Alternative {
  final String storeName;
  final double price;
  final String distance;
  final String address;
  final double savings;

  Alternative({
    required this.storeName,
    required this.price,
    required this.distance,
    required this.address,
    required this.savings,
  });
}

