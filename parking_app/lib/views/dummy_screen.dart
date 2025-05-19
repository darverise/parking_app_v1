import 'package:flutter/material.dart';
import 'package:parking_app/views/parking/parking_search_screen.dart';
import 'package:parking_app/views/auth/home_screen.dart';
import 'package:parking_app/core/models/auth_signin_model.dart';

class DummyScreen extends StatelessWidget {
  const DummyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dummy UI 画面')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'XXXXXXXXXX',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ParkingSearchScreen(),
                  ),
                );
              },
              child: const Text('駐車場検索画面へ'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 要件に合わせて修正されたAuthUserModelの作成
                final dummyUser = AuthUserModel(
                  id: 'user_123456',
                  name: 'テストユーザー',
                  email: 'test@example.com',
                  phoneNumber: '090-1234-5678',
                  avatarUrl: null,
                  token: 'dummy_user_token',
                  refreshToken: 'dummy_user_refresh_token',
                  isEmailVerified: true,
                  role: 'user',
                );

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            HomePage(authUserModel: dummyUser, isOwner: false),
                  ),
                );
              },
              child: const Text('ユーザーホーム画面へ'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                try {
                  // 要件に合わせて修正されたオーナー用AuthUserModelの作成
                  final dummyOwner = AuthUserModel(
                    id: 'owner_654321',
                    name: 'オーナーさん',
                    email: 'owner@example.com',
                    phoneNumber: '090-8765-4321',
                    avatarUrl: 'https://example.com/avatar.jpg',
                    token: 'dummy_owner_token',
                    refreshToken: 'dummy_owner_refresh_token',
                    isEmailVerified: true,
                    role: 'owner',
                  );

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => HomePage(
                            authUserModel: dummyOwner,
                            isOwner: true,
                          ),
                    ),
                  );
                } catch (e) {
                  // エラー発生時にスナックバーで表示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('エラーが発生しました: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  print('Error: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('オーナーホーム画面へ'),
            ),
          ],
        ),
      ),
    );
  }
}
