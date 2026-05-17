import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final int age;
  final DateTime createdAt;

  UserProfile({required this.name, required this.age, required this.createdAt});

  factory UserProfile.empty() =>
      UserProfile(name: '', age: 0, createdAt: DateTime.now());

  bool get isComplete => name.isNotEmpty && age > 0;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    _load();
    return UserProfile.empty();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final age = prefs.getInt('user_age') ?? 0;
    final created = prefs.getString('user_created') ?? '';
    if (name.isNotEmpty && age > 0) {
      state = UserProfile(
        name: name,
        age: age,
        createdAt:
            created.isNotEmpty ? DateTime.parse(created) : DateTime.now(),
      );
    }
  }

  Future<void> saveProfile(String name, int age) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('user_name', name);
    await prefs.setInt('user_age', age);
    await prefs.setString('user_created', now.toIso8601String());
    state = UserProfile(name: name, age: age, createdAt: now);
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);
