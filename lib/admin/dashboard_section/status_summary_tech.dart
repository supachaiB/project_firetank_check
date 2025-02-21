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
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard(
                    "ถังทั้งหมด", data['totalTanks']!, Colors.blue),
                _buildSummaryCard(
                    "ตรวจสอบแล้ว", data['checkedCount']!, Colors.green),
                _buildSummaryCard(
                    "ยังไม่ตรวจสอบ", data['uncheckedCount']!, Colors.grey),
                _buildSummaryCard("ชำรุด", data['brokenCount']!, Colors.red),
                _buildSummaryCard(
                    "ส่งซ่อม", data['repairCount']!, Colors.orange),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
