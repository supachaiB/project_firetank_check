import 'package:flutter/material.dart';

class StatusSummaryWidget extends StatelessWidget {
  final int totalTanks;
  final int checkedCount;
  final int brokenCount;
  final int repairCount;

  StatusSummaryWidget({
    required this.totalTanks,
    required this.checkedCount,
    required this.brokenCount,
    required this.repairCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen =
                constraints.maxWidth < 600; // ถ้าหน้าจอแคบกว่า 600px

            return isSmallScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // จัดกึ่งกลาง

                    children: [
                      _buildSummaryItem("ถังทั้งหมด", totalTanks, Colors.blue),
                      const SizedBox(width: 8), // เพิ่มระยะห่างระหว่างไอเทม
                      _buildSummaryItem(
                          "ตรวจสอบแล้ว", checkedCount, Colors.green),
                      const SizedBox(width: 8),
                      _buildSummaryItem(
                        "ยังไม่ตรวจสอบ",
                        totalTanks - checkedCount - brokenCount - repairCount,
                        Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryItem("ชำรุด", brokenCount, Colors.red),
                      const SizedBox(width: 8),
                      _buildSummaryItem("ส่งซ่อม", repairCount, Colors.orange),
                    ],
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildSummaryItem(
                            "ถังทั้งหมด", totalTanks, Colors.blue),
                        const SizedBox(width: 10),
                        _buildSummaryItem(
                            "ตรวจสอบแล้ว", checkedCount, Colors.green),
                        const SizedBox(width: 10),
                        _buildSummaryItem(
                          "ยังไม่ตรวจสอบ",
                          totalTanks - checkedCount - brokenCount - repairCount,
                          Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        _buildSummaryItem("ชำรุด", brokenCount, Colors.red),
                        const SizedBox(width: 10),
                        _buildSummaryItem(
                            "ส่งซ่อม", repairCount, Colors.orange),
                        const SizedBox(width: 10),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, int value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12, // ขนาดตัวอักษรที่เล็กลง
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4), // เพิ่มระยะห่างระหว่างข้อความ
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16, // ขนาดตัวอักษรที่เล็กลง
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
