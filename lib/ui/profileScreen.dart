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
  final String appVersion = PlatformService.getAppVersion() ?? 'NA';
  final String platform = PlatformService.getPlatform() ?? 'NA';

  @override
  void initState() {
    super.initState();
    // _userModel = UserService().loadCachedUserData();
    ref.read(userStateProvider.notifier).loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, _) {
        final user = ref.watch(userStateProvider);

        if (user == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            centerTitle: true,
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
              ),
            ],
          ),
          endDrawer: _buildEndDrawer(user, ref),
          body: Consumer(
            builder: (context, ref, _) {
              final familiesAsync =
                  ref.watch(userFamiliesProvider(user.email!));

              return familiesAsync.when(
                data: (families) {
                  return Column(
                    children: [
                      _buildTextForFamilyCode(families),
                      Expanded(child: _buildContent(user, families)),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Error loading families: $error')),
              );
            },
          ),
        );
      },
    );
  }

  Padding _buildTextForFamilyCode(List<FamilyModel> families) {
    String displayText = 'Your family code will appear here';

    if (families.isNotEmpty) {
      final code = families.first.familyCode;
      if (code.isNotEmpty) {
        displayText = 'Family Code: $code';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        displayText,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEndDrawer(UserModel user, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
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
                  _buildLogoutSection(user),
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
              final family = await FamilyService().getFamilyByCode(familyCode);

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

              await FamilyService().updateFamilyMembers(
                familyDocId: familyCode,
                member: {
                  'email': user.email!,
                  'name': user.displayName!,
                },
                add: true,
              );

              await UserService().updateUserFamilies(
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
          await FamilyService().createFamily(
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
          setState(() {});
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
                    FamilyService().deleteFamilyAsAdmin(user.email!);
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
          if (mounted) setState(() {});
        }
      },
      icon: const Icon(Icons.delete),
      label: const Text("Delete My Family"),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildLogoutSection(UserModel user) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              UserService().logout();
              Navigator.pushReplacement<void, void>(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const SignInScreen(),
                ),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Are you sure?"),
                  content: const Text(
                      "Deleting your account is permanent. All your data will be removed. Do you want to continue?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  await UserService().deleteUserAccountWithGoogle();
                  await UserService().logout();

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account deleted successfully."),
                    ),
                  );

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
                  );
                } on FirebaseAuthException catch (e) {
                  Navigator.of(context).pop();

                  if (e.code == 'reauthentication-required') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Please reauthenticate to delete your account."),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Auth error: ${e.message}')),
                    );
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
                if (confirmed != null && confirmed) {
                  // ref.invalidate(userFamiliesProvider(user.email!));
                  final container = ProviderContainer();

                  container.dispose();

                  if (mounted) setState(() {});
                }
              }
              ref.invalidate(userFamiliesProvider(user.email!));
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.delete),
            label: const Text("Delete Account"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
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

  Widget _buildContent(UserModel user, List<FamilyModel> families) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: families.map((family) {
              return ExpansionTile(
                title: Text(family.familyName),
                children: family.members.map((member) {
                  return ListTile(
                    title: Text(member['name'] ?? 'Unknown'),
                    subtitle: Text(member['email'] ?? ''),
                    leading: const Icon(Icons.person),
                    onLongPress: () async {
                      final selected = await showMenu<String>(
                        context: context,
                        position: RelativeRect.fill,
                        items: const [
                          PopupMenuItem(value: 'view', child: Text('View')),
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'remove', child: Text('Remove')),
                        ],
                      );
                      if (selected != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Selected: $selected for ${member['name']}'),
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
