import 'package:firecheck_setup/admin/EditFireTank.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // สำหรับเปิด URL

class FireTankManagementPage extends StatefulWidget {
  const FireTankManagementPage({Key? key}) : super(key: key);

  @override
  _FireTankManagementPageState createState() => _FireTankManagementPageState();
}

class _FireTankManagementPageState extends State<FireTankManagementPage> {
  bool _isCollapsed = false; // ตัวแปรในการซ่อน/แสดง

  String? _selectedBuilding;
  String? _selectedFloor;
  String? _selectedType;
  String _searchTankId = '';

  List<String> _buildings = [];
  List<String> _floors = [];

  List<String> _types = [];

  @override
  void initState() {
    super.initState();
    fetchBuildings();
    _fetchTypes();
  }

  Future<void> _fetchTypes() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('FE_type').get();
      setState(() {
        _types = snapshot.docs
            .map((doc) => doc['type'].toString())
            .toList(); // ดึงข้อมูลประเภทและเพิ่มลงใน _typeList
      });
    } catch (e) {
      print('Error fetching types: $e');
    }
  }

  Future<void> fetchBuildings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .get();

      // ตรวจสอบว่าเอกสารมีฟิลด์ 'building' หรือไม่
      final buildings = snapshot.docs
          .where((doc) => doc
              .data()
              .containsKey('building')) // ตรวจสอบว่าเอกสารมีฟิลด์ 'building'
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
      _selectedFloor = null;
    });
  }

  // ฟังก์ชันแสดงการยืนยันการลบ
  void _confirmDelete(BuildContext context, String tankId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบถังดับเพลิงนี้?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('firetank_Collection')
                  .doc(tankId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ลบข้อมูลสำเร็จ')),
              );
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // ปรับสีพื้นหลังนอก Container

      appBar: AppBar(
        title: const Text(
          'การจัดการถังดับเพลิง',
          style: TextStyle(color: Colors.white), // เปลี่ยนสีข้อความเป็นสีขาว
        ),
        backgroundColor: Colors.grey[700],
        iconTheme:
            const IconThemeData(color: Colors.white), // เปลี่ยนสีไอคอนเป็นสีขาว
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // ตัวกรอง
            LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ปุ่มไอคอนเพื่อซ่อน/แสดง
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ค้นหาและจัดเรียงข้อมูล',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(
                                _isCollapsed
                                    ? Icons.expand_more
                                    : Icons.expand_less,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isCollapsed = !_isCollapsed;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!_isCollapsed) ...[
                          // แสดงฟอร์มเมื่อ _isCollapsed เป็น false
                          isMobile
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2.0, horizontal: 16.0),
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        hint: const Text('เลือกอาคาร'),
                                        value: _selectedBuilding,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedBuilding = value;
                                            _selectedFloor = null;
                                            fetchFloors(value!);
                                          });
                                        },
                                        items: _buildings
                                            .map((building) =>
                                                DropdownMenuItem<String>(
                                                  value: building,
                                                  child: Text(building),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2.0, horizontal: 16.0),
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        hint: const Text('เลือกชั้น'),
                                        value: _selectedFloor,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedFloor = value;
                                          });
                                        },
                                        items: _floors
                                            .map((floor) =>
                                                DropdownMenuItem<String>(
                                                  value: floor,
                                                  child: Text(floor),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2.0, horizontal: 16.0),
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        hint: const Text('เลือกประเภท'),
                                        value: _selectedType,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedType = value;
                                          });
                                        },
                                        items: _types
                                            .map((type) =>
                                                DropdownMenuItem<String>(
                                                  value: type,
                                                  child: Text(type),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3.0, horizontal: 16.0),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          hint: const Text('เลือกอาคาร'),
                                          value: _selectedBuilding,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedBuilding = value;
                                              _selectedFloor = null;
                                              fetchFloors(value!);
                                            });
                                          },
                                          items: _buildings
                                              .map((building) =>
                                                  DropdownMenuItem<String>(
                                                    value: building,
                                                    child: Text(building),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 16.0),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          hint: const Text('เลือกชั้น'),
                                          value: _selectedFloor,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedFloor = value;
                                            });
                                          },
                                          items: _floors
                                              .map((floor) =>
                                                  DropdownMenuItem<String>(
                                                    value: floor,
                                                    child: Text(floor),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 16.0),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          hint: const Text('เลือกประเภท'),
                                          value: _selectedType,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedType = value;
                                            });
                                          },
                                          items: _types
                                              .map((type) =>
                                                  DropdownMenuItem<String>(
                                                    value: type,
                                                    child: Text(type),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],

                        // **ปุ่มรีเซ็ตตัวกรอง**
                        if (!_isCollapsed) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: TextField(
                                  onChanged: (value) {
                                    setState(() {
                                      _searchTankId = value;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'ค้นหาจาก Tank ID',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedBuilding = null;
                                    _selectedFloor = null;
                                    _selectedType = null;
                                    _searchTankId = '';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text(
                                  'รีเซ็ตตัวกรองทั้งหมด',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // **ข้อมูลจำนวนถัง**
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('firetank_Collection')
                              .where('building', isEqualTo: _selectedBuilding)
                              .where('floor', isEqualTo: _selectedFloor)
                              .where('type', isEqualTo: _selectedType)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text('กรุณากรองข้อมูลหรือค้นหาใหม่'));
                            }

                            int totalTanks = snapshot.data!.docs.length;
                            int expiredTanks = 0;
                            int nonExpiredTanks = 0;

                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final installationDate =
                                  (data['installation_date'] as Timestamp)
                                      .toDate();
                              final expirationYears = data['expiration_years'];
                              final expirationDate = installationDate
                                  .add(Duration(days: expirationYears * 365));
                              final currentDate = DateTime.now();

                              if (expirationDate.isBefore(currentDate)) {
                                expiredTanks++;
                              } else {
                                nonExpiredTanks++;
                              }
                            }

                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('ถังดับเพลิงทั้งหมด: $totalTanks'),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('ถังที่หมดอายุ: $expiredTanks'),
                                      SizedBox(height: 5),
                                      Text(
                                          'ถังที่ยังไม่หมดอายุ: $nonExpiredTanks'),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // แสดงข้อมูลถังดับเพลิง
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('firetank_Collection')
                    .where(
                      'building',
                      isEqualTo: _selectedBuilding == null ||
                              _selectedBuilding!.isEmpty
                          ? null
                          : _selectedBuilding,
                    )
                    .where(
                      'floor',
                      isEqualTo:
                          _selectedFloor == null || _selectedFloor!.isEmpty
                              ? null
                              : _selectedFloor,
                    )
                    .where(
                      'type',
                      isEqualTo: _selectedType == null || _selectedType!.isEmpty
                          ? null
                          : _selectedType,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('กรุณากรองข้อมูลหรือค้นหาใหม่'),
                    );
                  }

                  // ฟิลเตอร์ Tank ID หลังจากดึงข้อมูลจาก Firebase
                  final tanks = snapshot.data!.docs.where((doc) {
                    final data = doc.data()
                        as Map<String, dynamic>; // ตรวจสอบว่าเป็น Map
                    if (data.containsKey('tank_id')) {
                      final tankId = (data['tank_id'] as String)
                          .toLowerCase(); // แปลงเป็นพิมพ์เล็ก
                      return tankId.contains(
                          _searchTankId.toLowerCase()); // ค้นหาแบบไม่สนตัวพิมพ์
                    }
                    return false;
                  }).toList();

                  if (tanks.isEmpty) {
                    return const Center(
                      child: Text('ไม่พบข้อมูลที่ตรงกับการค้นหา'),
                    );
                  }

                  return ListView.builder(
                    itemCount:
                        tanks.length + 1, // เพิ่ม 1 เพื่อให้มีช่องว่างสุดท้าย
                    itemBuilder: (context, index) {
                      if (index == tanks.length) {
                        // เพิ่มช่องว่างที่ด้านล่างสุด
                        return SizedBox(
                            height: 80); // ปรับขนาดช่องว่างตามต้องการ
                      }

                      // ฟังก์ชั่นการเรียงลำดับ
                      tanks.sort((a, b) {
                        final idA = a['tank_id'].replaceAll(RegExp(r'\D'), '');
                        final idB = b['tank_id'].replaceAll(RegExp(r'\D'), '');
                        return int.parse(idA).compareTo(int.parse(idB));
                      });

                      final tank = tanks[index];

                      return ClipRRect(
                        borderRadius:
                            BorderRadius.circular(15), // ทำให้ทุกมุมโค้งมน
                        child: Card(
                          color: Colors.white, // พื้นหลังเป็นสีขาว
                          elevation: 0, // เอาเงาออก
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15), // ขอบโค้งมน
                            side: BorderSide(
                                color: Colors.grey[350]!,
                                width: 1), // เส้นขอบสีเทา
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  15), // ให้ ListTile มีมุมโค้งเหมือนกัน
                            ),
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Text('Tank ID: ${tank['tank_id']}'),
                            subtitle: Text(
                              'ประเภทถัง: ${tank['type']}\nอาคาร: ${tank['building']}\nชั้น: ${tank['floor']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FireTankDetailPage(tank: tank),
                                ),
                              );
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditFireTankPage(
                                          tankIdToEdit: tank.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _confirmDelete(context, tank.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FireTankFormPage(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

class FireTankFormPage extends StatefulWidget {
  const FireTankFormPage({Key? key}) : super(key: key);

  @override
  _FireTankFormPageState createState() => _FireTankFormPageState();
}

class _FireTankFormPageState extends State<FireTankFormPage> {
  final TextEditingController _fireExtinguisherIdController =
      TextEditingController();
  final TextEditingController _expirationYearsController =
      TextEditingController(text: '5');
  String? _type; // ตัวแปร _type อาจจะเป็น String
  String? _building;
  String? _floor;
  DateTime _installationDate = DateTime.now();
  String? _qrCode;

  List<String> _buildingList = [];
  List<String> _typeList = [];
  int _totalFloors = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBuildings();
    _fetchTypes(); // ดึงข้อมูลประเภทจาก FE_type

    // ดึงหมายเลขถังสำหรับการเพิ่มใหม่
    _getNextId().then((nextId) {
      setState(() {
        _fireExtinguisherIdController.text = nextId;
      });
    });
  }

  // ฟังก์ชันดึงข้อมูลประเภทจาก collection 'FE_type'
  Future<void> _fetchTypes() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('FE_type').get();
      setState(() {
        _typeList = snapshot.docs
            .map((doc) => doc['type'].toString())
            .toList(); // ดึงข้อมูลประเภทและเพิ่มลงใน _typeList
      });
    } catch (e) {
      print('Error fetching types: $e');
    }
  }

  Future<void> _fetchBuildings() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('buildings').get();
      setState(() {
        _buildingList =
            snapshot.docs.map((doc) => doc['name'].toString()).toList();
      });
    } catch (e) {
      print('Error fetching buildings: $e');
    }
  }

  Future<void> _fetchTotalFloors(String buildingName) async {
    setState(() {
      _isLoading = true;
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('buildings')
          .where('name', isEqualTo: buildingName)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _totalFloors = int.parse(snapshot.docs.first['totalFloors']);
          _floor = null;
        });
      }
    } catch (e) {
      print('Error fetching total floors: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectInstallationDate(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _installationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selectedDate != null && selectedDate != _installationDate) {
      setState(() {
        _installationDate = selectedDate;
      });
    }
  }

  Future<String> _getNextId() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .orderBy('tank_id')
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<int> usedIds = [];

        // ดึงหมายเลขถังดับเพลิงที่ใช้งานแล้ว
        for (var doc in snapshot.docs) {
          final lastId = doc['tank_id'] as String;
          final number = int.parse(lastId.replaceAll(RegExp(r'\D'), ''));
          usedIds.add(number);
        }

        // หาหมายเลขที่ยังไม่มี
        int nextId = 1;
        while (usedIds.contains(nextId)) {
          nextId++;
        }

        return 'FE${nextId.toString().padLeft(3, '0')}';
      } else {
        return 'FE001';
      }
    } catch (e) {
      print('Error getting next ID: $e');
      return 'FE001';
    }
  }

  Future<void> _generateQRCode(String tankId) async {
    _qrCode = 'https://fire-check-db.web.app/user?tankId=$tankId';
  }

  Future<void> _saveFireTankData() async {
    try {
      final newId = _fireExtinguisherIdController.text;

      // แสดงค่าตัวแปรที่ใช้ในการบันทึกข้อมูล
      /*print('newId: $newId');
      print('type: $_type');
      print('building: $_building');
      print('floor: $_floor');
      print('installationDate: $_installationDate');
      print('expirationYearsController $_expirationYearsController');*/

      //กรอกให้ครบ
      if (_type == null ||
          _building == null ||
          _floor == null ||
          _expirationYearsController.text.isEmpty) {
        print('ข้อมูลไม่ครบ');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
        );
        return;
      }

      await _generateQRCode(newId);

      print('กำลังบันทึกข้อมูลไปยัง Firestore...');
      try {
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('firetank_Collection')
            .add({
          'tank_id': newId,
          'type': _type,
          'building': _building,
          'floor': _floor,
          'status': 'ยังไม่ตรวจสอบ',
          'status_technician': 'ยังไม่ตรวจสอบ', // เพิ่มฟิลด์ status_technician
          'installation_date': _installationDate,
          'expiration_years': int.tryParse(_expirationYearsController.text) ??
              5, // แปลงเป็น int

          'qrcode': _qrCode,
        });

        print('บันทึกข้อมูลสำเร็จ: ${docRef.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
        );

        // เพิ่มการหน่วงเวลาก่อนเปลี่ยนหน้า
        await Future.delayed(Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        print("Error saving document: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } catch (e) {
      print("Error saving document: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'เพิ่มข้อมูลถังดับเพลิง',
          style: TextStyle(color: Colors.white), // เปลี่ยนสีข้อความเป็นสีขาว
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            Row(
              children: [
                Text(
                    'วันที่ติดตั้ง: ${DateFormat('dd/MM/yyyy').format(_installationDate)}'),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectInstallationDate(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fireExtinguisherIdController,
              decoration: const InputDecoration(
                labelText: 'Fire Extinguisher ID',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _type,
              onChanged: (value) {
                setState(() {
                  _type = value;
                });
              },
              items: _typeList.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'ประเภทถังดับเพลิง',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _expirationYearsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'วันหมดอายุถังดับเพลิง',
                  border: OutlineInputBorder(),
                  suffixText: 'ปี',
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _building,
              onChanged: (value) {
                setState(() {
                  _building = value;
                  _fetchTotalFloors(value!);
                });
              },
              items: _buildingList.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'เลือกอาคาร',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            if (_building != null)
              DropdownButtonFormField<String>(
                value: _floor,
                onChanged: (value) {
                  setState(() {
                    _floor = value;
                  });
                },
                items: List.generate(_totalFloors, (index) => '${index + 1}')
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'เลือกชั้น',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveFireTankData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'บันทึก',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white), // เปลี่ยนสีข้อความเป็นสีขาว
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// เพิ่มหน้ารายละเอียด
class FireTankDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot<Object?> tank;

  const FireTankDetailPage({Key? key, required this.tank}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // แปลงวันที่จาก Firestore เป็น DateTime
    final DateTime installationDate =
        (tank['installation_date'] as Timestamp).toDate();

    // แปลงวันที่เป็นรูปแบบ "วัน/เดือน/ปี เวลา"
    final formattedDate = DateFormat('dd/MM/yyyy ').format(installationDate);

    // คำนวณวันที่หมดอายุจากวันที่ติดตั้งและปีหมดอายุ (expiration_years)
    final expirationYears = tank['expiration_years'] ??
        5; // ถ้าไม่มีข้อมูลจะใช้ค่า 5 ปีเป็นค่าเริ่มต้น
    final expirationDate = installationDate.add(Duration(
        days: 365 *
            (expirationYears as int))); // ใช้ as int เพื่อบังคับแปลงเป็น int

    // ตรวจสอบว่าเวลาที่ปัจจุบันผ่านวันที่หมดอายุหรือยัง
    final DateTime currentDate = DateTime.now();
    int remainingYears = expirationYears;

    if (currentDate.isAfter(expirationDate)) {
      // ถ้าผ่านวันที่หมดอายุแล้ว ลดค่า expirationYears
      remainingYears =
          expirationYears - (currentDate.year - expirationDate.year);
      // ตรวจสอบว่าเหลือปีที่ติดลบไหม ถ้าเหลือให้น้อยกว่าศูนย์ให้เป็น 0
      remainingYears = remainingYears < 0 ? 0 : remainingYears;
    }

    // แปลงวันหมดอายุเป็นรูปแบบ "วัน/เดือน/ปี"
    final formattedExpirationDate =
        DateFormat('dd/MM/yyyy').format(expirationDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'รายละเอียดถังดับเพลิง: ${tank['tank_id']}',
          style: TextStyle(color: Colors.white), // เปลี่ยนสีข้อความเป็นสีขาว
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tank ID: ${tank['tank_id']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'ประเภท: ${tank['type']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'อาคาร: ${tank['building']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'ชั้น: ${tank['floor']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            // แสดงวันที่ติดตั้ง
            Text('วันที่ติดตั้ง: $formattedDate'),
            const SizedBox(height: 10),

            // แสดงวันที่หมดอายุ
            Text(
              'หมดอายุถัง: $formattedExpirationDate ($remainingYears  ปี)',
              style: const TextStyle(
                  fontSize: 16, color: Colors.red), // แสดงวันที่หมดอายุในสีแดง
            ),

            // แสดง QR Code และลิงก์ที่คลิกได้
            if (tank['qrcode'] != null)
              Column(
                children: [
                  // QR Code Image
                  Center(
                    child: QrImageView(
                      data: tank['qrcode'], // ใช้ข้อมูล qrcode จาก Firestore
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // คลิกเพื่อลิงก์
                  GestureDetector(
                    onTap: () async {
                      final url = tank['qrcode']; // ลิงก์ที่ได้จาก Firestore
                      if (await canLaunch(url)) {
                        await launch(url); // เปิดลิงก์ในเบราว์เซอร์
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('ไม่สามารถเปิดลิงก์นี้ได้: $url')),
                        );
                      }
                    },
                    child: Text(
                      tank['qrcode'],
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
