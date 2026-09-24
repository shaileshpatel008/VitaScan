import 'package:get/get.dart';

import '../datasources/local_datasource.dart';
import '../models/user_profile.dart';

class UserRepository extends GetxService {
  UserRepository(this._local);

  final LocalDataSource _local;
  final profile = Rxn<UserProfile>();

  @override
  void onInit() {
    final map = _local.readProfile();
    if (map != null) profile.value = UserProfile.fromMap(map);
    super.onInit();
  }

  bool get hasProfile => profile.value != null;

  Future<void> save(UserProfile value) async {
    profile.value = value;
    await _local.writeProfile(value.toMap());
  }

  void clear() => profile.value = null;
}
