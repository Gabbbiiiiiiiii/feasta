import 'package:flutter/material.dart';

import '../../core/helpers/provider_category_helper.dart';
import '../../models/feasta_models.dart';
import '../../repositories/feasta_repository.dart';
import '../notifications/notifications_screen.dart';
import 'customer_search_screen.dart';
import 'provider_profile_screen.dart';
import '../../core/helpers/auth_guard.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final FeastaRepository _repository = FeastaRepository();

  String selectedEventType = 'All';
  bool nearOrmocOnly = false;
  bool rating4PlusOnly = false;
  bool budgetFriendlyOnly = false;

  final List<_HomeCategoryItem> categories = const [
  _HomeCategoryItem('All', Icons.apps_outlined),
  _HomeCategoryItem('Wedding', Icons.favorite_border),
  _HomeCategoryItem('Birthday', Icons.cake_outlined),
  _HomeCategoryItem('Corporate', Icons.business_center_outlined),
  _HomeCategoryItem('Graduation', Icons.school_outlined),
  _HomeCategoryItem('Baptism', Icons.child_care_outlined),
  _HomeCategoryItem('Reunion', Icons.groups_outlined),
  _HomeCategoryItem('Anniversary', Icons.celebration_outlined),
  _HomeCategoryItem('Other', Icons.more_horiz),
];

  final List<_HomeFilterItem> filters = const [
    _HomeFilterItem('All', Icons.tune),
    _HomeFilterItem('Near Ormoc', Icons.location_on_outlined),
    _HomeFilterItem('Ratings 4.0+', Icons.star),
    _HomeFilterItem('Budget Friendly', Icons.sell_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(repository: _repository),
            ),

            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 86,
              flexibleSpace: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _HomeSearchBar(),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _CategoryShortcutSection(
                categories: categories,
                selectedEventType: selectedEventType,
                onSelected: (eventType) {
                  setState(() {
                    selectedEventType = eventType;
                  });
                },
              ),
            ),

            SliverToBoxAdapter(
              child: _FilterChipSection(
                filters: filters,
                nearOrmocOnly: nearOrmocOnly,
                rating4PlusOnly: rating4PlusOnly,
                budgetFriendlyOnly: budgetFriendlyOnly,
                onFilterTap: (filterLabel) {
                  setState(() {
                    if (filterLabel == 'All') {
                      selectedEventType = 'All';
                      nearOrmocOnly = false;
                      rating4PlusOnly = false;
                      budgetFriendlyOnly = false;
                    } else if (filterLabel == 'Near Ormoc') {
                      nearOrmocOnly = !nearOrmocOnly;
                    } else if (filterLabel == 'Ratings 4.0+') {
                      rating4PlusOnly = !rating4PlusOnly;
                    } else if (filterLabel == 'Budget Friendly') {
                      budgetFriendlyOnly = !budgetFriendlyOnly;
                    }
                  });
                },
              ),
            ),

            SliverToBoxAdapter(
              child: _BookAgainSection(repository: _repository),
            ),

            SliverToBoxAdapter(
              child: _ProviderHorizontalSection(
                title: selectedEventType == 'All'
                    ? 'Popular Caterers'
                    : '$selectedEventType Caterers',
                subtitle: selectedEventType == 'All'
                    ? 'Catering providers customers often browse'
                    : 'Caterers with active $selectedEventType packages',
                stream: _repository.homeCateringProviders(
                eventType: selectedEventType,
                nearOrmoc: nearOrmocOnly,
                rating4Plus: rating4PlusOnly,
                budgetFriendly: budgetFriendlyOnly,
              ),
                emptyText: 'No verified caterers available yet.',
              ),
            ),

            SliverToBoxAdapter(
              child: _ProviderHorizontalSection(
                title: 'Event Services',
                subtitle: 'Photographers, coordinators, singers, rentals, and more',
                stream: _repository.verifiedAddonProviders(),
                emptyText: 'No verified event service providers available yet.',
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 34),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final FeastaRepository repository;

  const _HomeHeader({
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuestUser) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hi, Guest!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                requireLogin(
                  context,
                  message:
                      'Please log in or create an account to view notifications.',
                );
              },
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: repository.currentUserData(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user == null ? 'Hi!' : 'Hi, ${user.firstName}!',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              StreamBuilder(
                stream: repository.myNotifications(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  final unreadCount = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['isRead'] == false;
                  }).length;

                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6333);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerSearchScreen(
              autofocusSearch: true,
            ),
          ),
        );
      },
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primary.withOpacity(0.35),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.search,
              color: primary,
              size: 26,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search caterers, packages, and event services',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.tune,
              color: Colors.grey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryShortcutSection extends StatelessWidget {
  final List<_HomeCategoryItem> categories;
  final String selectedEventType;
  final ValueChanged<String> onSelected;

  const _CategoryShortcutSection({
    required this.categories,
    required this.selectedEventType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6333);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedEventType == category.label;

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelected(category.label),
            child: Column(
              children: [
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primary
                        : primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    category.icon,
                    color: isSelected ? Colors.white : primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? primary : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChipSection extends StatelessWidget {
  final List<_HomeFilterItem> filters;
  final bool nearOrmocOnly;
  final bool rating4PlusOnly;
  final bool budgetFriendlyOnly;
  final ValueChanged<String> onFilterTap;

  const _FilterChipSection({
    required this.filters,
    required this.nearOrmocOnly,
    required this.rating4PlusOnly,
    required this.budgetFriendlyOnly,
    required this.onFilterTap,
  });

  bool _isSelected(String label) {
    if (label == 'Near Ormoc') return nearOrmocOnly;
    if (label == 'Ratings 4.0+') return rating4PlusOnly;
    if (label == 'Budget Friendly') return budgetFriendlyOnly;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6333);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = _isSelected(filter.label);

            return OutlinedButton.icon(
              onPressed: () => onFilterTap(filter.label),
              icon: Icon(filter.icon, size: 18),
              label: Text(
                filter.label == 'All' ? 'Reset' : filter.label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    isSelected ? primary.withOpacity(0.10) : Colors.white,
                foregroundColor: isSelected ? primary : Colors.black87,
                side: BorderSide(
                  color: isSelected ? primary : const Color(0xFFD6D6D6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BookAgainSection extends StatelessWidget {
  final FeastaRepository repository;

  const _BookAgainSection({
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuestUser) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<List<BookingModel>>(
      stream: repository.customerCompletedBookings(),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (bookings.isEmpty) {
          return const SizedBox.shrink();
        }

        final recentBookings = bookings.take(5).toList();

        return Container(
          margin: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                title: 'Book Again',
                subtitle: 'Quickly rebook providers you used before',
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: recentBookings.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final booking = recentBookings[index];

                    return _BookAgainCard(booking: booking);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookAgainCard extends StatelessWidget {
  final BookingModel booking;

  const _BookAgainCard({
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6333);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.providerBusinessName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            booking.packageName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                // Later we can route this to provider profile or duplicate booking flow.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Book Again',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderHorizontalSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Stream<List<ProviderModel>> stream;
  final String emptyText;

  const _ProviderHorizontalSection({
    required this.title,
    required this.subtitle,
    required this.stream,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProviderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        final providers = snapshot.data ?? [];

        return Container(
          margin: const EdgeInsets.only(top: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: title,
                subtitle: subtitle,
              ),
              const SizedBox(height: 14),

              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 225,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (providers.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    emptyText,
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              else
                SizedBox(
                  height: 235,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    scrollDirection: Axis.horizontal,
                    itemCount: providers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      return _HorizontalProviderCard(
                        provider: providers[index],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _HorizontalProviderCard extends StatelessWidget {
  final ProviderModel provider;

  const _HorizontalProviderCard({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF6333);
    final imageUrl = provider.coverImageUrl ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfileScreen(provider: provider),
          ),
        );
      },
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageUrl.isEmpty
              ? Container(
                  height: 85,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                )
              : Image.network(
                  imageUrl,
                  height: 85,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 85,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
            Padding(
              padding: const EdgeInsets.all(10),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (provider.isVerified)
                        const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 17,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      providerCategoryLabel(provider.providerCategory),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${provider.ratingAverage.toStringAsFixed(1)} (${provider.reviewCount})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '₱${provider.minPrice.toStringAsFixed(0)} - ₱${provider.maxPrice.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          provider.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCategoryItem {
  final String label;
  final IconData icon;

  const _HomeCategoryItem(this.label, this.icon);
}

class _HomeFilterItem {
  final String label;
  final IconData icon;

  const _HomeFilterItem(this.label, this.icon);
}