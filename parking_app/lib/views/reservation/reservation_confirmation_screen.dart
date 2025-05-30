import 'package:flutter/material.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';

class ReservationConfirmationScreen extends StatefulWidget {
  const ReservationConfirmationScreen({super.key});

  @override
  State<ReservationConfirmationScreen> createState() =>
      _ReservationConfirmationScreenState();
}

class _ReservationConfirmationScreenState
    extends State<ReservationConfirmationScreen> {
  // 予約情報
  DateTime _reservationDate = DateTime(2025, 5, 9);
  final String _reservationTime = '00:00～23:59まで利用可能';
  final int _parkingFee = 500;
  final int _serviceFee = 75;

  // ご利用情報
  bool _vehicleConfirmed = true;
  String? _vehicleModel;
  String _vehicleType = '中型車';
  String? _region;
  String? _classNumber;
  String? _hiragana;
  String? _number;
  bool _registerAsRegular = false;

  final List<String> _vehicleTypes = ['中型車', '軽自動車', '普通車', '大型車'];

  final _formKey = GlobalKey<FormState>();

  void _changeReservationDate() async {
    // 日付選択ダイアログ
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reservationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ja'),
    );
    if (picked != null) {
      setState(() {
        _reservationDate = picked;
      });
    }
  }

  void _showServiceFeeInfo() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('サービス料について'),
            content: const Text('サービス料はプラットフォーム利用に関連する手数料です。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _navigateToVehicleModelSetting() {
    // TODO: 車種名設定画面へ遷移
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('車種名設定画面へ遷移')));
  }

  void _proceedToPayment() {
    if (_vehicleConfirmed &&
        (_vehicleModel == null ||
            _vehicleModel!.isEmpty ||
            _region == null ||
            _classNumber == null ||
            _hiragana == null ||
            _number == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('車種名・ナンバーを入力してください')));
      return;
    }
    // TODO: 支払い画面へ遷移
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('お支払い画面へ進みます')));
  }

  @override
  Widget build(BuildContext context) {
    final total = _parkingFee + _serviceFee;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('予約確認', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ご利用日時と料金
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Text(
                  'ご利用日時と料金',
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '予約情報',
                          style: TextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _changeReservationDate,
                          icon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            '予約日を変更',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '予約日時',
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_reservationDate.month}/${_reservationDate.day}',
                              style: TextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _reservationTime,
                              style: TextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '駐車場料金',
                          style: TextStyles.bodyMedium.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text('¥$_parkingFee', style: TextStyles.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'サービス料',
                              style: TextStyles.bodyMedium.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _showServiceFeeInfo,
                              child: const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Text('¥$_serviceFee', style: TextStyles.bodyMedium),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '合計額',
                          style: TextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '¥$total',
                          style: TextStyles.bodyLarge.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ご利用情報
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  'ご利用情報',
                  style: TextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '利用車両',
                        style: TextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: true,
                                    groupValue: _vehicleConfirmed,
                                    activeColor: AppColors.primary,
                                    visualDensity: VisualDensity.compact,
                                    onChanged:
                                        (v) => setState(
                                          () => _vehicleConfirmed = true,
                                        ),
                                  ),
                                  Text(
                                    '決まっている',
                                    style: TextStyle(
                                      fontWeight:
                                          _vehicleConfirmed
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: false,
                                    groupValue: _vehicleConfirmed,
                                    activeColor: AppColors.primary,
                                    visualDensity: VisualDensity.compact,
                                    onChanged:
                                        (v) => setState(
                                          () => _vehicleConfirmed = false,
                                        ),
                                  ),
                                  Text(
                                    '決まっていない',
                                    style: TextStyle(
                                      fontWeight:
                                          !_vehicleConfirmed
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '車種名',
                              style: TextStyles.bodyMedium.copyWith(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _vehicleModel ?? '未設定',
                                  style: TextStyles.bodyMedium.copyWith(
                                    color:
                                        _vehicleModel == null
                                            ? Colors.grey
                                            : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _navigateToVehicleModelSetting,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    '車種名を設定',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '車種タイプ',
                        style: TextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _vehicleType,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            elevation: 2,
                            style: TextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _vehicleType = value;
                                });
                              }
                            },
                            items:
                                _vehicleTypes.map<DropdownMenuItem<String>>((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ナンバー',
                        style: TextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: '品川',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                        onChanged:
                                            (v) => setState(() => _region = v),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: '300',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                        onChanged:
                                            (v) => setState(
                                              () => _classNumber = v,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'お',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                        onChanged:
                                            (v) =>
                                                setState(() => _hiragana = v),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: TextFormField(
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: '0000',
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                        onChanged:
                                            (v) => setState(() => _number = v),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Transform.scale(
                              scale: 0.9,
                              child: Checkbox(
                                value: _registerAsRegular,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: BorderSide(
                                  width: 1.5,
                                  color: Colors.grey.shade400,
                                ),
                                onChanged:
                                    (v) => setState(
                                      () => _registerAsRegular = v ?? false,
                                    ),
                              ),
                            ),
                            Text(
                              '普段使う車両として登録',
                              style: TextStyle(
                                fontWeight:
                                    _registerAsRegular
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_vehicleConfirmed &&
                          (_vehicleModel == null ||
                              _vehicleModel!.isEmpty ||
                              _region == null ||
                              _classNumber == null ||
                              _hiragana == null ||
                              _number == null))
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '車種名、ナンバーは入庫までには必ずご入力ください',
                                  style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _proceedToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: AppColors.primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'お支払いに進む',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
