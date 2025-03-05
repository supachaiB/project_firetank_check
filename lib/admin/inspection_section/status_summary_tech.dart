import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatusSummaryTech extends StatelessWidget {
  const StatusSummaryTech({Key? key}) : super(key: key);

  Future<Map<String, int>> fetchTankData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final CollectionReference tanksCollection =
        firestore.collection('firetank_Collection');

    final QuerySnapshot snapshot = await tanksCollection.get();
    final int totalTanks = snapshot.size;

    int checkedCount = 0;
    int brokenCount = 0;
    int repairCount = 0;

    for (var doc in snapshot.docs) {
      final String status = doc['status_technician'] ?? '';
      if (status == 'ตรวจสอบแล้ว') {
        checkedCount++;
      } else if (status == 'ชำรุด') {
        brokenCount++;
      } else if (status == 'ส่งซ่อม') {
        repairCount++;
      }
    }

    return {
      'totalTanks': totalTanks,
      'checkedCount': checkedCount,
      'uncheckedCount': totalTanks - checkedCount - brokenCount - repairCount,
      'brokenCount': brokenCount,
      'repairCount': repairCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: fetchTankData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
        }
        if (!snapshot.hasData) {
          return Center(child: Text('ไม่มีข้อมูล'));
        }

        final data = snapshot.data!;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isSmallScreen = constraints.maxWidth < 600;

                return isSmallScreen
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSummaryItem(
                              "ถังทั้งหมด", data['totalTanks']!, Colors.blue),
                          const SizedBox(width: 8),
                          _buildSummaryItem("ตรวจสอบแล้ว",
                              data['checkedCount']!, Colors.green),
                          const SizedBox(width: 8),
                          _buildSummaryItem("ยังไม่ตรวจสอบ",
                              data['uncheckedCount']!, Colors.grey),
                          const SizedBox(width: 8),
                          _buildSummaryItem(
                              "ชำรุด", data['brokenCount']!, Colors.red),
                          const SizedBox(width: 8),
                          _buildSummaryItem(
                              "ส่งซ่อม", data['repairCount']!, Colors.orange),
                        ],
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildSummaryItem(
                                "ถังทั้งหมด", data['totalTanks']!, Colors.blue),
                            const SizedBox(width: 10),
                            _buildSummaryItem("ตรวจสอบแล้ว",
                                data['checkedCount']!, Colors.green),
                            const SizedBox(width: 10),
                            _buildSummaryItem("ยังไม่ตรวจสอบ",
                                data['uncheckedCount']!, Colors.grey),
                            const SizedBox(width: 10),
                            _buildSummaryItem(
                                "ชำรุด", data['brokenCount']!, Colors.red),
                            const SizedBox(width: 10),
                            _buildSummaryItem(
                                "ส่งซ่อม", data['repairCount']!, Colors.orange),
                            const SizedBox(width: 10),
                          ],
                        ),
                      );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String title, int value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
