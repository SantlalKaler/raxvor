import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:raxvor/app/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constant/string_constant.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<Map<String, dynamic>?>>(
      (ref) => ProfileController(),
    );

class ProfileController
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final supabase = Supabase.instance.client;

  ProfileController() : super(const AsyncValue.loading());

  Future<void> loadProfile(String uid) async {
    state = const AsyncValue.loading();
    try {
      final data = await supabase
          .from(supabaseUserTable)
          .select()
          .eq('uid', uid)
          .single();
      printValue("Profile data is $data");
      state = AsyncValue.data(data);
    } catch (e, st) {
      printValue(e);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await supabase.from(supabaseUserTable).update(data).eq('uid', uid);
      await loadProfile(uid);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uploadProfileImage(File imageFile, String uId) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storagePath = 'uploads/$fileName';
      printValue('Current Supabase user: ${supabase.auth.currentUser}');

      await supabase.storage
          .from('images')
          .upload(
            storagePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrl = supabase.storage
          .from('images')
          .getPublicUrl(storagePath);

      await supabase
          .from(supabaseUserTable)
          .update({'profile_image': imageUrl})
          .eq('uid', uId);
      loadProfile(uId);
    } catch (e) {
      printValue('Image upload failed: $e');
    }
  }
}
