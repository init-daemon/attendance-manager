import '../features/member/models/member.dart';
import 'member_table_service.dart';

class MockDataService {
  static Future<List<Member>> loadMembers() async {
    return await MemberTableService.getAll();
  }
}
