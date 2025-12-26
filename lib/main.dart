import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

// ==================== MAIN ====================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ziovzwhjkccapjbmmwpa.supabase.co',
    anonKey: 'sb_publishable_2QU4EA2CFxOUGmaIrryBiw_nflgdRz3',
  );

  runApp(const AnimeShopApp());
}

// ==================== COLORS ====================

class SAOColors {
  static const Color neonCyan = Color(0xFF00D4FF);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonPink = Color(0xFFFF6B9D);
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color cardBg = Color(0xFF12121A);
  static const Color cardBgLight = Color(0xFF1A1A25);
}

// ==================== PRODUCT MODEL ====================

class Product {
  final int id;
  final String name;
  final int price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'] as int,
      imageUrl: json['image_url'] as String,
    );
  }
}

// ==================== DATA FETCHING ====================

Future<List<Product>> fetchProducts() async {
  final response = await Supabase.instance.client.from('products').select();
  final List<dynamic> data = response as List<dynamic>;
  return data
      .map((json) => Product.fromJson(json as Map<String, dynamic>))
      .toList();
}

// ==================== APP ====================

class AnimeShopApp extends StatelessWidget {
  const AnimeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SAOColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: SAOColors.neonCyan,
          secondary: SAOColors.neonPurple,
          surface: SAOColors.darkBg,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// ==================== MAIN SCREEN ====================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// Global cart state (simple approach)
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get totalPrice => product.price * quantity;
}

class CartState {
  static final List<CartItem> items = [];

  static void addItem(Product product, int quantity) {
    final existingIndex = items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      items[existingIndex].quantity += quantity;
    } else {
      items.add(CartItem(product: product, quantity: quantity));
    }
  }

  static void removeItem(int productId) {
    items.removeWhere((item) => item.product.id == productId);
  }

  static void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      items[index].quantity = quantity;
    }
  }

  static int get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);
  static int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  static void clear() => items.clear();
}

// Global wishlist state
class WishlistState {
  static final List<Product> items = [];

  static void toggle(Product product) {
    if (contains(product.id)) {
      items.removeWhere((p) => p.id == product.id);
    } else {
      items.add(product);
    }
  }

  static bool contains(int productId) {
    return items.any((p) => p.id == productId);
  }

  static void remove(int productId) {
    items.removeWhere((p) => p.id == productId);
  }

  static int get count => items.length;
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late Future<List<Product>> _productsFuture;
  late AnimationController _glowController;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = fetchProducts();
    });
  }

  void _refreshCart() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SAOColors.darkBg,
              Color(0xFF0D0D15),
              Color(0xFF101018),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            const Positioned.fill(child: ParticleBackground()),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildCurrentPage()),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: const [
                              SAOColors.neonCyan,
                              SAOColors.neonPurple,
                              SAOColors.neonCyan,
                            ],
                            stops: [0.0, _glowController.value, 1.0],
                          ).createShader(bounds),
                          child: const Text(
                            'ANIME SHOP',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: SAOColors.neonCyan,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: SAOColors.neonCyan.withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LINK START',
                          style: TextStyle(
                            fontSize: 10,
                            color: SAOColors.neonCyan.withValues(alpha: 0.7),
                            letterSpacing: 2,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildHeaderButton(Icons.search, () {}),
              const SizedBox(width: 8),
              _buildHeaderButton(Icons.refresh, _refreshProducts),
            ],
          ),
          const SizedBox(height: 16),
          // Glowing divider
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  SAOColors.neonCyan.withValues(alpha: 0.6),
                  SAOColors.neonPurple.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: SAOColors.neonCyan.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SAOColors.neonCyan.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: SAOColors.neonCyan.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: SAOColors.cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: SAOColors.neonCyan, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedNavIndex) {
      case 1:
        return _buildWishlistPage();
      case 2:
        return CartPage(onUpdate: _refreshCart);
      case 3:
        return const ProfilePage();
      default:
        return _buildBody();
    }
  }

  Widget _buildWishlistPage() {
    if (WishlistState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: SAOColors.neonPink.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(color: SAOColors.neonPink.withValues(alpha: 0.2), blurRadius: 30),
                ],
              ),
              child: Icon(Icons.favorite_rounded, size: 64, color: SAOColors.neonPink.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            const Text(
              'WISHLIST EMPTY',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart on items to save them',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: WishlistState.items.length,
      itemBuilder: (context, index) {
        return _ProductCard(
          product: WishlistState.items[index],
          index: index,
          onTap: () => _openProductDetails(WishlistState.items[index]),
          onWishlistChanged: () => setState(() {}),
        );
      },
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }
        return _buildProductsGrid(snapshot.data!);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SAOColors.neonCyan.withValues(
                            alpha: 0.3 + (_glowController.value * 0.4),
                          ),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SAOColors.neonCyan.withValues(
                              alpha: 0.3 + (_glowController.value * 0.3),
                            ),
                            blurRadius: 20 + (_glowController.value * 10),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const CircularProgressIndicator(
                  color: SAOColors.neonCyan,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [SAOColors.neonCyan, SAOColors.neonPurple],
            ).createShader(bounds),
            child: const Text(
              'LOADING DATA...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 4,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: SAOColors.neonPink.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: SAOColors.neonPink.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.warning_amber_rounded, color: SAOColors.neonPink, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'CONNECTION ERROR',
              style: TextStyle(
                color: SAOColors.neonPink,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildGlowingButton('RETRY', SAOColors.neonPink, _refreshProducts),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: SAOColors.neonCyan.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 24),
          Text(
            'NO PRODUCTS FOUND',
            style: TextStyle(
              color: SAOColors.neonCyan.withValues(alpha: 0.7),
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingButton(String text, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 0),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.2),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _ProductCard(
          product: products[index],
          index: index,
          onTap: () => _openProductDetails(products[index]),
          onWishlistChanged: () => setState(() {}),
        );
      },
    );
  }

  void _openProductDetails(Product product) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductDetailsScreen(product: product),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: SAOColors.cardBg,
        border: Border(
          top: BorderSide(color: SAOColors.neonCyan.withValues(alpha: 0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: SAOColors.neonCyan.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0, null),
              _buildNavItem(Icons.favorite_rounded, 'Wishlist', 1, null),
              _buildNavItem(Icons.shopping_bag_rounded, 'Cart', 2, CartState.itemCount > 0 ? CartState.itemCount : null),
              _buildNavItem(Icons.person_rounded, 'Profile', 3, null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, int? badge) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SAOColors.neonCyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.4), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? SAOColors.neonCyan : Colors.white.withValues(alpha: 0.5),
                  size: 24,
                ),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: SAOColors.neonPink,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: SAOColors.neonPink.withValues(alpha: 0.6), blurRadius: 8),
                        ],
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? SAOColors.neonCyan : Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PRODUCT CARD ====================

class _ProductCard extends StatefulWidget {
  final Product product;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onWishlistChanged;

  const _ProductCard({
    required this.product,
    required this.index,
    required this.onTap,
    this.onWishlistChanged,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  bool get _isInWishlist => WishlistState.contains(widget.product.id);

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _toggleWishlist() {
    WishlistState.toggle(widget.product);
    setState(() {});
    widget.onWishlistChanged?.call();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isInWishlist 
                    ? 'Added to wishlist!' 
                    : 'Removed from wishlist',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: SAOColors.neonPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 0.97 : 1.0),
          decoration: BoxDecoration(
            color: SAOColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? SAOColors.neonCyan.withValues(alpha: 0.8)
                  : SAOColors.neonCyan.withValues(alpha: 0.25),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? SAOColors.neonCyan.withValues(alpha: 0.3)
                    : SAOColors.neonCyan.withValues(alpha: 0.1),
                blurRadius: _isHovered ? 25 : 15,
                spreadRadius: _isHovered ? 2 : 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Hexagon pattern overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: HexagonPatternPainter(
                      color: SAOColors.neonCyan.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image section
                    Expanded(
                      flex: 5,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Product image
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  SAOColors.cardBgLight,
                                  SAOColors.cardBg,
                                ],
                              ),
                            ),
                            child: Image.network(
                              widget.product.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: SAOColors.neonCyan.withValues(alpha: 0.5),
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: SAOColors.neonCyan.withValues(alpha: 0.3),
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),
                          // Gradient overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    SAOColors.cardBg.withValues(alpha: 0.9),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Wishlist button
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: _toggleWishlist,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isInWishlist 
                                      ? SAOColors.neonPink.withValues(alpha: 0.3)
                                      : SAOColors.darkBg.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: SAOColors.neonPink.withValues(alpha: _isInWishlist ? 0.8 : 0.4),
                                    width: 1,
                                  ),
                                  boxShadow: _isInWishlist ? [
                                    BoxShadow(
                                      color: SAOColors.neonPink.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ] : null,
                                ),
                                child: Icon(
                                  _isInWishlist ? Icons.favorite : Icons.favorite_border,
                                  color: SAOColors.neonPink,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Info section
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Price with yen symbol style
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [SAOColors.neonCyan, SAOColors.neonPurple],
                                ).createShader(bounds),
                                child: Text(
                                  '¥${widget.product.price}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              // Add to cart button
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [SAOColors.neonCyan, SAOColors.neonPurple],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SAOColors.neonCyan.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== PRODUCT DETAILS SCREEN ====================

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SAOColors.darkBg, Color(0xFF0D0D15), Color(0xFF101018)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: ParticleBackground()),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageSection(),
                          _buildProductInfo(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: SAOColors.neonCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.4), width: 1),
            ),
            child: const Text(
              'PRODUCT DETAILS',
              style: TextStyle(
                color: SAOColors.neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          _buildCircleButton(Icons.share_rounded, () {}),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: SAOColors.neonCyan.withValues(alpha: 0.2), blurRadius: 12),
        ],
      ),
      child: Material(
        color: SAOColors.cardBg.withValues(alpha: 0.8),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: SAOColors.neonCyan, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: SAOColors.neonCyan.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        SAOColors.cardBgLight,
                        SAOColors.cardBg,
                      ],
                    ),
                  ),
                ),
                // Product image
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: SAOColors.neonCyan.withValues(alpha: 0.3),
                          size: 60,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // Description below image
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Premium collectible featuring high-quality details and authentic design. Perfect for anime enthusiasts and collectors.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: SAOColors.cardBg.withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: SAOColors.neonCyan.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(
            widget.product.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Price and quantity row
          Row(
            children: [
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [SAOColors.neonCyan, SAOColors.neonPurple],
                  ).createShader(bounds),
                  child: Text(
                    '¥${widget.product.price}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              // Quantity selector
              Container(
                decoration: BoxDecoration(
                  color: SAOColors.darkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQtyButton(Icons.remove, () {
                      if (_quantity > 1) setState(() => _quantity--);
                    }),
                    Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildQtyButton(Icons.add, () => setState(() => _quantity++)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Features
          _buildFeatures(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: SAOColors.neonCyan, size: 20),
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      (Icons.verified_outlined, 'Authentic'),
      (Icons.local_shipping_outlined, 'Free Shipping'),
      (Icons.refresh, '30-Day Return'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: features.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: SAOColors.darkBg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            children: [
              Icon(f.$1, color: SAOColors.neonCyan, size: 24),
              const SizedBox(height: 6),
              Text(
                f.$2,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    final total = widget.product.price * _quantity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SAOColors.cardBg,
        border: Border(top: BorderSide(color: SAOColors.neonCyan.withValues(alpha: 0.3), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Total
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [SAOColors.neonCyan, SAOColors.neonPurple],
                  ).createShader(bounds),
                  child: Text(
                    '¥$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Add to cart button
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SAOColors.neonCyan, SAOColors.neonPurple],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: SAOColors.neonCyan.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      CartState.addItem(widget.product, _quantity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Added to cart!',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: SAOColors.neonCyan,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ADD TO CART',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CART PAGE ====================

class CartPage extends StatefulWidget {
  final VoidCallback onUpdate;

  const CartPage({super.key, required this.onUpdate});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    if (CartState.items.isEmpty) {
      return _buildEmptyCart();
    }
    return Column(
      children: [
        Expanded(child: _buildCartList()),
        _buildCheckoutSection(),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(color: SAOColors.neonCyan.withValues(alpha: 0.2), blurRadius: 30),
              ],
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: SAOColors.neonCyan.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'YOUR CART IS EMPTY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add some awesome items!',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: CartState.items.length,
      itemBuilder: (context, index) {
        final item = CartState.items[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 80)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _buildCartItem(item),
        );
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Dismissible(
      key: Key('${item.product.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        CartState.removeItem(item.product.id);
        widget.onUpdate();
        setState(() {});
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [SAOColors.neonPink.withValues(alpha: 0.5), SAOColors.neonPink],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: SAOColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: SAOColors.neonCyan.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.2), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    item.product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_not_supported,
                      color: SAOColors.neonCyan.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [SAOColors.neonCyan, SAOColors.neonPurple],
                      ).createShader(bounds),
                      child: Text(
                        '¥${item.totalPrice}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  color: SAOColors.darkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  children: [
                    _buildQtyButton(Icons.add, () {
                      CartState.updateQuantity(item.product.id, item.quantity + 1);
                      widget.onUpdate();
                      setState(() {});
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildQtyButton(Icons.remove, () {
                      CartState.updateQuantity(item.product.id, item.quantity - 1);
                      widget.onUpdate();
                      setState(() {});
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: SAOColors.neonCyan, size: 18),
        ),
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SAOColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: SAOColors.neonCyan.withValues(alpha: 0.3), width: 1)),
        boxShadow: [
          BoxShadow(
            color: SAOColors.neonCyan.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Summary rows
            _buildSummaryRow('Subtotal', '¥${CartState.totalPrice}'),
            const SizedBox(height: 8),
            _buildSummaryRow('Shipping', 'FREE', isHighlight: true),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: SAOColors.neonCyan.withValues(alpha: 0.2)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [SAOColors.neonCyan, SAOColors.neonPurple],
                  ).createShader(bounds),
                  child: Text(
                    '¥${CartState.totalPrice}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Checkout button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SAOColors.neonCyan, SAOColors.neonPurple],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: SAOColors.neonCyan.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.rocket_launch, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Processing checkout...', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        backgroundColor: SAOColors.neonPurple,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'CHECKOUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? const Color(0xFF4CAF50) : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ==================== PROFILE PAGE ====================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [SAOColors.neonCyan, SAOColors.neonPurple],
              ),
              boxShadow: [
                BoxShadow(
                  color: SAOColors.neonCyan.withValues(alpha: 0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: SAOColors.cardBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 64, color: SAOColors.neonCyan),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'PLAYER ONE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: SAOColors.neonCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              'Level 99 Collector',
              style: TextStyle(
                color: SAOColors.neonCyan.withValues(alpha: 0.8),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('ORDERS', '12', Icons.local_shipping_outlined),
              _buildStatCard('WISHLIST', '8', Icons.favorite_outline),
              _buildStatCard('REVIEWS', '24', Icons.star_outline),
            ],
          ),
          const SizedBox(height: 32),
          // Menu items
          _buildMenuItem(Icons.shopping_bag_outlined, 'My Orders', () {}),
          _buildMenuItem(Icons.location_on_outlined, 'Addresses', () {}),
          _buildMenuItem(Icons.payment_outlined, 'Payment Methods', () {}),
          _buildMenuItem(Icons.notifications_outlined, 'Notifications', () {}),
          _buildMenuItem(Icons.help_outline, 'Help & Support', () {}),
          _buildMenuItem(Icons.settings_outlined, 'Settings', () {}),
          const SizedBox(height: 20),
          // Logout button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SAOColors.neonPink.withValues(alpha: 0.5), width: 1.5),
            ),
            child: Material(
              color: SAOColors.neonPink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: SAOColors.neonPink, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'LOG OUT',
                      style: TextStyle(
                        color: SAOColors.neonPink,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: SAOColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: SAOColors.neonCyan, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SAOColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SAOColors.neonCyan.withValues(alpha: 0.15), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SAOColors.neonCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: SAOColors.neonCyan, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== PARTICLE BACKGROUND ====================

class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    for (int i = 0; i < 30; i++) {
      _particles.add(Particle.random());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  double x, y, size, speed, opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  factory Particle.random() {
    final random = math.Random();
    return Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 3 + 1,
      speed: random.nextDouble() * 0.5 + 0.2,
      opacity: random.nextDouble() * 0.5 + 0.1,
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double time;

  ParticlePainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y + time * p.speed) % 1.0;
      final paint = Paint()
        ..color = SAOColors.neonCyan.withValues(alpha: p.opacity * (1 - y))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

// ==================== HEXAGON PATTERN PAINTER ====================

class HexagonPatternPainter extends CustomPainter {
  final Color color;

  HexagonPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const hexSize = 40.0;
    const hexHeight = hexSize * 0.866;

    for (double y = 0; y < size.height + hexHeight; y += hexHeight * 1.5) {
      for (double x = 0; x < size.width + hexSize; x += hexSize * 1.5) {
        final offsetX = (y ~/ (hexHeight * 1.5)) % 2 == 0 ? 0.0 : hexSize * 0.75;
        _drawHexagon(canvas, Offset(x + offsetX, y), hexSize * 0.4, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
