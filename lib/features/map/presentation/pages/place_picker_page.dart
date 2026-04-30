import 'package:flutter/material.dart';

class PlacePickerPage extends StatelessWidget {
  const PlacePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('장소 선택')),
      body: const Center(child: Text('지도 준비 중')),
    );
  }
}
