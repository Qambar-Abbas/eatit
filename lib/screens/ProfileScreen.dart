import 'package:flutter/material.dart';
import 'CustomDrawer.dart';
import '../services/appService.dart'; // Assuming AppService is in this file

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Menu action
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Section
            const Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    'https://example.com/profile.jpg', // Replace with actual image URL or AssetImage if local
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nasir Uddin', // Replace with actual name
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
            // Family Lists
            Expanded(
              child: ListView(
                children: [
                  FamilyListWidget(familyName: 'Family 1', members: const [
                    'Jhon Doe',
                    'Qambar Abbas',
                    'James Williams',
                  ]),
                  const SizedBox(height: 16),
                  FamilyListWidget(familyName: 'Family 2', members: const [
                    'Jhon Doe',
                    'Qambar Abbas',
                    'James Williams',
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FamilyListWidget extends StatelessWidget {
  final String familyName;
  final List<String> members;

  FamilyListWidget({required this.familyName, required this.members});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            familyName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: members.map((member) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8),
                    const SizedBox(width: 8),
                    Text(
                      member,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}



// class ProfileScreen extends StatefulWidget {
//   final String familyId;
//   final String familyName;
//   const ProfileScreen({super.key, required this.familyId, required this.familyName});  
//   @override
//   _ProfileScreenState createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {

//   final AppService _appService = AppService();
//   Map<String, dynamic>? _userData;
//   List<Map<String, dynamic>> _families = [];

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//     _fetchFamilies();
//   }

//   // Fetch user data using AppService
//   Future<void> _fetchUserData() async {
//     final user = _appService.auth.currentUser;
//     if (user != null) {
//       final userData = await _appService.getUserData(user.uid);
//       setState(() {
//         _userData = userData;
//       });
//     }
//   }

//   // Fetch families the user is part of using AppService
//   void _fetchFamilies() {
//     _appService.getFamilies().listen((families) {
//       setState(() {
//         _families = families;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//       ),
//       endDrawer: CustomDrawer(_families, _userData),
//       body: _userData == null
//           ? const Center(
//               child: CircularProgressIndicator(),
//             )
//           : ListView(
//               padding: const EdgeInsets.all(16.0),
//               children: [
//                 Text(
//                   'Share Email To Let Others Join:\n${_userData?['email'] ?? 'Unknown'}',
//                   style: Theme.of(context).textTheme.bodyLarge,
//                 ),
//                 const SizedBox(height: 16.0),
//                 const Text(
//                   'Family Members:',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8.0),
//                 ..._families.map((family) {
//                   return FutureBuilder<List<Map<String, String>>>(
//                     future: _appService.getFamilyMembers(family['familyId']),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return const Center(
//                           child: CircularProgressIndicator(),
//                         );
//                       } else if (snapshot.hasError) {
//                         return Text('Error: ${snapshot.error}');
//                       } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                         return const Text('No family members found.');
//                       } else {
//                         final members = snapshot.data!;
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             ListTile(
//                               tileColor: Colors.grey[200],
//                               title: Text(
//                                 family['familyName'],
//                                 style: Theme.of(context).textTheme.titleLarge,
//                               ),
//                             ),
//                             const SizedBox(height: 8.0),
//                             ...members.map((member) {
//                               return ListTile(
//                                 leading: member['photoURL'] != null
//                                     ? CircleAvatar(
//                                         backgroundImage:
//                                             NetworkImage(member['photoURL']!),
//                                       )
//                                     : const CircleAvatar(
//                                         child: Icon(Icons.person),
//                                       ),
//                                 title: Text(member['username']!),
//                               );
//                             }),
//                           ],
//                         );
//                       }
//                     },
//                   );
//                 }),
//               ],
//             ),
//     );
//   }
// }
