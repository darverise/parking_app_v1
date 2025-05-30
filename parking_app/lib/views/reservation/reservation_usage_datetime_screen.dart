import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Added for DateFormat

// 仮の予約確認画面（実際の実装では別途定義が必要）
class ReservationConfirmationScreen extends StatelessWidget {
  const ReservationConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('予約確認')),
      body: const Center(child: Text('予約確認画面（仮）')),
    );
  }
}

class ReservationUsageDatetimeScreen extends StatefulWidget {
  const ReservationUsageDatetimeScreen({super.key});

  @override
  State<ReservationUsageDatetimeScreen> createState() =>
      _ReservationUsageDatetimeScreenState();
}

class _ReservationUsageDatetimeScreenState
    extends State<ReservationUsageDatetimeScreen> {
  // 予約単位
  bool _isDayUnit = true;

  // Updated for TableCalendar
  DateTime _focusedDay = DateTime(2025, 5, 29);
  DateTime _selectedDay = DateTime(2025, 5, 29);
  final CalendarFormat _calendarFormat = CalendarFormat.month; // Keep as month

  // 入出庫時間（15分単位予約の場合）
  String _entryTime = '13:00';
  String _exitTime = '16:00';

  // 駐車場情報
  final String _parkingName = '東京中央パーキング';
  final String _parkingAddress = '東京都中央区1-2-3';

  // 料金情報
  int _parkingFee = 500;

  // カレンダーデータ（実際のアプリではAPIから取得）
  // This data is assumed to apply to the day number of ANY month.
  // Added eventColor and spotsAvailable
  final Map<int, Map<String, dynamic>> _calendarData = {
    1: {
      'price': 500,
      'available': false, // Technically not available for booking
      'notice': 'キャンセル多数あり', // Main notice
      'eventColor': Colors.orange, // For dot and styling notice
      'spotsAvailable': 0, // No spots, but notice implies potential
    },
    2: {
      'price': 500,
      'available': false, // Not available
      'notice': 'システムメンテナンス',
      'eventColor': Colors.red,
      'spotsAvailable': 0,
    },
    3: {
      'price': 500,
      'available': false, // Not available
      'notice': '予約不可日',
      'eventColor': Colors.red,
      'spotsAvailable': 0,
    },
    4: {
      'price': 600,
      'available': true,
      'notice': '特別割引日実施中！',
      'eventColor': Colors.green,
      'spotsAvailable': 5,
    },
    5: {
      'price': 500,
      'available': true, // Available for waitlist / notification
      'notice': '現在満車・キャンセル待ち受付',
      'eventColor': Colors.orange,
      'spotsAvailable': 0, // Explicitly 0, but can be on waitlist
    },
    6: {
      'price': 500,
      'available': false, // Not available
      'notice': '満車',
      'eventColor': Colors.red, // Could be grey if just informational full
      'spotsAvailable': 0,
    },
    7: {
      'price': 550,
      'available': true,
      'spotsAvailable': 2,
      'notice': '残りわずか', // General notice
      // No eventColor means no dot, but notice and spots can still be shown in details
    },
    8: {'price': 500, 'available': true, 'spotsAvailable': 8, 'notice': '通常営業'},
    29: {
      'price': 500,
      'available': true,
      'spotsAvailable': 3,
      'notice': '予約受付中',
    },
    30: {
      'price': 700,
      'available': true,
      'notice': '週末特別料金',
      'eventColor': Colors.purple, // Custom event color
      'spotsAvailable': 6,
    },
    31: {
      'price': 500,
      'available': true,
      'spotsAvailable': 10,
      'notice': '予約枠多数あり',
    },
  };

  // 利用可能時間枠（実際のアプリではAPIから取得）
  final List<String> _availableTimeSlots = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize _parkingFee based on the initial _selectedDay
    final dayData = _getCalendarDayData(_selectedDay);
    if (dayData != null && dayData['available'] == true) {
      _parkingFee = dayData['price'] ?? 500;
    }
  }

  // Helper method to get data for a specific day
  // This method can be expanded later for API integration
  Map<String, dynamic>? _getCalendarDayData(DateTime day) {
    // For now, uses the existing _calendarData structure keyed by day.day.
    // In a real app, this might involve more complex logic, caching, or API calls
    // based on the full date (day.year, day.month, day.day).
    return _calendarData[day.day];
  }

  // 時間選択ダイアログを表示
  void _showTimePickerDialog(bool isEntry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEntry ? '入庫時間を選択' : '出庫時間を選択'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableTimeSlots.length,
              itemBuilder: (context, index) {
                final time = _availableTimeSlots[index];
                return ListTile(
                  title: Text(time),
                  onTap: () {
                    setState(() {
                      if (isEntry) {
                        _entryTime = time;
                      } else {
                        _exitTime = time;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 日付選択ダイアログを表示 (for 15-min unit)
  void _showDatePickerDialog() {
    final DateTime datePickerFirstDate = DateTime.now().subtract(
      const Duration(days: 30),
    );
    final DateTime datePickerLastDate = DateTime.now().add(
      const Duration(days: 365),
    );

    DateTime effectiveInitialDate = _selectedDay;

    // Ensure initialDate is not before firstDate
    if (effectiveInitialDate.isBefore(datePickerFirstDate)) {
      effectiveInitialDate = datePickerFirstDate;
    }
    // Ensure initialDate is not after lastDate
    if (effectiveInitialDate.isAfter(datePickerLastDate)) {
      effectiveInitialDate = datePickerLastDate;
    }

    showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: datePickerFirstDate,
      lastDate: datePickerLastDate,
      locale: const Locale('ja'),
    ).then((picked) {
      if (picked != null) {
        setState(() {
          _selectedDay = picked;
          _focusedDay = picked; // Keep focusedDay in sync
        });
      }
    });
  }

  // 予約確認画面に進む
  void _proceedToReservation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReservationConfirmationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kFirstDay = DateTime.now().subtract(const Duration(days: 365));
    final kLastDay = DateTime.now().add(const Duration(days: 365 * 2));
    final dateFormatter = DateFormat('yyyy年MM月dd日', 'ja_JP');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('利用日時選択', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                '利用日時選択',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            // 駐車場情報
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _parkingName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _parkingAddress,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

            // 予約単位選択タブ
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          () => setState(() {
                            _isDayUnit = true;
                            final dayData = _getCalendarDayData(_selectedDay);
                            if (dayData != null &&
                                dayData['available'] == true) {
                              _parkingFee = dayData['price'] ?? 500;
                            } else {
                              _parkingFee = 500;
                            }
                          }),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isDayUnit ? Colors.blue : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(7),
                          ),
                        ),
                        child: Text(
                          '1日単位',
                          style: TextStyle(
                            color: _isDayUnit ? Colors.white : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          () => setState(() {
                            _isDayUnit = false;
                            _parkingFee = 150;
                          }),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !_isDayUnit ? Colors.blue : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(7),
                          ),
                        ),
                        child: Text(
                          '15分単位',
                          style: TextStyle(
                            color: !_isDayUnit ? Colors.white : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 注意文
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '※ 現時点で予約可能な日時のみ表示されます',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),

            if (_isDayUnit)
              // 日単位予約のカレンダー表示 (TableCalendar)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TableCalendar(
                  locale: 'ja_JP',
                  firstDay: kFirstDay,
                  lastDay: kLastDay,
                  focusedDay: _focusedDay,
                  calendarFormat:
                      _calendarFormat, // Should remain CalendarFormat.month
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    final dayData = _getCalendarDayData(selectedDay);
                    if (dayData?['available'] != true) {
                      return;
                    }
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay; // update focused day as well
                      _parkingFee = dayData?['price'] ?? _parkingFee;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    // setState is important here if _getCalendarDayData were to fetch
                    // new data based on the month of focusedDay.
                    // For now, it just updates the UI's focused day.
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  enabledDayPredicate: (day) {
                    final dayData = _getCalendarDayData(day);
                    return dayData?['available'] ?? false;
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final dayData = _getCalendarDayData(day);
                      final isAvailable = dayData?['available'] ?? false;
                      Color textColor =
                          isAvailable ? Colors.black : Colors.grey.shade400;
                      if (day.weekday == DateTime.sunday) {
                        textColor =
                            isAvailable
                                ? Colors.red
                                : Colors.red.withOpacity(0.5);
                      } else if (day.weekday == DateTime.saturday) {
                        textColor =
                            isAvailable
                                ? Colors.blue[700]!
                                : Colors.blue.withOpacity(0.5);
                      }

                      return _buildCalendarCell(
                        day: day.day,
                        price:
                            isAvailable
                                ? (dayData != null ? dayData['price'] : null)
                                : null,
                        notice:
                            isAvailable
                                ? (dayData != null ? dayData['notice'] : null)
                                : null,
                        textColor: textColor,
                        isAvailable: isAvailable,
                        eventColor: dayData?['eventColor'] as Color?,
                        spotsAvailable: dayData?['spotsAvailable'] as int?,
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      final dayData = _getCalendarDayData(day);
                      return _buildCalendarCell(
                        day: day.day,
                        price: dayData?['price'],
                        notice: dayData?['notice'],
                        textColor: Colors.white,
                        backgroundColor: Colors.blue,
                        isBold: true,
                        isAvailable: true, // Selected day must be available
                        eventColor: dayData?['eventColor'] as Color?,
                        spotsAvailable: dayData?['spotsAvailable'] as int?,
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final dayData = _getCalendarDayData(day);
                      final isAvailable = dayData?['available'] ?? false;
                      Color textColor =
                          isAvailable ? Colors.black : Colors.grey.shade400;
                      if (day.weekday == DateTime.sunday) {
                        textColor =
                            isAvailable
                                ? Colors.red
                                : Colors.red.withOpacity(0.5);
                      } else if (day.weekday == DateTime.saturday) {
                        textColor =
                            isAvailable
                                ? Colors.blue[700]!
                                : Colors.blue.withOpacity(0.5);
                      }
                      return _buildCalendarCell(
                        day: day.day,
                        price:
                            isAvailable
                                ? (dayData != null ? dayData['price'] : null)
                                : null,
                        notice:
                            isAvailable
                                ? (dayData != null ? dayData['notice'] : null)
                                : null,
                        textColor: textColor,
                        isBold: true, // Make today's number bold
                        isAvailable: isAvailable,
                        isToday: true,
                        eventColor: dayData?['eventColor'] as Color?,
                        spotsAvailable: dayData?['spotsAvailable'] as int?,
                      );
                    },
                    disabledBuilder: (context, day, focusedDay) {
                      Color textColor = Colors.grey.shade300;
                      if (day.weekday == DateTime.sunday) {
                        textColor = Colors.red.withOpacity(0.3);
                      } else if (day.weekday == DateTime.saturday) {
                        textColor = Colors.blue.withOpacity(0.3);
                      }
                      return _buildCalendarCell(
                        day: day.day,
                        price: _getCalendarDayData(day)?['price'],
                        textColor: textColor,
                        isAvailable: false,
                        eventColor:
                            _getCalendarDayData(day)?['eventColor'] as Color?,
                        spotsAvailable:
                            _getCalendarDayData(day)?['spotsAvailable'] as int?,
                      );
                    },
                  ),
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false, // Ensures month view is fixed
                    titleTextStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: 24,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(
                      color: Colors.red[600],
                    ), // For Sat/Sun headers
                    todayDecoration: BoxDecoration(
                      // Subtle indicator for today if not selected
                      color: Colors.transparent, // No background fill
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.7),
                        width: 1.5,
                      ),
                    ),
                    selectedDecoration: BoxDecoration(
                      // This is overridden by selectedBuilder
                      color: Colors.blue,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    weekendStyle: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              // 15分単位予約の時間選択
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '入庫',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: _showDatePickerDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    // '${_selectedDay.month}/${_selectedDay.day}',
                                    dateFormatter.format(_selectedDay),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _showTimePickerDialog(true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _entryTime,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Icon(Icons.arrow_downward, color: Colors.grey),
                      ),
                    ),

                    Text(
                      '出庫',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: _showDatePickerDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    // '${_selectedDay.month}/${_selectedDay.day}',
                                    dateFormatter.format(_selectedDay),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _showTimePickerDialog(false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _exitTime,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Event Details Section (New)
            if (_isDayUnit) _buildEventDetailsSection(),

            // 利用日時と料金の確認
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '利用日時',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _isDayUnit
                            // ? '${_selectedDay.month}/${_selectedDay.day}'
                            ? dateFormatter.format(_selectedDay)
                            // : '${_selectedDay.month}/${_selectedDay.day} $_entryTime～$_exitTime',
                            : '${dateFormatter.format(_selectedDay)} $_entryTime～$_exitTime',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '駐車場料金',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '¥$_parkingFee',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ), // This SizedBox might need adjustment or removal depending on final layout with bottomSheet
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16,
        ), // Adjust padding as needed
        color: Colors.white, // Ensure background color to hide content behind
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _proceedToReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, // Or your AppColors.accent
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('予約に進む'),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Example: Set to 0 for 'Home' or adjust as needed
        selectedItemColor: Colors.blue, // Placeholder for AppColors.primary
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
          // Handle navigation for bottom bar items
          // For example, if idx matches current screen's purpose, do nothing.
          // Otherwise, Navigator.pushReplacementNamed or similar.
        },
      ),
    );
  }

  Widget _buildCalendarCell({
    required int day,
    int? price,
    String?
    notice, // Notice here is more for cell display if needed, main notice in _calendarData
    required Color textColor,
    Color? backgroundColor,
    bool isBold = false,
    required bool isAvailable,
    bool isToday = false,
    Color? eventColor,
    int? spotsAvailable,
  }) {
    Border? cellBorder;
    if (isToday && backgroundColor == null) {
      // Special border for today if not selected
      cellBorder = Border.all(
        color: Colors.blueAccent.withOpacity(0.7),
        width: 1.0, // Reduced width for today's border
      );
    } else if (backgroundColor == null) {
      // Apply default border only if no specific background (e.g. not selected)
      // Default subtle border for all other cells
      cellBorder = Border.all(
        color: Colors.grey.shade200, // Lighter border color
        width: 0.5, // Thinner border
      );
    }
    // If backgroundColor is present (e.g., for selected day), no explicit border is drawn here,
    // relying on the BoxDecoration of the selection.

    return Container(
      margin: const EdgeInsets.all(0.5), // Minimal margin
      padding: EdgeInsets.zero, // No internal padding for the container itself
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4.0), // Slightly smaller radius
        border: cellBorder,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            '$day',
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (price != null)
            Text(
              '¥$price',
              style: TextStyle(
                fontSize: 9,
                color: textColor.withOpacity(isAvailable ? 1.0 : 0.7),
              ),
            ),
          // Removed SizedBox(height: 1) to allow MainAxisAlignment.spaceBetween to manage space
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 2.0,
            ), // Reduced horizontal padding
            child:
                (eventColor == null &&
                        isAvailable &&
                        spotsAvailable != null &&
                        spotsAvailable > 0)
                    // Case 1: No dot, but spots available -> Center spots text
                    ? Center(
                      child: Text(
                        '空$spotsAvailable',
                        style: TextStyle(
                          fontSize: 7.5, // Reduced font size
                          color: textColor.withOpacity(isAvailable ? 0.9 : 0.5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    // Case 2: Dot present, or no spots to show in this row, or not available
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Event Dot
                        if (eventColor != null && isAvailable)
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: eventColor,
                          ) // Reduced radius
                        else
                          const SizedBox(
                            width: 6,
                          ), // Adjusted placeholder size (radius*2)
                        // Right: Spots Available (only if dot is also present)
                        if (eventColor != null &&
                            spotsAvailable != null &&
                            spotsAvailable > 0 &&
                            isAvailable)
                          Text(
                            '空$spotsAvailable',
                            style: TextStyle(
                              fontSize: 7.5, // Reduced font size
                              color: textColor.withOpacity(
                                isAvailable ? 0.9 : 0.5,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          const SizedBox(width: 6), // Adjusted placeholder size
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  // New widget to display event details for the selected day
  Widget _buildEventDetailsSection() {
    final dayData = _getCalendarDayData(_selectedDay);

    // If day is not available for booking, or no specific data, show minimal or no info.
    // We show details even if not 'available' in _calendarData if there's a notice (e.g. "System Maintenance")
    if (dayData == null) {
      return const SizedBox.shrink();
    }

    final String? notice = dayData['notice'] as String?;
    final int? spots = dayData['spotsAvailable'] as int?;
    final Color? eventColor = dayData['eventColor'] as Color?;
    final bool isActuallyAvailableForBooking =
        dayData['available'] as bool? ?? false;

    List<Widget> eventItems = [];

    // Line 1: Primary Notice
    if (notice != null && notice.isNotEmpty) {
      eventItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            notice,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  eventColor ??
                  (isActuallyAvailableForBooking
                      ? Colors.black87
                      : Colors.red.shade700),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Line 2: Availability Status
    if (isActuallyAvailableForBooking) {
      if (spots != null && spots > 0) {
        eventItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              '空き車位数: $spots台',
              style: TextStyle(
                fontSize: 13,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else if (spots == 0 && notice != null && notice.contains("満車")) {
        // Already covered by primary notice if it says "満車"
      } else if (spots == 0 && isActuallyAvailableForBooking) {
        // E.g. available for waitlist, but 0 spots now
        eventItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              '現在空き枠なし (キャンセル待ち可能)', // Or similar text
              style: TextStyle(fontSize: 13, color: Colors.orange.shade800),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    // Line 3: Actionable Event (Cancellation Notification)
    if (isActuallyAvailableForBooking &&
        eventColor == Colors.orange &&
        notice != null &&
        (notice.contains('キャンセル') || notice.contains('満車'))) {
      eventItems.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 6.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.notification_add_outlined, size: 18),
            label: const Text('空き通知を受け取る'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('空き通知の登録機能を実装予定です。')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // Line 4: Critical Information (Maintenance/Unavailable)
    if (!isActuallyAvailableForBooking &&
        eventColor == Colors.red &&
        notice != null &&
        (notice.contains('メンテナンス') || notice.contains('予約不可'))) {
      eventItems.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0, bottom: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                notice, // Or a more specific message like 'この日は予約できません'
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (eventItems.isEmpty) {
      // If the day is selected but no specific events, show a generic message or nothing
      if (isActuallyAvailableForBooking) {
        eventItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              '詳細情報はありません。', // No specific events for this day
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else {
        return const SizedBox.shrink(); // Truly nothing to show
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '選択日のイベント情報',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const Divider(height: 16),
          ...eventItems,
        ],
      ),
    );
  }
}
