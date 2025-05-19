import 'package:flutter/material.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';

class ParkingSearchScreen extends StatefulWidget {
  const ParkingSearchScreen({super.key});

  @override
  State<ParkingSearchScreen> createState() => _ParkingSearchScreenState();
}

class _ParkingSearchScreenState extends State<ParkingSearchScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedCarType = '指定なし';
  String _selectedReserveType = '時間貸し';
  bool _showMap = false;
  final TextEditingController _searchController = TextEditingController();

  // デモ用駐車場データ
  final List<Map<String, dynamic>> _parkingList = List.generate(
    28,
    (i) => {
      'name': '東京中央パーキング ${i + 1}',
      'address': '東京都中央区${i % 10 + 1}-${i % 5 + 1}-${i % 8 + 1}',
      'rate': '時間貸し ¥${(i % 5 + 4) * 100}/時間',
      'features': [
        i % 3 == 0 ? '24時間営業' : '8:00-22:00',
        i % 2 == 0 ? '屋根あり' : '屋根なし',
        '予約可',
      ],
      'distance': '駅から${i % 10 + 1}分',
      'favorite': i % 7 == 0,
    },
  );

  final List<String> _carTypes = ['指定なし', '軽自動車', '普通車', '大型車'];
  final List<String> _reserveTypes = ['時間貸し', '日貸し', '月極'];
  List<Map<String, dynamic>> _filteredParkingList = [];

  @override
  void initState() {
    super.initState();
    _filteredParkingList = List.from(_parkingList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          isStart
              ? (_startTime ?? TimeOfDay(hour: 15, minute: 0))
              : (_endTime ?? TimeOfDay(hour: 20, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatDateTime() {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      return '2025年4月29日 15:00〜20:00';
    }
    final d = _selectedDate!;
    final s = _startTime!;
    final e = _endTime!;
    return '${d.year}年${d.month}月${d.day}日 ${s.format(context)}〜${e.format(context)}';
  }

  void _toggleFavorite(int idx) {
    setState(() {
      _parkingList[idx]['favorite'] = !_parkingList[idx]['favorite'];
    });
  }

  void _filterParkingList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredParkingList = List.from(_parkingList);
      } else {
        _filteredParkingList =
            _parkingList.where((parking) {
              return parking['name'].toLowerCase().contains(query) ||
                  parking['address'].toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('駐車場検索', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            icon: const Icon(Icons.map, color: Colors.white),
            label: Text(
              'マップ表示',
              style: TextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索入力フィールド
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '駐車場名や住所を検索...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterParkingList();
                  },
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _filterParkingList(),
              onChanged: (_) {
                if (_searchController.text.isEmpty) {
                  _filterParkingList();
                }
              },
            ),
          ),

          // フィルタバー - レスポンシブ対応
          isSmallScreen
              ? Column(
                children: [
                  // 日付・時間フィルター
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: InkWell(
                      onTap: () async {
                        await _pickDate();
                        await _pickTime(isStart: true);
                        await _pickTime(isStart: false);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _formatDateTime(),
                                style: TextStyles.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 車種と予約タイプの行
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      children: [
                        // 車種
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCarType,
                            items:
                                _carTypes
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _selectedCarType = v);
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              isDense: true,
                            ),
                            icon: const Icon(Icons.arrow_drop_down),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 予約タイプ
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedReserveType,
                            items:
                                _reserveTypes
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _selectedReserveType = v);
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              isDense: true,
                            ),
                            icon: const Icon(Icons.arrow_drop_down),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0),
                child: Row(
                  children: [
                    // 日時
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          await _pickDate();
                          await _pickTime(isStart: true);
                          await _pickTime(isStart: false);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formatDateTime(),
                                  style: TextStyles.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 車種
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCarType,
                        items:
                            _carTypes
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCarType = v);
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          isDense: true,
                        ),
                        icon: const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 予約タイプ
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _selectedReserveType,
                        items:
                            _reserveTypes
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null)
                            setState(() => _selectedReserveType = v);
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          isDense: true,
                        ),
                        icon: const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ],
                ),
              ),

          // 検索ボタン
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _filterParkingList,
                    icon: const Icon(Icons.search),
                    label: const Text('検索する'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 検索結果件数
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredParkingList.length}件の駐車場が見つかりました',
                style: TextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // マップ表示 or リスト
          Expanded(
            child:
                _showMap
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map, size: 80, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'マップがここに表示されます',
                            style: TextStyles.bodyMedium.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                    : _filteredParkingList.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '検索条件に一致する駐車場がありません',
                            style: TextStyles.bodyMedium.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _filteredParkingList.length,
                      itemBuilder: (context, idx) {
                        final p = _filteredParkingList[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 上段: 名称・お気に入り
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p['name'],
                                        style: TextStyles.titleSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        p['favorite']
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color:
                                            p['favorite']
                                                ? Colors.red
                                                : AppColors.primary,
                                      ),
                                      onPressed:
                                          () => _toggleFavorite(
                                            _parkingList.indexOf(p),
                                          ),
                                      tooltip:
                                          p['favorite'] ? 'お気に入り解除' : 'お気に入り登録',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 住所
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        p['address'],
                                        style: TextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // 料金・距離
                                Row(
                                  children: [
                                    Text(
                                      p['rate'],
                                      style: TextStyles.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.directions_walk,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      p['distance'],
                                      style: TextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // 特徴
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children:
                                      (p['features'] as List<String>).map((f) {
                                        return Chip(
                                          label: Text(
                                            f,
                                            style: TextStyles.bodySmall,
                                          ),
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.08),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: 12),
                                // 予約ボタン
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('予約する'),
                                  ),
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
      // ボトムナビゲーション
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '検索'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '履歴'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'アカウント'),
        ],
        onTap: (idx) {
          // 必要に応じて画面遷移
        },
      ),
    );
  }
}
