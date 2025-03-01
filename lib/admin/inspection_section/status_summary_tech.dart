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
    int uncheckedCount = 0;
    int brokenCount = 0;
    int repairCount = 0;

    for (var doc in snapshot.docs) {
      final String status = doc['status_technician'] ?? '';
      if (status == 'ตรวจสอบแล้ว') {
        checkedCount++;
      } else if (status == 'ยังไม่ตรวจสอบ') {
        uncheckedCount++;
      } else if (status == 'ชำรุด') {
        brokenCount++;
      } else if (status == 'ส่งซ่อม') {
        repairCount++;
      }
    }

    return {
      'totalTanks': totalTanks,
      'checkedCount': checkedCount,
      'uncheckedCount': uncheckedCount,
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
                bool isSmallScreen =
                    constraints.maxWidth < 600; // ถ้าหน้าจอแคบกว่า 600px

                return isSmallScreen
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryItem(
                              "ถังทั้งหมด", data['totalTanks']!, Colors.blue),
                          _buildSummaryItem("ตรวจสอบแล้ว",
                              data['checkedCount']!, Colors.green),
                          _buildSummaryItem(
                            "ยังไม่ตรวจสอบ",
                            data['uncheckedCount']!,
                            Colors.grey,
                          ),
                          _buildSummaryItem(
                              "ชำรุด", data['brokenCount']!, Colors.red),
                          _buildSummaryItem(
                              "ส่งซ่อม", data['repairCount']!, Colors.orange),
                        ],
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
