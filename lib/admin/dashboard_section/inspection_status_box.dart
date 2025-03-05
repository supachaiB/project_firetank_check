import 'package:flutter/material.dart';
import 'package:firecheck_setup/admin/dashboard.dart';

class InspectionStatusBox extends StatelessWidget {
  final int checkedCount, uncheckedCount, brokenCount, repairCount;
  const InspectionStatusBox({
    Key? key,
    required this.checkedCount,
    required this.uncheckedCount,
    required this.brokenCount,
    required this.repairCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12.0),
      decoration: boxDecorationStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text('การตรวจสอบ(ผู้ใช้ทั่วไป)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          buildStatusRow('ตรวจสอบแล้ว', checkedCount, Colors.green),
          buildStatusRow('ยังไม่ตรวจสอบ', uncheckedCount, Colors.grey),
          buildStatusRow('ชำรุด', brokenCount, Colors.red),
          buildStatusRow('ส่งซ่อม', repairCount, Colors.orange),
        ],
      ),
    );
  }

  Widget buildStatusRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('$label: $count'),
      ],
    );
  }
}
