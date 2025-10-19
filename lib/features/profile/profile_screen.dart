import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:raxvor/app/images.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/profile/profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final bioController = TextEditingController();
  final walletController = TextEditingController();
  bool isEditing = false;

  File? selectedImage;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getUserProfile();
  }

  Future<void> pickImage(ImageSource source) async {
    // 🔹 Check permission before picking
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
        return;
      }
    } else if (source == ImageSource.gallery) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery permission denied')),
        );
        return;
      }
    }

    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      final file = File(picked.path);
      setState(() => selectedImage = file);

      // upload image just after picked/clicked
      final uid = ref.read(authControllerProvider).currentUser?.uid;
      ref
          .read(profileControllerProvider.notifier)
          .uploadProfileImage(file, uid!);
    }
  }

  void showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              if (selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  getUserProfile() {
    final uid = ref.read(authControllerProvider).currentUser?.uid;
    if (uid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileControllerProvider.notifier).loadProfile(uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final uid = ref.read(authControllerProvider).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () async {
              if (!isEditing) {
                setState(() => isEditing = true);
              } else {
                final data = {
                  'name': nameController.text.trim(),
                  'username': usernameController.text.trim(),
                  'bio': bioController.text.trim(),
                };
                if (uid != null) {
                  await ref
                      .read(profileControllerProvider.notifier)
                      .updateProfile(uid, data);
                }
                setState(() => isEditing = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: profileState.when(
        data: (data) {
          if (data == null) {
            return const Center(child: Text("No profile found"));
          }

          nameController.text = data['name'] ?? '';
          usernameController.text = data['username'] ?? '';
          bioController.text = data['bio'] ?? '';
          emailController.text = data['email'] ?? '';
          walletController.text = data['wallet_balance']?.toString() ?? '0.0';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : (data['profile_image'] != null
                                      ? NetworkImage(data['profile_image'])
                                      : AssetImage(ImageConst.user))
                                  as ImageProvider,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: InkWell(
                          onTap: showImagePickerOptions,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.deepPurple,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField("Name", nameController, isEditing),
                _buildTextField("Username", usernameController, isEditing),
                _buildTextField("Email", emailController, false),
                _buildTextField("Bio", bioController, isEditing, maxLines: 3),

                const SizedBox(height: 24),
                if (!isEditing)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => isEditing = true);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Something went wrong ${err}'),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  getUserProfile();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Retry!"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 30,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool enabled, {
    int maxLines = 1,
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
