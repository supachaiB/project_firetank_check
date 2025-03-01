import 'package:flutter/material.dart';

class ScheduleBox extends StatelessWidget {
  final int remainingTime;
  final int remainingQuarterTime;

  const ScheduleBox({
    Key? key,
    required this.remainingTime,
    required this.remainingQuarterTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // คำนวณเวลาสำหรับผู้ใช้ทั่วไป
    int days = remainingTime ~/ (24 * 3600); // คำนวณจำนวนวัน
    /*int hours = (remainingTime % (24 * 3600)) ~/ 3600; // คำนวณชั่วโมง
    int minutes = (remainingTime % 3600) ~/ 60; // คำนวณนาที
    int seconds = remainingTime % 60; // คำนวณวินาที*/

    // คำนวณเวลาสำหรับช่างเทคนิค
    int quarterDays = remainingQuarterTime ~/ (24 * 3600);
    int quarterHours = (remainingQuarterTime % (24 * 3600)) ~/ 3600;
    /*int quarterMinutes = (remainingQuarterTime % 3600) ~/ 60;
    int quarterSeconds = remainingQuarterTime % 60;*/

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width *
              0.9, // จำกัดความกว้างไม่เกิน 90% ของหน้าจอ
        ),
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ป้องกันการขยาย Column
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
                Text(
                  "ผู้ใช้ทั่วไปเหลือ :  $days วัน $quarterHours ชั่วโมง",
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  "ช่างเทคนิคเหลือ : $quarterDays วัน $quarterHours ชั่วโมง",
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
