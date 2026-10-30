import 'package:flutter/material.dart';

import '../../enums/user_role.dart';
import 'bendahara_tugas_page.dart';
import 'ketua_tugas_page.dart';
import 'member_tugas_page.dart';
import 'sekretaris_tugas_page.dart';
import 'wakil_ketua_tugas_page.dart';
import 'dekan_tugas_page.dart';

class TasksPage extends StatelessWidget {
  final UserRole role;

  const TasksPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case UserRole.dekan:
        return const DekanTugasPage();
      case UserRole.ketua:
        return const KetuaTugasPage();
      case UserRole.wakilKetua:
        return const WakilKetuaTugasPage();
      case UserRole.bendahara:
        return const BendaharaTugasPage();
      case UserRole.sekretaris:
        return const SekretarisTugasPage();
      case UserRole.kepalaDivisi:
      case UserRole.anggota:
        return const MemberTugasPage();
    }
  }
}
