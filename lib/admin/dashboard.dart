import 'package:flutter/material.dart';
import 'package:firecheck_setup/admin/dashboard_section/damage_info_section.dart';
//import 'package:firecheck_setup/admin/dashboard_section/status_summary.dart';
import 'package:firecheck_setup/admin/dashboard_section/scheduleBox.dart';
import 'package:firecheck_setup/admin/fire_tank_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int remainingTime = FireTankStatusPageState.calculateRemainingTime();
  int remainingQuarterTimeInSeconds =
      FireTankStatusPageState.calculateNextQuarterEnd()
          .difference(DateTime.now())
          .inSeconds;

  int totalTanks = 0;
  int checkedCount = 0;
  int brokenCount = 0;
  int repairCount = 0;
  int otherCount = 0;
  int uncheckedCount = 0;

  // ตัวแปรสำหรับ status_technician
  int checkedTechnicianCount = 0;
  int uncheckedTechnicianCount = 0;
  int brokenTechnicianCount = 0;
  int repairTechnicianCount = 0;

  // ดึงข้อมูลจาก Firestore
  void _fetchFireTankData() async {
    final totalSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .get();
    totalTanks = totalSnapshot.size;

    final checkedSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status', isEqualTo: 'ตรวจสอบแล้ว')
        .get();
    checkedCount = checkedSnapshot.size;

    final brokenSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status', isEqualTo: 'ชำรุด')
        .get();
    brokenCount = brokenSnapshot.size;

    final repairSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status', isEqualTo: 'ส่งซ่อม')
        .get();
    repairCount = repairSnapshot.size;

    final uncheckedSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status', isEqualTo: 'ยังไม่ตรวจสอบ')
        .get();
    uncheckedCount = uncheckedSnapshot.size;

    // ดึงข้อมูลสำหรับ status_technician
    final checkedTechnicianSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status_technician', isEqualTo: 'ตรวจสอบแล้ว')
        .get();
    checkedTechnicianCount = checkedTechnicianSnapshot.size;

    final uncheckedTechnicianSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status_technician', isEqualTo: 'ยังไม่ตรวจสอบ')
        .get();
    uncheckedTechnicianCount = uncheckedTechnicianSnapshot.size;

    final brokenTechnicianSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status_technician', isEqualTo: 'ชำรุด')
        .get();
    brokenTechnicianCount = brokenTechnicianSnapshot.size;

    final repairTechnicianSnapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('status_technician', isEqualTo: 'ส่งซ่อม')
        .get();
    repairTechnicianCount = repairTechnicianSnapshot.size;

    setState(() {}); // อัปเดตข้อมูลหลังจากดึงข้อมูลมา
  }

  @override
  void initState() {
    super.initState();
    _fetchFireTankData(); // ดึงข้อมูลเมื่อหน้าเริ่มต้น

    remainingQuarterTimeInSeconds =
        FireTankStatusPageState.calculateNextQuarterEnd()
            .difference(DateTime.now())
            .inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    double totalStatus =
        (checkedCount + brokenCount + repairCount + uncheckedCount).toDouble();
    double checkedPercentage = (checkedCount / totalStatus) * 100;
    double brokenPercentage = (brokenCount / totalStatus) * 100;
    double repairPercentage = (repairCount / totalStatus) * 100;
    double uncheckedPercentage = (uncheckedCount / totalStatus) * 100;

    double totalTechnicianStatus = (checkedTechnicianCount +
            brokenTechnicianCount +
            repairTechnicianCount +
            uncheckedTechnicianCount)
        .toDouble();
    double checkedTechnicianPercentage =
        (checkedTechnicianCount / totalTechnicianStatus) * 100;
    double brokenTechnicianPercentage =
        (brokenTechnicianCount / totalTechnicianStatus) * 100;
    double repairTechnicianPercentage =
        (repairTechnicianCount / totalTechnicianStatus) * 100;
    double uncheckedTechnicianPercentage =
        (uncheckedTechnicianCount / totalTechnicianStatus) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScheduleBox(
              remainingTime: remainingTime,
              remainingQuarterTime: remainingQuarterTimeInSeconds,
            ),
            const SizedBox(height: 10),

            // แถวของ 3 กล่อง
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // กล่อง 1 (ข้อมูลสถานะทั้งหมด)
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: boxDecorationStyle(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            'การตรวจสอบ(ผู้ใช้ทั่วไป)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text('ถังทั้งหมด: $totalTanks'),
                          Text('ตรวจสอบแล้ว: $checkedCount'),
                          Text('ยังไม่ตรวจสอบ: $uncheckedCount'),
                          Text('ชำรุด: $brokenCount'),
                          Text('ส่งซ่อม: $repairCount'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // กล่อง 2 (ข้อมูลจาก status_technician)
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: boxDecorationStyle(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            'การตรวจสอบ(ช่างเทคนิค)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text('ถังทั้งหมด: $totalTanks'),
                          Text('ตรวจสอบแล้ว: $checkedTechnicianCount'),
                          Text('ยังไม่ตรวจสอบ: $uncheckedTechnicianCount'),
                          Text('ชำรุด: $brokenTechnicianCount'),
                          Text('ส่งซ่อม: $repairTechnicianCount'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // กล่อง 3 (ข้อมูลการชำรุด) - มี ScrollView
                Expanded(
                  child: SizedBox(
                    height: 200, // ความสูงเท่ากัน
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: boxDecorationStyle(),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: DamageInfoSection(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // กล่อง 3 (ข้อมูลจาก status)
                Expanded(
                  child: SizedBox(
                    height: 300,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: boxDecorationStyle(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'สถานะการตรวจสอบ (ผู้ใช้ทั่วไป)',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Flexible(
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: checkedCount.toDouble(),
                                    title:
                                        '${checkedPercentage.toStringAsFixed(1)}%',
                                    color: Colors.green,
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: brokenCount.toDouble(),
                                    title:
                                        '${brokenPercentage.toStringAsFixed(1)}%',
                                    color: Colors.red,
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: repairCount.toDouble(),
                                    title:
                                        '${repairPercentage.toStringAsFixed(1)}%',
                                    color: Colors.orange,
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: uncheckedCount.toDouble(),
                                    title:
                                        '${uncheckedPercentage.toStringAsFixed(1)}%',
                                    color: Colors.grey,
                                    radius: 50,
                                  ),
                                ],
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: const [
                              LegendItem(
                                  color: Colors.green, text: 'ตรวจสอบแล้ว'),
                              LegendItem(color: Colors.red, text: 'ชำรุด'),
                              LegendItem(color: Colors.orange, text: 'ส่งซ่อม'),
                              LegendItem(
                                  color: Colors.grey, text: 'ยังไม่ตรวจสอบ'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30),

                // กล่อง 4 (ข้อมูลจาก status_technician)
                Expanded(
                  child: SizedBox(
                    height: 300,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: boxDecorationStyle(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'สถานะการตรวจสอบ (ช่างเทคนิค)',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Flexible(
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: checkedTechnicianCount.toDouble(),
                                    title:
                                        '${checkedTechnicianPercentage.toStringAsFixed(1)}%',
                                    color: Colors.green,
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: brokenTechnicianCount.toDouble(),
                                    title:
                                        '${brokenTechnicianPercentage.toStringAsFixed(1)}%',
                                    color: Colors.red,
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: repairTechnicianCount.toDouble(),
                                    title:
                                        '${repairTechnicianPercentage.toStringAsFixed(1)}%',
                                    color: Colors.orange,
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: uncheckedTechnicianCount.toDouble(),
                                    title:
                                        '${uncheckedTechnicianPercentage.toStringAsFixed(1)}%',
                                    color: Colors.grey,
                                    radius: 50,
                                  ),
                                ],
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: const [
                              LegendItem(
                                  color: Colors.green, text: 'ตรวจสอบแล้ว'),
                              LegendItem(color: Colors.red, text: 'ชำรุด'),
                              LegendItem(color: Colors.orange, text: 'ส่งซ่อม'),
                              LegendItem(
                                  color: Colors.grey, text: 'ยังไม่ตรวจสอบ'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// สร้างฟังก์ชันสำหรับตกแต่งกล่อง
BoxDecoration boxDecorationStyle() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 5,
        spreadRadius: 2,
      ),
    ],
  );
}

Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.grey[850], // เปลี่ยนเป็นสีเทาเข้ม
          ),
          child: Text(
            'เมนู',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Dashboard'),
          onTap: () {
            Navigator.pushNamed(context, '/');
          },
        ),
        /*ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('ตรวจสอบสถานะถัง'),
            onTap: () {
              Navigator.pushNamed(context, '/firetankstatus');
            },
          ),*/
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('ประวัติการตรวจสอบ'),
          onTap: () {
            Navigator.pushNamed(context, '/inspectionhistory');
          },
        ),
        ListTile(
          leading: const Icon(Icons.build),
          title: const Text('การจัดการถังดับเพลิง'),
          onTap: () {
            Navigator.pushNamed(context, '/fire_tank_management');
          },
        ),
        ListTile(
          leading: const Icon(Icons.apartment),
          title: const Text('การจัดการอาคาร'),
          onTap: () {
            Navigator.pushNamed(context, '/BuildingManagement');
          },
        ),
        ListTile(
          leading: const Icon(Icons.local_fire_department),
          title: const Text('ประเภทถังดับเพลิง'),
          onTap: () {
            Navigator.pushNamed(context, '/FireTankTypes');
          },
        ),
        const Divider(),
      ],
    ),
  );
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
