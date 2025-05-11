import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:parking_app/core/services/auth_signin_service.dart';
import 'package:provider/provider.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';
import 'package:parking_app/core/models/auth_signin_model.dart';

class HomePage extends StatefulWidget {
  final AuthUserModel authUserModel;
  final bool isOwner;

  const HomePage({
    super.key,
    required this.authUserModel,
    required this.isOwner,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isOwner
              ? "オーナーダッシュボード" // 使用硬编码替代AppLocalizations
              : "ユーザーダッシュボード", // 使用硬编码替代AppLocalizations
          style: TextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: AppLocalizations.of(context).logout ?? 'ログアウト',
          ),
        ],
      ),
      body: widget.isOwner ? _buildOwnerContent() : _buildUserContent(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildUserContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User profile card
          _buildProfileCard(),

          const SizedBox(height: 24.0),

          // Active reservations section
          _buildSectionHeader(
            "現在の予約", // 使用硬编码替代AppLocalizations
            Icons.bookmark,
          ),

          // Demo reservation card
          _buildReservationCard(
            parkingName: '栄駅前パーキング',
            dateTime: '2024-05-13 14:00 - 17:00',
            status: 'confirmed',
            amount: '¥1,500',
            onClick: () {},
          ),

          const SizedBox(height: 24.0),

          // Find parking section
          _buildSectionHeader(
            "駐車場を探す", // 使用硬编码替代AppLocalizations
            Icons.search,
          ),

          // Search box
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "駐車場を検索...", // 使用硬编码替代AppLocalizations
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
              ),
            ),
          ),

          // Map placeholder
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map, size: 48.0, color: Colors.grey),
                  const SizedBox(height: 8.0),
                  Text(
                    "地図が表示されます", // 使用硬编码替代AppLocalizations
                    style: TextStyles.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24.0),

          // Parking history section
          _buildSectionHeader(
            "利用履歴", // 使用硬编码替代AppLocalizations
            Icons.history,
          ),

          // History item
          _buildHistoryItem(
            parkingName: '名古屋城北駐車場',
            dateTime: '2024-05-06 10:00 - 12:00',
            amount: '¥800',
          ),

          const SizedBox(height: 50.0), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildOwnerContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner profile card
          _buildProfileCard(),

          const SizedBox(height: 24.0),

          // Parking spaces section
          _buildSectionHeader(
            "登録駐車場一覧", // 修改: 移除了 AppLocalizations.of(context)?.
            Icons.local_parking,
          ),

          // Parking space items
          _buildParkingSpaceItem(
            name: '栄駅前パーキング',
            address: '愛知県名古屋市中区栄3-5-6',
            hourlyRate: '¥500/時間',
            isAvailable: true,
          ),

          _buildParkingSpaceItem(
            name: '名古屋城北駐車場',
            address: '愛知県名古屋市中区三の丸1-1-10',
            hourlyRate: '¥400/時間',
            isAvailable: true,
          ),

          // Add parking button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context).settings ?? '駐車場を追加'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                side: BorderSide(color: AppColors.primary),
              ),
            ),
          ),

          const SizedBox(height: 24.0),

          // Revenue summary
          _buildSectionHeader(
            AppLocalizations.of(context).payment ?? '収益情報',
            Icons.trending_up,
          ),

          // Revenue card
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildRevenueItem(
                  title: AppLocalizations.of(context).payment ?? '本日の収益',
                  amount: '¥1,500',
                  color: Colors.green,
                ),
                const Divider(),
                _buildRevenueItem(
                  title: AppLocalizations.of(context).payment ?? '今月の収益',
                  amount: '¥32,400',
                  color: Colors.blue,
                ),
                const Divider(),
                _buildRevenueItem(
                  title: AppLocalizations.of(context).payment ?? '累計収益',
                  amount: '¥128,700',
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24.0),

          // Recent reservations
          _buildSectionHeader(
            "最近の予約", // 修改: 移除了 AppLocalizations.of(context)?.reservations ??
            Icons.book_online,
          ),

          _buildOwnerReservationItem(
            userName: '田中 ユキ',
            parkingName: '栄駅前パーキング',
            dateTime: '2024-05-13 14:00 - 17:00',
            amount: '¥1,500',
          ),

          _buildOwnerReservationItem(
            userName: '鈴木 タロウ',
            parkingName: '名古屋城北駐車場',
            dateTime: '2024-05-06 10:00 - 12:00',
            amount: '¥800',
            status: 'completed',
          ),

          const SizedBox(height: 50.0), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = widget.authUserModel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 32.0,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : '?',
                  style: TextStyles.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: TextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      user.email,
                      style: TextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      user.phone_number,
                      style: TextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
                tooltip:
                    "プロフィール編集", // 修改: 移除了 AppLocalizations.of(context)?.editProfile ??
              ),
            ],
          ),
          // Additional info for owner
          if (widget.isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 16.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    AppLocalizations.of(context).appTitle ?? '駐車場オーナーアカウント',
                    style: TextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24.0, color: AppColors.primary),
          const SizedBox(width: 8.0),
          Text(
            title,
            style: TextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard({
    required String parkingName,
    required String dateTime,
    required String status,
    required String amount,
    required VoidCallback onClick,
  }) {
    final statusText =
        status == 'confirmed'
            ? "確認済み" // 使用硬编码替代AppLocalizations
            : "保留中"; // 使用硬编码替代AppLocalizations

    final statusColor = status == 'confirmed' ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        parkingName,
                        style: TextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8.0),
                    Text(dateTime, style: TextStyles.bodyMedium),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_car,
                          size: 16.0,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          "標準駐車", // 使用硬编码替代AppLocalizations
                          style: TextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    Text(
                      amount,
                      style: TextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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

  Widget _buildHistoryItem({
    required String parkingName,
    required String dateTime,
    required String amount,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_parking, color: AppColors.primary),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parkingName,
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dateTime,
                    style: TextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingSpaceItem({
    required String name,
    required String address,
    required String hourlyRate,
    required bool isAvailable,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16.0, color: Colors.grey),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hourlyRate,
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem({
    required String title,
    required String amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            amount,
            style: TextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerReservationItem({
    required String userName,
    required String parkingName,
    required String dateTime,
    required String amount,
    String status = 'confirmed',
  }) {
    final statusText =
        status == 'confirmed'
            ? "確認済み" // 修改: 使用硬编码而不是 AppLocalizations.of(context).welcome
            : status == 'completed'
            ? "完了" // 修改: 使用硬编码而不是 AppLocalizations.of(context)?.welcome
            : "保留中"; // 修改: 使用硬编码而不是 AppLocalizations.of(context)?.welcome

    final statusColor =
        status == 'confirmed'
            ? Colors.green
            : status == 'completed'
            ? Colors.blue
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0] : '?',
                    style: TextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  userName,
                  style: TextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parkingName,
                        style: TextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14.0,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            dateTime,
                            style: TextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  amount,
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: "ホーム", // 使用硬编码替代AppLocalizations
        ),
        if (widget.isOwner)
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_parking),
            label: "駐車場", // 使用硬编码替代AppLocalizations
          )
        else
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: "検索", // 使用硬编码替代AppLocalizations
          ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bookmark),
          label: "予約", // 使用硬编码替代AppLocalizations
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: "プロフィール", // 使用硬编码替代AppLocalizations
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    try {
      final authService = Provider.of<AuthSignInService>(
        context,
        listen: false,
      );
      await authService.signOut();

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
