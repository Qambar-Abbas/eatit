import 'package:eatit/models/familyModel.dart';
import 'package:eatit/models/userModel.dart';
import 'package:eatit/services/familyService.dart';
import 'package:eatit/services/platformService.dart';
import 'package:eatit/services/userService.dart';
import 'package:eatit/ui/signinScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/riverpods/familyRiverpod.dart';
import '../services/riverpods/userStateRiverPod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _joinFamilyController = TextEditingController();
  final String appVersion = PlatformService.getAppVersion();
  final String platform = PlatformService.getPlatform();

  @override
  void initState() {
    super.initState();
    // _userModel = UserService().loadCachedUserData();
    ref.read(userStateProvider.notifier).loadUserData();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStateProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              setState(() {
                ref.invalidate(userFamiliesProvider(user.email!));
              });
            },
            icon: const Icon(Icons.refresh)),
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildEndDrawer(user, ref),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildTextForFamilyCode(
              user,
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildContent(user, ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextForFamilyCode(UserModel user) {
    final families = ref.watch(userFamiliesProvider(user.email!)).maybeWhen(
          data: (fams) => fams,
          orElse: () => <FamilyModel>[],
        );

    final adminFamily = families.where(
      (family) => family.adminEmail == user.email && family.isDeleted == false,
    );

    final display = adminFamily.isNotEmpty
        ? 'Family Code: ${adminFamily.first.familyCode}'
        : 'Your family code will appear here';

    return Text(
      display,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEndDrawer(UserModel user, WidgetRef ref) {
    return Drawer(
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.transparent,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _buildProfileHeader(user),
                  _buildJoinFamilySection(user, ref),
                  const SizedBox(height: 10),
                  _buildCreateFamilyButton(user, ref),
                  const SizedBox(height: 10),
                  _buildDeleteFamilyButton(context, user),
                  const Divider(),
                  _buildLogoutButton(user),
                  const SizedBox(height: 10),
                  _buildDeleteAccountButton(user),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(user.photoURL!),
        ),
        const SizedBox(height: 10),
        Text(
          user.displayName ?? "User",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(user.email!),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildJoinFamilySection(UserModel user, WidgetRef ref) {
    return TextFormField(
      controller: _joinFamilyController,
      decoration: InputDecoration(
        hintText: 'Enter Family Code To Join',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_circle_right_outlined),
          onPressed: () async {
            final familyCode = _joinFamilyController.text.trim();

            if (familyCode.length != 20) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "❗ Invalid family code. It must be exactly 20 characters long.",
                  ),
                ),
              );
              return;
            }

            try {
              final family =
                  await FamilyService().getFamilyByCodeFromFirebase(familyCode);

              if (family == null || family.isDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ No family found with this code."),
                  ),
                );
                return;
              }

              // Now members is List<String>, so just contains()
              if (family.members.contains(user.email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "ℹ️ You're already a member of this family.",
                    ),
                  ),
                );
                return;
              }

              // Pass the email directly
              await FamilyService().addOrRemoveFamilyMembers(
                familyCode: familyCode,
                memberEmail: user.email!, // simplified signature
                add: true,
              );

              await UserService().addOrRemoveUserFamilies(
                userEmail: user.email!,
                familyCode: familyCode,
                add: true,
              );

              ref.invalidate(userFamiliesProvider(user.email!));

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Successfully joined the family!"),
                ),
              );
              _joinFamilyController.clear();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("❌ Error: ${e.toString()}"),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCreateFamilyButton(UserModel user, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          await FamilyService().createAndStoreFamilyInFirebase(
            FamilyModel(
              familyName: "${user.displayName}'s Family",
              adminEmail: user.email!,
              familyCode: '', // to be generated by the service
              members: [user.email!], // just the user’s email
              foodMenu: {}, // empty list to start
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Family created successfully!'),
            ),
          );
          ref.invalidate(userFamiliesProvider(user.email!));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${e.toString()}'),
            ),
          );
        }
      },
      icon: const Icon(Icons.group_add),
      label: const Text("Create My Family"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildDeleteFamilyButton(BuildContext context, UserModel user) {
    return ElevatedButton.icon(
      onPressed: () async {
        final result = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirm Deletion"),
              content: const Text(
                  "Are you sure you want to delete your family? This action cannot be undone."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop('cancel');
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    FamilyService().deleteAdminFamily(user.email!);
                    Navigator.of(context).pop('deleted');
                  },
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
        if (result == 'deleted') {
          ref.invalidate(userFamiliesProvider(user.email!));
        }
      },
      icon: const Icon(Icons.delete),
      label: const Text("Delete My Family"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildLogoutButton(UserModel user) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleLogout(user),
        icon: const Icon(Icons.logout),
        label: const Text("Logout"),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _handleLogout(UserModel user) async {
    final confirmed = await _showConfirmationDialog(
      context,
      title: "Confirm Logout",
      content: "Are you sure you want to logout?",
      confirmLabel: "Logout",
    );

    if (confirmed != true) return;

    await UserService().logout();

    final container = ProviderContainer();
    container.dispose();

    ref.invalidate(userFamiliesProvider(user.email!));
    // if (mounted) setState(() {});

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  Widget _buildDeleteAccountButton(UserModel user) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleAccountDeletion(user),
        icon: const Icon(Icons.delete),
        label: const Text("Delete Account"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _handleAccountDeletion(UserModel user) async {
    final confirmed = await _showConfirmationDialog(
      context,
      title: "Are you sure you want to delete your account?",
      content: "All your data will be removed. Do you want to continue?",
      confirmLabel: "Delete",
      confirmLabelColor: Colors.red,
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await UserService().deleteUserAccountWithGoogle();
      await UserService().logout();

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully.")),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();

      if (e.code == 'reauthentication-required') {
        _showSnackBar("Please reauthenticate to delete your account.");
      } else {
        _showSnackBar("Auth error: ${e.message}");
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar("Error: ${e.toString()}");
    }

    final container = ProviderContainer();
    container.dispose();

    ref.invalidate(userFamiliesProvider(user.email!));
    // if (mounted) setState(() {});
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = "",
    Color? confirmLabelColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(color: confirmLabelColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.info),
                  label: const Text("About App"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text('Version: $appVersion | Platform: $platform')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(UserModel user, WidgetRef ref) {
    final userEmail = user.email!;
    final familiesAsync = ref.watch(userFamiliesProvider(userEmail));
    final familyService = FamilyService();

    return familiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: ${e.toString()}')),
      data: (families) {
        if (families.isEmpty) {
          return const Center(child: Text('No families found.'));
        }
        return ListView.builder(
          itemCount: families.length,
          itemBuilder: (context, index) {
            final family = families[index];
            final isAdmin = family.adminEmail == userEmail;
            final cookEmail = family.cook;
            // display cookEmail directly

            return ExpansionTile(
              title: Text(family.familyName),
              children: family.members.map((email) {
                final isCook = email == cookEmail;
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Row(
                    children: [
                      Text(email),
                      if (isCook) ...[
                        const SizedBox(width: 5),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(2.0),
                          child: const Text(
                            "Cook",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: isAdmin && email != family.adminEmail
                      ? Text('Long-press to manage')
                      : null,
                  onLongPress: isAdmin
                      ? () async {
                          final choice = await showMenu<String>(
                            context: context,
                            position:
                                const RelativeRect.fromLTRB(100, 100, 0, 0),
                            items: const [
                              PopupMenuItem(
                                  value: 'cook', child: Text('Toggle Cook')),
                              PopupMenuItem(
                                  value: 'remove',
                                  child: Text('Remove Member')),
                            ],
                          );
                          if (choice == null) return;

                          if (choice == 'cook') {
                            final resultText = isCook
                                ? 'Removed cook role from $email'
                                : 'Assigned cook: $email';
                            await familyService.toggleFamilyCook(
                              familyCode: family.familyCode,
                              memberEmail: email,
                            );
                            ref.refresh(userFamiliesProvider(userEmail));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(resultText)),
                            );
                          } else {
                            // Prevent the admin from removing themselves
                            if (email == family.adminEmail) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      '⚠️ You cannot remove the family admin from the family.'),
                                ),
                              );
                            } else {
                              await familyService.addOrRemoveFamilyMembers(
                                familyCode: family.familyCode,
                                memberEmail: email,
                                add: false,
                              );
                              ref.refresh(userFamiliesProvider(userEmail));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('$email removed from family')),
                              );
                            }
                          }
                        }
                      : null,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
