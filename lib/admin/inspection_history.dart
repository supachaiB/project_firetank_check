import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firecheck_setup/admin/fire_tank_status.dart';
import 'package:firecheck_setup/admin/dashboard_section/status_summary.dart';
import 'package:firecheck_setup/admin/dashboard_section/scheduleBox.dart';
import 'package:firecheck_setup/admin/dashboard_section/status_summary_tech.dart';
//import 'package:firecheck_setup/admin/fire_tank_status.dart';

class InspectionHistoryPage extends StatefulWidget {
  const InspectionHistoryPage({super.key});

  @override
  _InspectionHistoryPageState createState() => _InspectionHistoryPageState();
}

class _InspectionHistoryPageState extends State<InspectionHistoryPage> {
  String? selectedBuilding;
  String? selectedFloor;
  String? selectedStatus;
  String? sortBy = 'tank_number'; // เริ่มต้นการเรียงตามหมายเลขถัง
  bool isUserView = true; // true = ผู้ใช้ทั่วไป, false = ช่างเทคนิค
  bool get isTechnician =>
      !isUserView; // กำหนดให้ isTechnician ตรงข้ามกับ isUserView

  List<String> _buildings = [];
  List<String> _floors = [];
  List<Map<String, dynamic>> combinedData = [];

  int remainingTime = FireTankStatusPageState.calculateRemainingTime();
  int remainingQuarterTimeInSeconds =
      FireTankStatusPageState.calculateNextQuarterEnd()
          .difference(DateTime.now())
          .inSeconds;

  int totalTanks = 0;
  int checkedCount = 0;
  int brokenCount = 0;
  int repairCount = 0;

  int rowsPerPage = 10;
  int currentPage = 1; // ค่าเริ่มต้นของ currentPage

  // ดึงข้อมูลจาก Firestore
  void _fetchFireTankData() async {
    try {
      // ใช้ Future.wait เพื่อทำคิวรีพร้อมกันและรอให้เสร็จ
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('firetank_Collection').get(),
        FirebaseFirestore.instance
            .collection('firetank_Collection')
            .where('status', isEqualTo: 'ตรวจสอบแล้ว')
            .get(),
        FirebaseFirestore.instance
            .collection('firetank_Collection')
            .where('status', isEqualTo: 'ชำรุด')
            .get(),
        FirebaseFirestore.instance
            .collection('firetank_Collection')
            .where('status', isEqualTo: 'ส่งซ่อม')
            .get(),
      ]);

      // กำหนดค่าผลลัพธ์จาก Future
      final totalSnapshot = results[0];
      totalTanks = totalSnapshot.size;

      final checkedSnapshot = results[1];
      checkedCount = checkedSnapshot.size;

      final brokenSnapshot = results[2];
      brokenCount = brokenSnapshot.size;

      final repairSnapshot = results[3];
      repairCount = repairSnapshot.size;

      setState(() {}); // อัปเดตข้อมูลหลังจากดึงข้อมูลมา
    } catch (e) {
      // หากเกิดข้อผิดพลาดใดๆ แสดงข้อความ
      print("Error fetching fire tank data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchFireTankData(); // ดึงข้อมูลเมื่อหน้าเริ่มต้น
    fetchBuildings();

    remainingQuarterTimeInSeconds =
        FireTankStatusPageState.calculateNextQuarterEnd()
            .difference(DateTime.now())
            .inSeconds;
  }

  Future<void> fetchBuildings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .get();

      if (snapshot.docs.isEmpty) {
        print('ไม่มีข้อมูลใน collection firetank_Collection');
        return;
      }

      final buildings = snapshot.docs
          .where((doc) => doc
              .data()
              .containsKey('building')) // ตรวจสอบว่ามีฟิลด์ 'building'
          .map((doc) => doc['building'] as String)
          .toSet()
          .toList();

      setState(() {
        _buildings = buildings;
      });
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงข้อมูล: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการดึงข้อมูลจาก Firestore'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// ดึงรายชื่อชั้นของอาคารที่เลือก
  Future<void> fetchFloors(String building) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('building', isEqualTo: building)
        .get();

    final floors = snapshot.docs
        .map((doc) => doc['floor'].toString()) // แปลงเป็น String
        .toSet()
        .toList();

    floors.sort(
        (a, b) => int.parse(a).compareTo(int.parse(b))); // เรียงจากน้อยไปมาก

    setState(() {
      _floors = floors;
      selectedFloor = null;
    });
  }

  // ฟังก์ชันสำหรับการแก้ไขสถานะการตรวจสอบ
  Future<void> _updateStatus(
      String tankId, String newStatus, bool isTechnician) async {
    try {
      // ค้นหาถังที่มี tank_id ตรงกับที่ระบุ
      var docSnapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .where('tank_id', isEqualTo: tankId)
          .get();

      if (docSnapshot.docs.isNotEmpty) {
        var docRef = docSnapshot.docs.first.reference;

        // ถ้าเป็นช่างเทคนิค ให้อัปเดตเฉพาะฟิลด์ status_technician
        if (isTechnician) {
          await docRef.update({'status_technician': newStatus});
        } else {
          await docRef.update({'status': newStatus});
        }

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สถานะได้รับการอัปเดต')));
      } else {
        throw Exception('ไม่พบถังที่มี tank_id: $tankId');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  Future<void> _deleteTank(String tankId, String dateChecked) async {
    try {
      // 1️⃣ ค้นหาเอกสาร form_checks ที่ตรงกับ tank_id และ date_checked
      var formCheckDocs = await FirebaseFirestore.instance
          .collection('form_checks')
          .where('tank_id', isEqualTo: tankId)
          .where('date_checked', isEqualTo: dateChecked)
          .get();

      if (formCheckDocs.docs.isEmpty) {
        debugPrint(
            "ไม่พบข้อมูลที่ต้องการลบ tank_id: $tankId, date_checked: $dateChecked");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลที่ต้องการลบ')));
        return;
      }

      // 2️⃣ หาเอกสารที่มี time_checked ล่าสุด
      QueryDocumentSnapshot<Map<String, dynamic>> latestDoc =
          formCheckDocs.docs.first;

      for (var doc in formCheckDocs.docs) {
        String aTimeChecked = latestDoc['time_checked'] as String;
        String bTimeChecked = doc['time_checked'] as String;

        if (aTimeChecked.compareTo(bTimeChecked) < 0) {
          latestDoc = doc;
        }
      }

      // 3️⃣ ลบเอกสารที่มี time_checked ล่าสุด
      debugPrint(
          "ลบเอกสารที่มี time_checked ล่าสุด: ${latestDoc['time_checked']}");
      await latestDoc.reference.delete();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข้อมูลการตรวจสอบล่าสุดเรียบร้อย')));

      // 4️⃣ อัปเดต UI โดยการลบข้อมูลออกจาก DataTable เฉพาะจากหน้าที่กำลังใช้งาน
      setState(() {
        if (isTechnician) {
          // ลบข้อมูลที่เกี่ยวข้องในหน้า Technician
          combinedData = combinedData
              .where((inspection) =>
                  inspection['tank_id'] != tankId ||
                  inspection['date_checked'] != dateChecked ||
                  inspection['time_checked'] != latestDoc['time_checked'])
              .toList();
        } else {
          // ลบข้อมูลที่เกี่ยวข้องในหน้า UserView
          combinedData = combinedData
              .where((inspection) =>
                  inspection['tank_id'] != tankId ||
                  inspection['date_checked'] != dateChecked ||
                  inspection['time_checked'] != latestDoc['time_checked'])
              .toList();
        }
      });

      debugPrint("ข้อมูลการตรวจสอบที่อัปเดตใหม่: $combinedData");

      // 5️⃣ ค้นหาเอกสาร form_checks ที่ใหม่ที่สุดหลังจากลบ
      var remainingDocs = await FirebaseFirestore.instance
          .collection('form_checks')
          .where('tank_id', isEqualTo: tankId)
          .orderBy('date_checked', descending: true)
          .orderBy('time_checked', descending: true) // เลือกข้อมูลที่ใหม่ที่สุด
          .limit(1)
          .get();

      if (remainingDocs.docs.isNotEmpty) {
        var doc = remainingDocs.docs.first;

        // เลือกใช้ 'status' หรือ 'status_technician' ตามที่ต้องการ
        var latestStatus = doc.data().containsKey('status')
            ? doc['status']
            : (doc.data().containsKey('status_technician')
                ? doc['status_technician']
                : 'ไม่มีข้อมูล');

        // อัปเดตสถานะใน firetank_Collection
        var firetankDoc = await FirebaseFirestore.instance
            .collection('firetank_Collection')
            .where('tank_id', isEqualTo: tankId)
            .get();

        if (firetankDoc.docs.isNotEmpty) {
          // ถ้าเป็นหน้าช่างเทคนิค ให้ปรับอัปเดต `status_technician`
          if (isTechnician) {
            await firetankDoc.docs.first.reference.update({
              'status_technician': latestStatus, // อัปเดตสถานะเฉพาะช่างเทคนิค
            });
          } else {
            // ถ้าเป็นหน้าผู้ใช้ทั่วไป ให้ปรับอัปเดต `status`
            await firetankDoc.docs.first.reference.update({
              'status': latestStatus, // อัปเดตสถานะเฉพาะผู้ใช้ทั่วไป
            });
          }

          debugPrint(
              "สถานะใน firetank_Collection ได้รับการอัปเดตเป็น: $latestStatus");

          // แสดงสถานะล่าสุดจาก form_checks
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('สถานะล่าสุดจาก form_checks: $latestStatus')));
        }
      } else {
        // เช็คว่าในกรณีที่ไม่มีข้อมูลใน form_checks และเป็นหน้าช่างเทคนิค
        if (remainingDocs.docs.isEmpty) {
          var firetankDoc = await FirebaseFirestore.instance
              .collection('firetank_Collection')
              .where('tank_id', isEqualTo: tankId)
              .get();

          if (firetankDoc.docs.isNotEmpty) {
            // ถ้าเป็นหน้าช่างเทคนิค ให้รีเซ็ต `status_technician`
            if (isTechnician) {
              await firetankDoc.docs.first.reference.update({
                'status_technician': 'ยังไม่ตรวจสอบ', // รีเซ็ตสถานะช่างเทคนิค
              });
            } else {
              // ถ้าเป็นหน้าผู้ใช้ทั่วไป ให้รีเซ็ต `status`
              await firetankDoc.docs.first.reference.update({
                'status': 'ยังไม่ตรวจสอบ', // รีเซ็ตสถานะผู้ใช้ทั่วไป
              });
            }
          }
          debugPrint(
              "สถานะใน firetank_Collection ได้รับการรีเซ็ตเป็น 'ยังไม่ตรวจสอบ'");

          // แสดงสถานะเป็นยังไม่ตรวจสอบ
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่มีข้อมูลใน form_checks')));
        }
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาด: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  // ฟังก์ชันรีเซ็ตสถานะถังดับเพลิง
  void resetStatus(String userType, BuildContext context) async {
    String fieldName =
        userType == 'General User' ? 'status' : 'status_technician';
    CollectionReference firetankCollection =
        FirebaseFirestore.instance.collection('firetank_Collection');

    QuerySnapshot snapshot = await firetankCollection.get();

    bool alreadyNotified = false; // ป้องกันแจ้งเตือนซ้ำ
    bool technicianStatusNotifiable =
        false; // สำหรับเช็คว่า Technician สามารถรีเซ็ตได้หรือไม่

    for (var doc in snapshot.docs) {
      String docId = doc.id;
      DocumentReference historyRef = firetankCollection
          .doc(docId)
          .collection('reset_history')
          .doc(userType);

      DocumentSnapshot historySnapshot = await historyRef.get();

      DateTime nextAllowedReset;

      if (historySnapshot.exists) {
        Timestamp lastResetTime = historySnapshot['timestamp'];
        DateTime lastResetDate = lastResetTime.toDate();

        if (userType == 'General User') {
          // รีเซ็ตได้ทุกเดือน → วันที่ 1 ของเดือนถัดไป
          nextAllowedReset =
              DateTime(lastResetDate.year, lastResetDate.month + 1, 1);
        } else {
          // รีเซ็ตได้ทุก 3 เดือน → วันที่ 1 ของไตรมาสถัดไป
          int nextQuarterMonth = ((lastResetDate.month - 1) ~/ 3 + 1) * 3 + 1;
          int nextQuarterYear =
              lastResetDate.year + (nextQuarterMonth > 12 ? 1 : 0);
          nextQuarterMonth = (nextQuarterMonth > 12) ? 1 : nextQuarterMonth;
          nextAllowedReset = DateTime(nextQuarterYear, nextQuarterMonth, 1);

          technicianStatusNotifiable = DateTime.now().isAfter(nextAllowedReset);
        }

        if (DateTime.now().isBefore(nextAllowedReset)) {
          if (!alreadyNotified) {
            alreadyNotified = true;
            int remainingDays =
                nextAllowedReset.difference(DateTime.now()).inDays;
            String message = userType == 'General User'
                ? 'ไม่สามารถรีเซ็ตได้สถานะผู้ใช้ทั่วไป เหลืออีก $remainingDays วัน'
                : 'ไม่สามารถรีเซ็ตสถานะช่างเทคนิค เหลืออีก $remainingDays วัน';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
          continue;
        }
      }

      // อัปเดตสถานะ
      await firetankCollection.doc(docId).update({
        fieldName: 'ยังไม่ตรวจสอบ',
      });

      // บันทึกเวลาการรีเซ็ต
      await historyRef.set({
        'timestamp': Timestamp.now(),
        'reset_by': userType,
      });
    }

    if (!alreadyNotified) {
      // ถ้า Technician สามารถรีเซ็ตได้
      if (technicianStatusNotifiable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('รีเซ็ตสถานะช่างเทคนิคสำเร็จ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('รีเซ็ตสถานะผู้ใช้ทั่วไปสำเร็จ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ประวัติการตรวจสอบ',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[700],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              resetStatus(
                  'General User', context); // รีเซ็ตสถานะของ General User
              resetStatus('Technician', context); // รีเซ็ตสถานะของ Technician
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'รีเซ็ตสถานะทั้งหมด',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // จัดตำแหน่งกลาง
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // ใช้เพื่อจัดตำแหน่งกลาง
                  children: [
                    Expanded(
                      // ให้ ScheduleBox ขยายพื้นที่ตามที่เหลือ
                      child: ScheduleBox(
                        remainingTime: remainingTime,
                        remainingQuarterTime: remainingQuarterTimeInSeconds,
                      ),
                    ),

                    // เพิ่ม Spacer() ก่อน StatusSummaryWidget
                    Spacer(), // เพิ่มเพื่อให้ StatusSummaryWidget อยู่กลาง
                    Offstage(
                      offstage:
                          !isUserView, // ซ่อน StatusSummaryWidget เมื่อเลือกเป็นช่างเทคนิค
                      child: StatusSummaryWidget(
                        totalTanks: totalTanks,
                        checkedCount: checkedCount,
                        brokenCount: brokenCount,
                        repairCount: repairCount,
                      ),
                    ),

                    // เพิ่ม Spacer() ก่อน StatusSummaryTech
                    Spacer(), // เพิ่มเพื่อให้ StatusSummaryTech อยู่กลาง
                    Offstage(
                      offstage:
                          isUserView, // ซ่อน StatusSummaryTech เมื่อเลือกเป็นผู้ใช้ทั่วไป
                      child: StatusSummaryTech(),
                    ),

                    ToggleButtons(
                      isSelected: [isUserView, isTechnician],
                      onPressed: (index) {
                        setState(() {
                          isUserView = index == 0;
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('ผู้ใช้ทั่วไป'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('ช่างเทคนิค'),
                        ),
                      ],
                    ),
                  ],
                ),

                // ส่วนตัวกรอง
                Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  color: Colors.white, // เปลี่ยนพื้นหลังเป็นสีขาว

                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ค้นหาและจัดเรียงข้อมูล',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                hint: const Text('เลือกอาคาร'),
                                value: selectedBuilding,
                                onChanged: (value) {
                                  setState(() {
                                    selectedBuilding = value;
                                    selectedFloor = null;
                                    fetchFloors(
                                        value!); // อัปเดตรายชื่อชั้นเมื่อเลือกอาคาร
                                  });
                                },
                                items: _buildings
                                    .map((building) => DropdownMenuItem<String>(
                                          value: building,
                                          child: Text(building),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: DropdownButton<String>(
                                hint: const Text('เลือกชั้น'),
                                value: selectedFloor,
                                onChanged: (value) {
                                  setState(() {
                                    selectedFloor = value;
                                  });
                                },
                                items: _floors
                                    .map((floor) => DropdownMenuItem<String>(
                                          value: floor,
                                          child: Text(floor),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedStatus,
                                isExpanded: true,
                                hint: const Text('เลือกสถานะการตรวจสอบ'),
                                items: [
                                  'ตรวจสอบแล้ว',
                                  'ส่งซ่อม',
                                  'ชำรุด',
                                  'ยังไม่ตรวจสอบ',
                                ].map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedStatus = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(
                                width:
                                    10), // เพิ่มช่องว่างระหว่าง Dropdown กับปุ่ม
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedBuilding = null;
                                  selectedFloor = null;
                                  selectedStatus =
                                      null; // รีเซ็ตสถานะการตรวจสอบ
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.blue, // เปลี่ยนพื้นหลังเป็นสีฟ้า
                              ),
                              child: const Text(
                                'รีเซ็ตตัวกรองทั้งหมด',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // ส่วนแสดงข้อมูล
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('firetank_Collection')
                      .snapshots(),
                  builder: (context, firetankSnapshot) {
                    if (firetankSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!firetankSnapshot.hasData ||
                        firetankSnapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('ไม่มีข้อมูลใน Firetank Collection'));
                    }

                    List<Map<String, dynamic>> firetankData = firetankSnapshot
                        .data!.docs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .toList();

                    // ดึงข้อมูลจาก form_checks
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('form_checks')
                          .orderBy('time_checked', descending: true)
                          .snapshots(),
                      builder: (context, formChecksSnapshot) {
                        if (formChecksSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!formChecksSnapshot.hasData ||
                            formChecksSnapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text('ไม่มีข้อมูลใน Form Checks'));
                        }

// ดึงข้อมูลล่าสุดสำหรับ tank_id แต่ละรายการ
                        Map<String, Map<String, dynamic>> latestFormChecks = {};
                        for (var doc in formChecksSnapshot.data!.docs) {
                          Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;
                          String tankId = data['tank_id'] ?? 'N/A';

                          // เก็บข้อมูลล่าสุดของแต่ละ tank_id
                          if (!latestFormChecks.containsKey(tankId)) {
                            latestFormChecks[tankId] = data;
                          }
                        }
                        List<Map<String, dynamic>> formChecksData =
                            formChecksSnapshot.data!.docs
                                .map(
                                    (doc) => doc.data() as Map<String, dynamic>)
                                .toList();

                        // รวมข้อมูลจากทั้งสอง collection โดยใช้วันที่ตรวจสอบล่าสุด
                        List<Map<String, dynamic>> combinedData =
                            firetankData.map((firetank) {
                          String tankId = firetank['tank_id'] ?? 'N/A';

                          // หา form_check ที่มี date_checked ล่าสุดและ tank_id ตรงกัน
                          var relevantFormChecks = formChecksData.where(
                              (check) =>
                                  check['tank_id'] == tankId &&
                                  check['user_type'] ==
                                      (isUserView
                                          ? 'ผู้ใช้ทั่วไป'
                                          : 'ช่างเทคนิค'));
                          var latestFormCheck = relevantFormChecks.isNotEmpty
                              ? relevantFormChecks.reduce((a, b) {
                                  DateTime dateTimeA = DateTime.tryParse(
                                          '${a['date_checked']} ${a['time_checked'] ?? '00:00:00'}') ??
                                      DateTime.fromMillisecondsSinceEpoch(0);
                                  DateTime dateTimeB = DateTime.tryParse(
                                          '${b['date_checked']} ${b['time_checked'] ?? '00:00:00'}') ??
                                      DateTime.fromMillisecondsSinceEpoch(0);
                                  return dateTimeA.isAfter(dateTimeB) ? a : b;
                                })
                              : {
                                  'date_checked': 'N/A',
                                  'time_checked': 'N/A',
                                  'inspector': 'N/A',
                                  'user_type': 'N/A',
                                  'status': 'N/A',
                                  'status_technician': 'N/A',
                                  'remarks': 'N/A'
                                };

                          return {
                            'tank_id': tankId,
                            'type': firetank['type']?.toString() ??
                                'N/A', // เพิ่มประเภทถัง

                            'building': firetank['building']?.toString() ??
                                'N/A', // แปลงเป็น String
                            'floor': firetank['floor']?.toString() ??
                                'N/A', // แปลงเป็น String
                            'date_checked':
                                latestFormCheck['date_checked']?.toString() ??
                                    'N/A', // แปลงเป็น String
                            'inspector':
                                latestFormCheck['inspector']?.toString() ??
                                    'N/A', // แปลงเป็น String
                            'user_type':
                                latestFormCheck['user_type']?.toString() ??
                                    'N/A', // แปลงเป็น String
                            'status': firetank['status']?.toString() ??
                                'N/A', // แปลงเป็น String
                            'status_technician':
                                firetank['status_technician']?.toString() ??
                                    'N/A',
                            'remarks': latestFormCheck['remarks']?.toString() ??
                                'N/A', // แปลงเป็น String
                          };
                        }).toList();

                        // การจัดเรียงข้อมูลตามหมายเลขถัง (จาก FE001 ไป FE002)
                        combinedData.sort((a, b) {
                          String tankIdA = a['tank_id'] ?? 'N/A';
                          String tankIdB = b['tank_id'] ?? 'N/A';

                          // แปลง FE001 เป็น 1, FE002 เป็น 2, และอื่น ๆ โดยใช้เลขที่อยู่หลัง FE
                          int numberA =
                              int.tryParse(tankIdA.replaceFirst('FE', '')) ?? 0;
                          int numberB =
                              int.tryParse(tankIdB.replaceFirst('FE', '')) ?? 0;

                          return numberA
                              .compareTo(numberB); // จัดเรียงจากน้อยไปหามาก
                        });

                        // กรองข้อมูลตามตัวเลือก
                        if (selectedBuilding != null &&
                            selectedBuilding!.isNotEmpty) {
                          combinedData = combinedData.where((inspection) {
                            return inspection['building'] == selectedBuilding;
                          }).toList();
                        }
                        if (selectedFloor != null &&
                            selectedFloor!.isNotEmpty) {
                          combinedData = combinedData.where((inspection) {
                            return inspection['floor'] == selectedFloor;
                          }).toList();
                        }
                        if (selectedStatus != null &&
                            selectedStatus!.isNotEmpty) {
                          combinedData = combinedData.where((inspection) {
                            return inspection['status'] == selectedStatus;
                          }).toList();
                        }

                        // การจัดเรียงข้อมูล
                        if (sortBy == 'tank_number') {
                          combinedData.sort((a, b) {
                            return a['tank_id'].compareTo(b['tank_id']);
                          });
                        }

// ปรับให้แสดงข้อมูลตามหน้า (Pagination)

                        int totalRows = combinedData.length;
                        int totalPages = (totalRows / rowsPerPage)
                            .ceil(); // คำนวณ totalPages ให้ถูกต้อง

// คำนวณ startIndex และ endIndex ตาม currentPage
                        final int startIndex = (currentPage - 1) * rowsPerPage;
                        final int endIndex =
                            (currentPage * rowsPerPage) > totalRows
                                ? totalRows
                                : (currentPage * rowsPerPage);

                        List<Map<String, dynamic>> currentPageData =
                            combinedData.sublist(startIndex, endIndex);

                        return SingleChildScrollView(
                          child: Column(children: [
                            Container(
                              margin: EdgeInsets.all(16), // เพิ่มระยะขอบ
                              padding: EdgeInsets.all(12), // เพิ่มระยะภายใน
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DataTable(
                                headingRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.blueGrey.shade50,
                                ),
                                dataRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.white,
                                ),
                                columns: const [
                                  DataColumn(label: Text('หมายเลขถัง')),
                                  DataColumn(
                                      label: Text(
                                          'ประเภทถัง')), // เพิ่มคอลัมน์ประเภทถัง

                                  DataColumn(label: Text('อาคาร')),
                                  DataColumn(label: Text('ชั้น')),
                                  DataColumn(label: Text('วันที่ตรวจสอบ')),
                                  DataColumn(label: Text('ผู้ตรวจสอบ')),
                                  DataColumn(label: Text('ประเภทผู้ใช้')),
                                  DataColumn(label: Text('ผลการตรวจสอบ')),
                                  DataColumn(label: Text('หมายเหตุ')),
                                  DataColumn(label: Text('การกระทำ')),
                                ],
                                rows: currentPageData.map((inspection) {
                                  Color statusColor = Colors.grey;

                                  if (inspection['status'] == 'ตรวจสอบแล้ว') {
                                    statusColor = Colors.green;
                                  } else if (inspection['status'] == 'ชำรุด') {
                                    statusColor = Colors.red;
                                  } else if (inspection['status'] ==
                                      'ส่งซ่อม') {
                                    statusColor = Colors.orange;
                                  }

                                  // เช็คสีจาก status_technician
                                  Color technicianStatusColor = Colors.grey;
                                  if (inspection['status_technician'] ==
                                      'ตรวจสอบแล้ว') {
                                    technicianStatusColor = Colors.green;
                                  } else if (inspection['status_technician'] ==
                                      'ชำรุด') {
                                    technicianStatusColor = Colors.red;
                                  } else if (inspection['status_technician'] ==
                                      'ส่งซ่อม') {
                                    technicianStatusColor = Colors.orange;
                                  }

                                  return DataRow(
                                    color: MaterialStateColor.resolveWith(
                                        (states) => Colors.white),
                                    cells: [
                                      DataCell(Text(
                                          inspection['tank_id']?.toString() ??
                                              'N/A')),
                                      DataCell(Text(
                                          inspection['type']?.toString() ??
                                              'N/A')), // แสดงประเภทถัง

                                      DataCell(Text(
                                          inspection['building']?.toString() ??
                                              'N/A')),
                                      DataCell(Text(
                                          inspection['floor']?.toString() ??
                                              'N/A')),
                                      DataCell(Text(inspection['date_checked']
                                              ?.toString() ??
                                          'N/A')),
                                      DataCell(Text(
                                          inspection['inspector']?.toString() ??
                                              'N/A')),
                                      DataCell(Text(
                                          inspection['user_type']?.toString() ??
                                              'N/A')),
                                      DataCell(
                                        Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: isUserView
                                                    ? statusColor
                                                    : technicianStatusColor, // ใช้สีที่แตกต่างตามประเภทผู้ใช้
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              isUserView
                                                  ? (inspection['status']
                                                          ?.toString() ??
                                                      'N/A') // ผู้ใช้ทั่วไป
                                                  : (inspection[
                                                              'status_technician']
                                                          ?.toString() ??
                                                      'N/A'), // ช่างเทคนิค
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(
                                          inspection['remarks']?.toString() ??
                                              'N/A')),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () {
                                                _showStatusDialog(
                                                    inspection['tank_id'] ?? '',
                                                    inspection['status'] ?? '',
                                                    isTechnician);
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () {
                                                _showDeleteConfirmationDialog(
                                                  inspection['tank_id'] ?? '',
                                                  inspection['date_checked'] ??
                                                      '',
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),

                            // ปุ่มเปลี่ยนหน้า
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: () {
                                    if (currentPage > 1) {
                                      setState(() {
                                        currentPage--;
                                        print("Previous page: $currentPage");
                                      });
                                    }
                                  },
                                ),
                                Text('$currentPage of $totalPages'),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () {
                                    if (currentPage < totalPages) {
                                      setState(() {
                                        currentPage++;
                                        print("Next page: $currentPage");
                                        print(
                                            "Start Index: $startIndex, End Index: $endIndex");
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ]),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ฟังก์ชันแจ้งเตือนการลบ
  void _showDeleteConfirmationDialog(String tankId, String dateChecked) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text(
              'คุณต้องการลบข้อมูลของถัง $tankId ที่วันที่ตรวจสอบ $dateChecked หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                // ถ้าผู้ใช้เลือก "ยืนยัน"
                Navigator.pop(context); // ปิด Dialog
                _deleteTank(tankId, dateChecked); // เรียกฟังก์ชันลบ
              },
              child: const Text('ยืนยัน'),
            ),
            TextButton(
              onPressed: () {
                // ถ้าผู้ใช้เลือก "ยกเลิก"
                Navigator.pop(context); // ปิด Dialog
              },
              child: const Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
  }

  // Dialog ให้ผู้ใช้เลือกสถานะใหม่
  void _showStatusDialog(
      String tankId, String currentStatus, bool isTechnician) {
    String? newStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // ✅ ใช้ StatefulBuilder เพื่ออัปเดตค่า Dropdown
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('เลือกสถานะใหม่'),
              content: DropdownButton<String>(
                value: newStatus,
                isExpanded: true,
                items: ['ตรวจสอบแล้ว', 'ส่งซ่อม', 'ชำรุด', 'ยังไม่ตรวจสอบ']
                    .map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    newStatus = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (newStatus != null) {
                      _updateStatus(tankId, newStatus!,
                          isTechnician); // ✅ แก้ไขให้ส่ง isTechnician ถูกต้อง
                      Navigator.pop(context); // ✅ ปิด dialog อย่างปลอดภัย
                    }
                  },
                  child: const Text('บันทึก'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('ยกเลิก'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
