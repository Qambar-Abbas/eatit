import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eatit/services/familyService.dart';
import 'package:eatit/services/userService.dart';
import 'package:eatit/models/userModel.dart';
import 'package:eatit/models/familyModel.dart';
import '../services/platformService.dart';
import 'signInScreen.dart';
import 'package:flutter/services.dart';  // For Clipboard functionality

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  UserModel? _userModel;
  FamilyModel? _familyModel; // Add FamilyModel to store user's family
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
      print('Error retrieving app info: $e');
      setState(() {
        appVersion = 'Unavailable';
        platform = 'Unavailable';
        loading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser != null) {
      _userModel = await UserService().getUserData(_currentUser!.email!);
      _familyModel = await FamilyService().getFamilyData(_currentUser!.email!);  // Fetch family data by admin email
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
      print("Error logging out: $e");
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
            'Are you sure you want to delete your account? This action cannot be undone.'),
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
            child: const Text('Yes'),
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
        print("Error deleting account: $e");
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
        members: [_currentUser!.email!],
      );
      await FamilyService().createFamily(family);

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
      await FamilyService().joinFamily(familyCode, _currentUser!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined the family!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join family: $e')),
      );
    }
  }

  // Function to copy the family code to clipboard
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      child: _userModel?.profilePhoto != null
                          ? ClipOval(
                              child: Image.network(
                                _userModel!.profilePhoto!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Name: ${_currentUser!.displayName ?? 'No Name'}'),
                  Text('Email: ${_currentUser!.email}'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _familyCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Family Code',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _joinFamily,  // Implemented join family logic
                    child: const Text('Join Family'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _createFamily,  // Use the FamilyService method to create a family
                    child: const Text('Create My Family'),
                  ),
                  // Display family code if user is the admin of a family
                  if (_familyModel != null)
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        Text('Your Family Code: ${_familyModel!.familyCode}'),
                        ElevatedButton(
                          onPressed: _copyFamilyCode,
                          child: const Text('Copy Family Code'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
