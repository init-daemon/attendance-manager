import 'package:presence_manager/features/member/models/member.dart';
import 'package:presence_manager/services/member_table_service.dart';

class MockDataService {
  static Future<List<Member>> loadMembers() async {
    return await MemberTableService.getAll();
  }
}
