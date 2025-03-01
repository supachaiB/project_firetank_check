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
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryItem("ถังทั้งหมด", totalTanks, Colors.blue),
                      _buildSummaryItem(
                          "ตรวจสอบแล้ว", checkedCount, Colors.green),
                      _buildSummaryItem(
                        "ยังไม่ตรวจสอบ",
                        totalTanks - checkedCount - brokenCount - repairCount,
                        Colors.grey,
                      ),
                      _buildSummaryItem("ชำรุด", brokenCount, Colors.red),
                      _buildSummaryItem("ส่งซ่อม", repairCount, Colors.orange),
                    ],
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
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

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            "$count",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
