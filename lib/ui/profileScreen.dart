import 'package:eatit/models/familyModel.dart';
import 'package:eatit/models/userModel.dart';
import 'package:eatit/riverpods/familyriverpod.dart';
import 'package:eatit/riverpods/userStateRiverPod.dart';
import 'package:eatit/services/familyService.dart';
import 'package:eatit/services/platformService.dart';
import 'package:eatit/services/userService.dart';
import 'package:eatit/ui/signinScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // late Future<UserModel?> _userModel;

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
  Widget build(BuildContext context) {
    final user = ref.watch(userStateProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
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
            _buildTextForFamilyCode(user),
            const SizedBox(height: 8),
            Expanded(child: _buildContent(user)),
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
    final display = families.isNotEmpty ? 'Family Code: ${families.first.familyCode}' : 'Your family code will appear here';
    return Text(
      display,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   return Consumer(
  //     builder: (context, watch, _) {
  //       final user = ref.watch(userStateProvider);
  //
  //       if (user == null) {
  //         return const Scaffold(
  //             body: Center(child: CircularProgressIndicator()));
  //       }
  //
  //       return Scaffold(
  //         appBar: AppBar(
  //           title: const Text('Profile'),
  //           centerTitle: true,
  //           actions: [
  //             Builder(
  //               builder: (context) => IconButton(
  //                 icon: const Icon(Icons.menu),
  //                 onPressed: () {
  //                   Scaffold.of(context).openEndDrawer();
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //         endDrawer: _buildEndDrawer(user, ref),
  //         body: Consumer(
  //           builder: (context, ref, _) {
  //             final familiesAsync =
  //                 ref.watch(userFamiliesProvider(user.email!));
  //
  //             return familiesAsync.when(
  //               data: (families) {
  //                 return Column(
  //                   children: [
  //                     _buildTextForFamilyCode(families),
  //                     Expanded(child: _buildContent(user, families)),
  //                   ],
  //                 );
  //               },
  //               loading: () => const Center(child: CircularProgressIndicator()),
  //               error: (error, _) =>
  //                   Center(child: Text('Error loading families: $error')),
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  // Padding _buildTextForFamilyCode(List<FamilyModel> families) {
  //   String displayText = 'Your family code will appear here';
  //
  //   if (families.isNotEmpty) {
  //     final code = families.first.familyCode;
  //     if (code.isNotEmpty) {
  //       displayText = 'Family Code: $code';
  //     }
  //   }
  //
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Text(
  //       displayText,
  //       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //     ),
  //   );
  // }

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
                      "❗ Invalid family code. It must be exactly 20 characters long."),
                ),
              );
              return;
            }

            try {
              final family = await FamilyService().getFamilyByCodeFromFirebase(familyCode);

              if (family == null || family.isDeleted == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ No family found with this code."),
                  ),
                );
                return;
              }

              final alreadyInFamily =
                  family.members.any((member) => member['email'] == user.email);

              if (alreadyInFamily) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("ℹ️ You're already a member of this family."),
                  ),
                );
                return;
              }

              await FamilyService().addOrRemoveFamilyMembers(
                familyCode: familyCode,
                member: {
                  'email': user.email!,
                  'name': user.displayName!,
                },
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
              familyCode: '',
              members: [
                {
                  'name': user.displayName!,
                  'email': user.email!,
                }
              ],
              foodMenu: [],
              isDeleted: false,
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Family created successfully!'),
            ),
          );
          ref.invalidate(userFamiliesProvider(user.email!));
          // setState(() {});
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
                  onPressed: (){   FamilyService().deleteAdminFamily(user.email!);
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

  Widget _buildContent(UserModel user) {
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
            final cookName = cookEmail != null
                ? family.members.firstWhere((m) => m['email'] == cookEmail)['name'] as String
                : null;

            return ExpansionTile(
              title: Row(
                children: [
                  Expanded(child: Text(family.familyName)),
                  if (cookName != null) ...[
                    const SizedBox(width: 12),
                    Chip(label: Text('Cook: $cookName')),
                  ],
                ],
              ),
              children: family.members.map((member) {
                final name = member['name'] as String? ?? 'Unknown';
                final email = member['email'] as String? ?? '';
                final isCookMember = email == cookEmail;

                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Row(
                    children: [
                      Text(name),
                      if (isCookMember) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.restaurant_menu, size: 18),
                      ],
                    ],
                  ),
                  subtitle: Text(email),
                  onLongPress: isAdmin
                      ? () async {
                    final choice = await showMenu<String>(
                      context: context,
                      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: const [
                        PopupMenuItem(value: 'cook', child: Text('Toggle Cook')),
                        PopupMenuItem(value: 'remove', child: Text('Remove Member')),
                      ],
                    );
                    if (choice == null) return;

                    if (choice == 'cook') {
                      final resultText = isCookMember
                          ? 'Removed cook role from $name'
                          : 'Assigned cook: $name';
                      await familyService.toggleFamilyCook(
                        familyCode: family.familyCode,
                        memberEmail: email,
                      );
                      ref.refresh(userFamiliesProvider(userEmail));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(resultText)),
                      );
                    } else {
                      await familyService.addOrRemoveFamilyMembers(
                        familyCode: family.familyCode,
                        member: {'name': name, 'email': email},
                        add: false,
                      );
                      ref.refresh(userFamiliesProvider(userEmail));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$name removed from family')),
                      );
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

// Widget _buildContent(UserModel user, List<FamilyModel> families) {
//     return Column(
//       children: [
//         Expanded(
//           child:
//           ListView(
//             children: families.map((family) {
//               return ExpansionTile(
//                 title: Text(family.familyName),
//                 children: family.members.map((member) {
//                   return ListTile(
//                     title: Text(member['name'] ?? 'Unknown'),
//                     subtitle: Text(member['email'] ?? ''),
//                     leading: const Icon(Icons.person),
//                     onLongPress: () async {
//                       final selected = await showMenu<String>(
//                         context: context,
//                         position: RelativeRect.fill,
//                         items: const [
//                           PopupMenuItem(value: 'cook', child: Text('Assign Cook')),
//                           // PopupMenuItem(value: 'edit', child: Text('Edit')),
//                           PopupMenuItem(value: 'remove', child: Text('Remove')),
//                         ],
//                       );
//                       if (selected != null) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                                 'Selected: $selected for ${member['name']}'),
//                           ),
//                         );
//                       }
//                     },
//                   );
//                 }).toList(),
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }
}
