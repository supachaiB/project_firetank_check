import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FilterWidget extends StatefulWidget {
  final String? selectedBuilding;
  final String? selectedFloor;
  final String? selectedStatus;
  final ValueChanged<String?> onBuildingChanged;
  final ValueChanged<String?> onFloorChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onReset;

  const FilterWidget({
    Key? key,
    required this.selectedBuilding,
    required this.selectedFloor,
    required this.selectedStatus,
    required this.onBuildingChanged,
    required this.onFloorChanged,
    required this.onStatusChanged,
    required this.onReset,
  }) : super(key: key);

  @override
  _FilterWidgetState createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  bool _isCollapsed = false;

  List<String> _buildings = [];
  List<String> _floors = [];

  @override
  void initState() {
    super.initState();
    fetchBuildings(); // ดึงข้อมูลอาคารเมื่อเริ่มต้น
  }

  Future<void> fetchBuildings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .get();

    final buildings = snapshot.docs
        .map((doc) => doc['building'].toString()) // แปลงเป็น String
        .toSet()
        .toList();

    setState(() {
      _buildings = buildings;
    });
  }

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white, // เปลี่ยนพื้นหลังเป็นสีขาว
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ค้นหาและจัดเรียงข้อมูล',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(
                    _isCollapsed
                        ? Icons.expand_more
                        : Icons.expand_less, // เปลี่ยนไอคอนระหว่างขยายและย่อ
                    color: Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed; // สลับสถานะการซ่อน/แสดง
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 750;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isCollapsed) ...[
                      // ถ้าสถานะเป็น false (ไม่ซ่อน), แสดงตัวกรอง
                      if (isMobile) ...[
                        // ถ้าหน้าจอเล็กกว่า 700px, ใช้ Column
                        DropdownButton<String>(
                          hint: const Text('เลือกอาคาร',
                              style: TextStyle(fontSize: 14)),
                          value: widget.selectedBuilding,
                          onChanged: (building) {
                            widget.onBuildingChanged(building);
                            if (building != null) {
                              fetchFloors(building);
                            }
                          },
                          items: _buildings
                              .map((building) => DropdownMenuItem<String>(
                                    value: building,
                                    child: Text(building,
                                        style: TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          hint: const Text('เลือกชั้น',
                              style: TextStyle(fontSize: 14)),
                          value: widget.selectedFloor,
                          onChanged: widget.onFloorChanged,
                          items: _floors
                              .map((floor) => DropdownMenuItem<String>(
                                    value: floor,
                                    child: Text(floor,
                                        style: TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: widget.selectedStatus,
                          isExpanded: true,
                          hint: const Text('เลือกสถานะการตรวจสอบ',
                              style: TextStyle(fontSize: 14)),
                          items: [
                            'ตรวจสอบแล้ว',
                            'ส่งซ่อม',
                            'ชำรุด',
                            'ยังไม่ตรวจสอบ',
                          ].map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child:
                                  Text(status, style: TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: widget.onStatusChanged,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: widget.onReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text(
                            'รีเซ็ตตัวกรองทั้งหมด',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ] else ...[
                        // ถ้าหน้าจอใหญ่กว่า 700px, ใช้ Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                hint: const Text('เลือกอาคาร',
                                    style: TextStyle(fontSize: 16)),
                                value: widget.selectedBuilding,
                                onChanged: (building) {
                                  widget.onBuildingChanged(building);
                                  if (building != null) {
                                    fetchFloors(building);
                                  }
                                },
                                items: _buildings
                                    .map((building) => DropdownMenuItem<String>(
                                          value: building,
                                          child: Text(building,
                                              style: TextStyle(fontSize: 16)),
                                        ))
                                    .toList(),
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Colors.black),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: DropdownButton<String>(
                                hint: const Text('เลือกชั้น',
                                    style: TextStyle(fontSize: 16)),
                                value: widget.selectedFloor,
                                onChanged: widget.onFloorChanged,
                                items: _floors
                                    .map((floor) => DropdownMenuItem<String>(
                                          value: floor,
                                          child: Text(floor,
                                              style: TextStyle(fontSize: 16)),
                                        ))
                                    .toList(),
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Colors.black),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: DropdownButton<String>(
                                value: widget.selectedStatus,
                                isExpanded: true,
                                hint: const Text('เลือกสถานะการตรวจสอบ',
                                    style: TextStyle(fontSize: 16)),
                                items: [
                                  'ตรวจสอบแล้ว',
                                  'ส่งซ่อม',
                                  'ชำรุด',
                                  'ยังไม่ตรวจสอบ',
                                ].map((status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status,
                                        style: TextStyle(fontSize: 16)),
                                  );
                                }).toList(),
                                onChanged: widget.onStatusChanged,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Colors.black),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: widget.onReset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text(
                                'รีเซ็ตตัวกรองทั้งหมด',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ]
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
