import 'package:flutter/material.dart';
import 'package:firecheck_setup/admin/dashboard.dart';

class FireTankBox extends StatelessWidget {
  final int totalTanks;
  const FireTankBox({Key? key, required this.totalTanks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12.0),
      decoration: boxDecorationStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.fire_extinguisher, size: 24, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('ถังดับเพลิงทั้งหมด',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Center(
              child: Text(
                '$totalTanks',
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
