import 'package:flutter/material.dart';

class ScheduleBox extends StatelessWidget {
  final int remainingTimeInSeconds;
  final int remainingQuarterTimeInSeconds;

  const ScheduleBox({
    Key? key,
    required this.remainingTimeInSeconds,
    required this.remainingQuarterTimeInSeconds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // วันที่ปัจจุบัน
    DateTime now = DateTime.now();

    // หาวันสุดท้ายของเดือนปัจจุบัน (สิ้นเดือน)
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    Duration remainingTime =
        endOfMonth.difference(now); // เวลาที่เหลือจนถึงสิ้นเดือน

    // หาวันสุดท้ายของไตรมาส (3 เดือน)
    int quarterEndMonth =
        ((now.month - 1) ~/ 3 + 1) * 3; // เดือนสุดท้ายของไตรมาส
    DateTime endOfQuarter = DateTime(
        now.year, quarterEndMonth + 1, 0, 23, 59, 59); // วันที่สุดท้ายของไตรมาส
    Duration remainingQuarterTime =
        endOfQuarter.difference(now); // เวลาที่เหลือจนถึงสิ้นไตรมาส

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "กำหนดการตรวจ",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(height: 2),
                // แสดงเวลาเหลือของผู้ใช้ทั่วไป
                Text(
                  "ผู้ใช้ทั่วไปเหลือ :  ${remainingTime.inDays} วัน ${remainingTime.inHours % 24} ชั่วโมง",
                  style: TextStyle(fontSize: 14),
                ),
                // แสดงเวลาเหลือของช่างเทคนิค
                Text(
                  "ช่างเทคนิคเหลือ : ${remainingQuarterTime.inDays} วัน ${remainingQuarterTime.inHours % 24} ชั่วโมง",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
