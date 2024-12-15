import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:eatit/services/familyService.dart';
import 'package:eatit/services/userService.dart';
import 'package:eatit/services/platformService.dart';
import 'package:eatit/models/familyModel.dart';
import 'package:eatit/models/userModel.dart';
import 'signInScreen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  UserModel? _userModel;
  FamilyModel? _adminFamily;
  List<FamilyModel> _userFamilies = [];
  final TextEditingController _familyCodeController = TextEditingController();

  String appVersion = 'Loading...';
  String platform = 'Loading...';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initializeAppInfo();
    _loadUserData();
  }

  Future<void> _initializeAppInfo() async {
    try {
      final version = await PlatformService.getAppVersion();
      final platformName = PlatformService.getPlatform();
      setState(() {
        appVersion = version;
        platform = platformName;
      });
    } catch (e) {
      setState(() {
        appVersion = 'Unavailable';
        platform = 'Unavailable';
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() => loading = true);

    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        _userModel = await UserService().getUserData(_currentUser!.email!);
        _adminFamily = await FamilyService().getFamilyData(_currentUser!.email!);

        if (_userModel?.familyList?.isNotEmpty ?? false) {
          _userFamilies = await FamilyService().getUserFamilies(_userModel!.familyList!);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  Future<void> _deleteUserAccount() async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await UserService().deleteUserAccount(_currentUser!.email!);
        await _currentUser!.delete();
        await _logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account deletion failed: $e')),
        );
      }
    }
  }

  Future<void> _createFamily() async {
    try {
      final family = FamilyModel(
        familyName: "${_currentUser?.displayName ?? 'No Name'}'s Family",
        adminEmail: _currentUser!.email!,
        familyCode: '',
        members: {_userModel!.email!: _userModel!.displayName ?? 'No Name'},
      );
      await FamilyService().createFamily(family, _userModel!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family created successfully!')),
      );
      await _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Family creation failed: $e')),
      );
    }
  }

  Future<void> _joinFamily() async {
    final familyCode = _familyCodeController.text.trim();

    if (familyCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid family code')),
      );
      return;
    }

    try {
      await FamilyService().joinFamily(
        familyCode,
        _currentUser!.email!,
        _currentUser!.displayName!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined family successfully!')),
      );
      await _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join family: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      endDrawer: Drawer(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        ElevatedButton.icon(
          onPressed: _createFamily,
          icon: const Icon(Icons.group_add),
          label: const Text('Create My Family'),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        const Text(
          'Join other\'s Family',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _familyCodeController,
          decoration: const InputDecoration(
            labelText: 'Enter Family Code',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _joinFamily,
          icon: const Icon(Icons.login),
          label: const Text('Join Family'),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.exit_to_app),
          label: const Text('Logout'),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _deleteUserAccount,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          icon: const Icon(Icons.delete),
          label: const Text('Delete Account'),
        ),
        const Spacer(),
        Text('Version: $appVersion | Platform: $platform'),
      ],
    ),
  ),
),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildFamilyDetails(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
  return Column(
    children: [
      CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade300,
        child: _isValidBase64(_userModel?.profileImageBase64)
            ? ClipOval(
                child: Image.memory(
                  base64Decode(_userModel!.profileImageBase64!),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.person, size: 50, color: Colors.white),
      ),
      const SizedBox(height: 10),
      Text(
        _currentUser?.displayName ?? 'No Name',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      Text(
        'Email: ${_currentUser?.email}',
        style: const TextStyle(fontSize: 14),
      ),
    ],
  );
}

bool _isValidBase64(String? base64String) {
  if (base64String == null || base64String.isEmpty) return false;
  try {
    base64Decode(base64String);
    return true;
  } catch (e) {
    print('Invalid Base64 string: $e');
    return false;
  }
}


  Widget _buildFamilyDetails() {
    final widgets = <Widget>[];

    if (_adminFamily != null) {
      widgets.add(Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Family Code (Share to Let Others Join):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: _adminFamily!.familyCode),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Family Code',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _adminFamily!.familyCode),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Family code copied to clipboard!')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    if (_userFamilies.isEmpty) {
      widgets.add(const Text('You are not part of any other families.'));
    } else {
      widgets.addAll(
        _userFamilies.map((family) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                title: Text(
                  family.familyName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: family.members.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('- ${entry.value} (${entry.key})'),
                  );
                }).toList(),
              ),
            )),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
