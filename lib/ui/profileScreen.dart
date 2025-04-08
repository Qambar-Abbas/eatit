import 'package:eatit/models/familyModel.dart';
import 'package:eatit/models/userModel.dart';
import 'package:eatit/services/familyService.dart';
import 'package:eatit/services/platformService.dart';
import 'package:eatit/services/userService.dart';
import 'package:eatit/ui/signinScreen.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserModel?> _userModel;
  late Future<List<FamilyModel>> _userFamilies;
  final TextEditingController _joinFamilyController = TextEditingController();
  final String appVersion = PlatformService.getAppVersion() ?? 'NA';
  final String platform = PlatformService.getPlatform() ?? 'NA';

  @override
  void initState() {
    super.initState();
    _userModel = UserService().loadCachedUserData();
  }

  /// Extracts the admin family code if the current user is an admin.
  String _getAdminFamilyCode(List<FamilyModel> families, String? userEmail) {
    if (userEmail == null) return 'User email not found';
    try {
      final adminFamily = families.firstWhere((family) =>
          family.adminEmail.toLowerCase() == userEmail.toLowerCase());
      return "${adminFamily.familyCode}";
    } catch (e) {
      return "Your Family Code Will Appear Here";
    }
  }

  /// Builds the text field showing the admin's family code.
  Widget _buildFamilyCodeField(List<FamilyModel> families, String? userEmail) {
    final codeText = _getAdminFamilyCode(families, userEmail);
    return TextFormField(
      initialValue: codeText,
      readOnly: true,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colors.black12,
        border: OutlineInputBorder(),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }

  /// Builds the end drawer that contains profile and family actions.
  Widget _buildEndDrawer(UserModel user) {
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
                  const Divider(),
                  _buildJoinFamilySection(user),
                  const SizedBox(height: 10),
                  _buildCreateFamilyButton(user),
                  const SizedBox(height: 10),
                  _buildDeleteFamilyButton(user),
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

  /// Builds the join family section as a single text field with a done icon.
  Widget _buildJoinFamilySection(UserModel user) {
    return TextFormField(
      controller: _joinFamilyController,
      decoration: InputDecoration(
        hintText: 'Enter Family Code To Join',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.done),
          onPressed: () async {
            final familyCode = _joinFamilyController.text.trim();
            if (familyCode.isEmpty) return;
            try {
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

              // Refresh the family details.
              setState(() {
                _userFamilies = UserService().getUserFamilyDetails(user.email!);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Successfully joined the family!"),
                ),
              );
              _joinFamilyController.clear();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCreateFamilyButton(UserModel user) {
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

          // Refresh the family details after creation.
          setState(() {
            _userFamilies = UserService().getUserFamilyDetails(user.email!);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Family created successfully!'),
            ),
          );
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

  Widget _buildDeleteFamilyButton(UserModel user) {
    return ElevatedButton.icon(
      onPressed: () {
        FamilyService().deleteFamilyAsAdmin(user.email!);
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
                try {
                  await UserService().deleteUserAccount();
                  await UserService().logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
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

  /// Builds the main content of the screen that displays the family admin code
  /// and a list of family details.
  Widget _buildContent(UserModel user, List<FamilyModel> families) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildFamilyCodeField(families, user.email),
        ),
        const SizedBox(height: 10),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userModel,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('❌ Error: ${snapshot.error}')),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('No user data found')),
          );
        }

        // Initialize user family details.
        _userFamilies = UserService().getUserFamilyDetails(user.email!);

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
          endDrawer: _buildEndDrawer(user),
          body: FutureBuilder<List<FamilyModel>>(
            future: _userFamilies,
            builder: (context, familySnapshot) {
              if (familySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (familySnapshot.hasError) {
                return Center(
                    child: Text(
                        'Error loading families: ${familySnapshot.error}'));
              }
              final families = familySnapshot.data ?? [];
              return _buildContent(user, families);
            },
          ),
        );
      },
    );
  }
}
