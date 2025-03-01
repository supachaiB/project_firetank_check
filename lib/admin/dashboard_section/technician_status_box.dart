import 'package:flutter/material.dart';
import 'inspection_status_box.dart';

class TechnicianStatusBox extends StatelessWidget {
  final int checkedCount, uncheckedCount, brokenCount, repairCount;
  const TechnicianStatusBox({
    Key? key,
    required this.checkedCount,
    required this.uncheckedCount,
    required this.brokenCount,
    required this.repairCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InspectionStatusBox(
      checkedCount: checkedCount,
      uncheckedCount: uncheckedCount,
      brokenCount: brokenCount,
      repairCount: repairCount,
    );
  }
}
