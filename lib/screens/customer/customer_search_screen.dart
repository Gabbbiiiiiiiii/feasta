import 'package:flutter/material.dart';

import '../../models/feasta_models.dart';
import '../../repositories/feasta_repository.dart';
import 'provider_profile_screen.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final FeastaRepository repository = FeastaRepository();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController minBudgetController = TextEditingController();
  final TextEditingController maxBudgetController = TextEditingController();

  String selectedEventType = 'All';
  bool showFilters = true;

  final List<String> eventTypes = const [
    'All',
    'Birthday',
    'Wedding',
    'Anniversary',
    'Reunion',
    'Corporate',
    'Baptism',
    'Graduation',
    'Other',
  ];

  double? get minBudget {
    final value = minBudgetController.text.trim();
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  double? get maxBudget {
    final value = maxBudgetController.text.trim();
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  void _refreshSearch() {
    setState(() {});
  }

  void _clearFilters() {
    setState(() {
      searchController.clear();
      locationController.clear();
      minBudgetController.clear();
      maxBudgetController.clear();
      selectedEventType = 'All';
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    locationController.dispose();
    minBudgetController.dispose();
    maxBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6333);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Search Caterers',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  showFilters = !showFilters;
                });
              },
              icon: Icon(
                showFilters
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (_) => _refreshSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search catering providers',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                searchController.clear();
                                _refreshSearch();
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  if (showFilters) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedEventType,
                      decoration: const InputDecoration(
                        labelText: 'Event Type',
                      ),
                      items: eventTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedEventType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: locationController,
                      onChanged: (_) => _refreshSearch(),
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Example: Ormoc City',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minBudgetController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _refreshSearch(),
                            decoration: const InputDecoration(
                              labelText: 'Min Budget',
                              hintText: '15000',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxBudgetController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _refreshSearch(),
                            decoration: const InputDecoration(
                              labelText: 'Max Budget',
                              hintText: '50000',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearFilters,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text(
                              'Clear',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              _refreshSearch();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ProviderModel>>(
                stream: repository.searchVerifiedProviders(
                  keyword: searchController.text,
                  eventType: selectedEventType,
                  location: locationController.text,
                  minBudget: minBudget,
                  maxBudget: maxBudget,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final providers = snapshot.data ?? [];

                  if (providers.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 18),
                            Text(
                              'No results found',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try changing your search keyword or filters.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: providers.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Text(
                          '${providers.length} provider${providers.length == 1 ? '' : 's'} found',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }

                      final provider = providers[index - 1];

                      return SearchProviderCard(provider: provider);
                    },
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

class SearchProviderCard extends StatelessWidget {
  final ProviderModel provider;

  const SearchProviderCard({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6333);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(provider: provider),
          ),
        );
      },
      child: Container(
        height: 145,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            provider.coverImageUrl == null || provider.coverImageUrl!.isEmpty
                ? Container(
                    width: 130,
                    height: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_outlined,
                      color: Colors.grey,
                      size: 42,
                    ),
                  )
                : Image.network(
                    provider.coverImageUrl!,
                    width: 130,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 130,
                        height: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (provider.isVerified)
                          const Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${provider.ratingAverage.toStringAsFixed(1)} (${provider.reviewCount})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${provider.minPrice.toStringAsFixed(0)} - ₱${provider.maxPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey,
                          size: 17,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            provider.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}