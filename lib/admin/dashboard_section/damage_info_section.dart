import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // เพิ่มการ import

class DamageInfoSection extends StatelessWidget {
  const DamageInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('firetank_Collection')
          .where('status',
              isEqualTo: 'ชำรุด') // เงื่อนไขการดึงข้อมูลจาก firetank_Collection
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('ไม่มีข้อมูลการชำรุด'));
        }

        final damageList = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            // เพิ่ม SingleChildScrollView เพื่อให้กล่องเลื่อน
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                ...damageList.map((damage) {
                  final data = damage.data() as Map<String, dynamic>;
                  final tankId = data['tank_id'] ?? 'ไม่ระบุ';

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('form_checks')
                        .where('tank_id', isEqualTo: tankId)
                        .orderBy('date_checked', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, reportSnapshot) {
                      if (reportSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }

                      if (reportSnapshot.hasError) {
                        return const SizedBox.shrink();
                      }

                      String reportDate = '-';
                      if (reportSnapshot.hasData &&
                          reportSnapshot.data!.docs.isNotEmpty) {
                        final reportData = reportSnapshot.data!.docs.first
                            .data() as Map<String, dynamic>;
                        var dateChecked = reportData['date_checked'];

                        if (dateChecked is Timestamp) {
                          DateTime dateTime = dateChecked.toDate();
                          reportDate =
                              DateFormat('yyyy-MM-dd').format(dateTime);
                        } else if (dateChecked is String) {
                          try {
                            DateTime dateTime = DateTime.parse(dateChecked);
                            reportDate =
                                DateFormat('yyyy-MM-dd').format(dateTime);
                          } catch (e) {
                            reportDate = '-';
                          }
                        }
                      }

                      return _buildDamageAlert(
                        tankId: tankId,
                        type: data['type'] ?? 'ไม่ระบุ',
                        building: data['building'] ?? 'ไม่ระบุ',
                        floor: data['floor'] ?? 'ไม่ระบุ',
                        reportDate: reportDate,
                      );
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /*Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }*/

  Widget _buildDamageAlert({
    required String tankId,
    required String type,
    required String building,
    required String floor,
    required String reportDate,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 3,
        child: ListTile(
          leading: const Icon(Icons.warning, color: Colors.red),
          title: Text('รหัสถัง: $tankId \nประเภทถัง: $type'),
          subtitle:
              Text('อาคาร: $building\nชั้น: $floor\nวันที่แจ้ง: $reportDate'),
          contentPadding: EdgeInsets.symmetric(
              horizontal: 10.0, vertical: 8.0), // ปรับ padding ภายใน
        ),
      ),
    );
  }
}
