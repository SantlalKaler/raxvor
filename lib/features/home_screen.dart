import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:raxvor/app/images.dart';
import 'package:raxvor/features/profile/profile_screen.dart';
import 'package:raxvor/features/wallet/wallet_screen.dart';

import '../app/app_routes.dart';
import 'auth/auth_controller.dart';
import 'home/chat_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    ChatListScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = ref.read(authControllerProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.deepPurple,
              elevation: 0,
              leading: Image.asset(ImageConst.logo, height: 30, width: 30),
              title: const Text(
                'Raxvor',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await authController.logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User logged out.")),
                    );
                    if (mounted) context.go(AppRoutes.login);
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: _screens[_selectedIndex],
      /* floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              onPressed: () {
                context.push(AppRoutes.chatroom);
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,*/
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none),
            label: 'Chatrooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
