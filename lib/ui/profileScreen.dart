import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eatit/services/familyService.dart';
import 'package:eatit/services/userService.dart';
import 'package:eatit/models/familyModel.dart';
import 'package:eatit/models/userModel.dart';
import '../services/platformService.dart';
import 'signInScreen.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  UserModel? _userModel;
  FamilyModel? _familyModel;
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
        loading = false;
      });
    } catch (e) {
      setState(() {
        appVersion = 'Unavailable';
        platform = 'Unavailable';
        loading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    var userData = await UserService().loadCachedUserData();

    if (userData != null) {
      _userModel = userData;
      _familyModel = await FamilyService().getFamilyData(_currentUser!.email!);
      setState(() {});
    } else {
      _userModel = await UserService().getUserData(_currentUser!.email!);
      _familyModel = await FamilyService().getFamilyData(_currentUser!.email!);
      setState(() {});
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }

  Future<void> _deleteUserAccount() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
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
          const SnackBar(
              content: Text('Your account has been deleted successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete account. Please try again.')),
        );
      }
    }
  }

  Future<void> _createFamily() async {
    try {
      FamilyModel family = FamilyModel(
        familyName: '${_currentUser!.displayName ?? 'No Name'}\'s Family',
        adminEmail: _currentUser!.email!,
        familyCode: '',
        members: {
          _userModel!.email!: _userModel!.displayName ??
              'No Name' // Key-value pair for the admin.
        },
      );
      await FamilyService().createFamily(family, _userModel!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create family: $e')),
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
          familyCode, _currentUser!.email!, _currentUser!.displayName!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined the family!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join family: $e')),
      );
    }
  }

  Future<void> _copyFamilyCode() async {
    if (_familyModel != null) {
      await Clipboard.setData(ClipboardData(text: _familyModel!.familyCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family code copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      endDrawer: Drawer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _createFamily,
                child: const Text('Create My Family'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Logout'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _deleteUserAccount,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Account'),
              ),
              Text('Version: $appVersion | Platform: $platform'),
            ],
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  Text('Name: ${_currentUser!.displayName ?? 'No Name'}'),
                  Text('Email: ${_currentUser!.email}'),
                  const SizedBox(height: 20),
                  _buildFamilyCodeInput(),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _joinFamily,
                    child: const Text('Join Family'),
                  ),
                  const SizedBox(height: 10),
                  if (_familyModel != null) _buildFamilyDetails(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade300,
        child: _userModel?.profileImageBase64 != null
            ? ClipOval(
                child: Image.memory(
                base64Decode(_userModel!.profileImageBase64 ?? ''),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ))
            : const Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
      ),
    );
  }

  Widget _buildFamilyCodeInput() {
    return TextField(
      controller: _familyCodeController,
      decoration: const InputDecoration(
        labelText: 'Enter Family Code',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildFamilyDetails() {
    return Column(
      children: [
        Text('Your Family Code: ${_familyModel!.familyCode}'),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _copyFamilyCode,
          child: const Text('Copy Family Code'),
        ),
      ],
    );
  }
}
