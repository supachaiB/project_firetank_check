import 'package:flutter/material.dart';

class InspectionTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isUserView;
  bool get isTechnician =>
      !isUserView; // กำหนดให้ isTechnician ตรงข้ามกับ isUserView
  final Function(String, String, bool) onEditStatus;
  final Function(String, String) onDeleteTank;
  final String selectedBuilding;
  final String selectedFloor;
  final String selectedStatus;

  InspectionTable({
    required this.data,
    required this.isUserView,
    required this.onEditStatus,
    required this.onDeleteTank,
    required this.selectedBuilding,
    required this.selectedFloor,
    required this.selectedStatus,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
                DataColumn(label: Text('ประเภทถัง')), // เพิ่มคอลัมน์ประเภทถัง
                DataColumn(label: Text('อาคาร')),
                DataColumn(label: Text('ชั้น')),
                DataColumn(label: Text('วันที่ตรวจสอบ')),
                DataColumn(label: Text('ผู้ตรวจสอบ')),
                DataColumn(label: Text('ประเภทผู้ใช้')),
                DataColumn(label: Text('ผลการตรวจสอบ')),
                DataColumn(label: Text('หมายเหตุ')),
                DataColumn(label: Text('การกระทำ')),
              ],
              rows: data.map((inspection) {
                Color statusColor = Colors.grey;

                if (inspection['status'] == 'ตรวจสอบแล้ว') {
                  statusColor = Colors.green;
                } else if (inspection['status'] == 'ชำรุด') {
                  statusColor = Colors.red;
                } else if (inspection['status'] == 'ส่งซ่อม') {
                  statusColor = Colors.orange;
                }

                // เช็คสีจาก status_technician
                Color technicianStatusColor = Colors.grey;
                if (inspection['status_technician'] == 'ตรวจสอบแล้ว') {
                  technicianStatusColor = Colors.green;
                } else if (inspection['status_technician'] == 'ชำรุด') {
                  technicianStatusColor = Colors.red;
                } else if (inspection['status_technician'] == 'ส่งซ่อม') {
                  technicianStatusColor = Colors.orange;
                }

                return DataRow(
                  color:
                      MaterialStateColor.resolveWith((states) => Colors.white),
                  cells: [
                    DataCell(Text(inspection['tank_id']?.toString() ?? 'N/A')),
                    DataCell(Text(inspection['type']?.toString() ??
                        'N/A')), // แสดงประเภทถัง
                    DataCell(Text(inspection['building']?.toString() ?? 'N/A')),
                    DataCell(Text(inspection['floor']?.toString() ?? 'N/A')),
                    DataCell(
                        Text(inspection['date_checked']?.toString() ?? 'N/A')),
                    DataCell(
                        Text(inspection['inspector']?.toString() ?? 'N/A')),
                    DataCell(
                        Text(inspection['user_type']?.toString() ?? 'N/A')),
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
                                ? (inspection['status']?.toString() ??
                                    'N/A') // ผู้ใช้ทั่วไป
                                : (inspection['status_technician']
                                        ?.toString() ??
                                    'N/A'), // ช่างเทคนิค
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(inspection['remarks']?.toString() ?? 'N/A')),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              onEditStatus(
                                inspection['tank_id'] ?? '',
                                inspection['status'] ?? '',
                                isTechnician,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              onDeleteTank(
                                inspection['tank_id'] ?? '',
                                inspection['date_checked'] ?? '',
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
        ],
      ),
    );
  }
}
