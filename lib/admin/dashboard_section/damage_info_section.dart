import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // เพิ่มการ import

class DamageInfoSection extends StatelessWidget {
  final int checkedCount, uncheckedCount, brokenCount, repairCount;
  const DamageInfoSection({
    Key? key,
    required this.checkedCount,
    required this.uncheckedCount,
    required this.brokenCount,
    required this.repairCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DamageInfoSection(
      checkedCount: checkedCount,
      uncheckedCount: uncheckedCount,
      brokenCount: brokenCount,
      repairCount: repairCount,
    );
  }
}
