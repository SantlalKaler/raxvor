import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/profile/profile_controller.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final walletController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserProfile();
  }

  getUserProfile() {
    final uid = ref.read(authControllerProvider).currentUser?.uid;
    if (uid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileControllerProvider.notifier).loadProfile(uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),
      body: profileState.when(
        data: (data) {
          if (data == null) {
            return const Center(child: Text("No data found"));
          }

          walletController.text = data['wallet_balance']?.toString() ?? '0.0';

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Wallet Balance",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹${data['wallet_balance'] ?? 0}",
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                const Text(
                  "Recent Transactions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),

                ..._dummyTransactions.map((tx) {
                  final isCredit = tx['type'] == 'credit';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 1.5,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCredit ? Colors.green : Colors.red,
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(tx['title']!),
                      subtitle: Text(tx['time']!),
                      trailing: Text(
                        tx['amount']!,
                        style: TextStyle(
                          color: isCredit ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Something went wrong ${err}'),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  getUserProfile();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Retry!"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 30,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _dummyTransactions = [
  {
    "title": "Audio Room Join Bonus",
    "amount": "+₹50",
    "time": "Today, 10:30 AM",
    "type": "credit",
  },
  {
    "title": "Gift Sent to @ankit",
    "amount": "-₹20",
    "time": "Yesterday, 08:10 PM",
    "type": "debit",
  },
  {
    "title": "Daily Login Reward",
    "amount": "+₹10",
    "time": "12 Oct, 09:00 AM",
    "type": "credit",
  },
];
