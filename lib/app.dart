import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'config/theme.dart';
import 'database/database_helper.dart';
import 'providers/transaction_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaction_list_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/scan_slip_screen.dart';
import 'screens/settings_screen.dart';

class SlipDApp extends StatelessWidget {
  const SlipDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'slipD',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;
  bool _hasNewGalleryItems = false;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionListScreen(),
    SizedBox(), // placeholder for FAB
    ScanSlipScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();
    _checkNewGalleryItems();
  }

  Future<void> _checkNewGalleryItems() async {
    try {
      final state = await PhotoManager.requestPermissionExtend();
      if (state == PermissionState.authorized || state == PermissionState.limited) {
        final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          onlyAll: true,
        );
        if (albums.isNotEmpty) {
          final List<AssetEntity> assets = await albums.first.getAssetListRange(
            start: 0,
            end: 50,
          );
          if (assets.isNotEmpty) {
            final assetIds = assets.map((a) => a.id).toList();
            final db = DatabaseHelper();
            final processed = await db.getProcessedAssetIds(assetIds);
            final newCount = assetIds.where((id) => !processed.contains(id)).length;
            if (newCount > 0) {
              setState(() {
                _hasNewGalleryItems = true;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking new gallery items: $e');
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceBg,
          border: Border(
            top: BorderSide(color: AppTheme.borderColor, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'หน้าหลัก'),
                _navItem(1, Icons.receipt_long_outlined, Icons.receipt_long, 'รายการ'),
                _fabButton(),
                _navItem(3, Icons.document_scanner_outlined, Icons.document_scanner, 'สแกน'),
                _navItem(4, Icons.settings_outlined, Icons.settings, 'ตั้งค่า'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    final showBadge = index == 3 && _hasNewGalleryItems;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          if (index == 3) {
            _hasNewGalleryItems = false;
          }
        });
        _fabController.reset();
        _fabController.forward();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppTheme.primaryGreen : AppTheme.textMuted,
                  size: 22,
                ),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryGreen : AppTheme.textMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fabButton() {
    return ScaleTransition(
      scale: _fabScale,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const AddTransactionScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        },
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
