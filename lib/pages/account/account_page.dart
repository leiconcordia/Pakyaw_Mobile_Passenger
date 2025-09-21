import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/account/change_email.dart';
import 'package:pakyaw/pages/account/change_name.dart';
import 'package:pakyaw/pages/account/change_password.dart';
import 'package:pakyaw/pages/account/change_phonenumber.dart';
import 'package:pakyaw/pages/account/change_profile.dart';
import 'package:pakyaw/pages/account/id_page.dart';
import 'package:pakyaw/pages/account/saved_places.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/providers/user_provider.dart';
import 'package:pakyaw/services/database.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../../services/auth.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  DatabaseService database = DatabaseService();
  bool value = false;
  final AuthService _authService = AuthService(FirebaseAuth.instance);
  String? providerType = '';

  final Color primaryColor = const Color(0xFF83358E);
  final Color accentColor = const Color(0xFFFFD41C);
  final Color backgroundColor = const Color(0xFFF8F8F8);

  void showNameChangePanel(String name) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding:
            const EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
            child: NameChange(name: name),
          );
        });
  }

  void showEmailChangePanel(String email) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding:
            const EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
            child: EmailChange(email: email),
          );
        });
  }

  void showPhoneNumberChangePanel(
      String number, String? providerType, BuildContext context1) {
    showModalBottomSheet(
        context: context1,
        builder: (context) {
          return Container(
            padding:
            const EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
            child: PhoneChange(
                number: number, providerType: providerType, context1: context1),
          );
        });
  }

  void showProfileChange() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding:
            const EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
            child: const ChangeProfile(),
          );
        });
  }

  Future<String> getSignInMethod() async {
    final User? user = FirebaseAuth.instance.currentUser;

    String providerId = user!.providerData[0].providerId;
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'phone':
        return 'Phone';
      default:
        return providerId;
    }
  }

  Future<void> loadProviderType() async {
    String val = await getSignInMethod();
    setState(() {
      providerType = val;
    });
  }

  Future<void> getIfVerified(String userId) async {
    value = await database.checkVerified(userId);
  }

  @override
  void initState() {
    super.initState();
    loadProviderType();
    final user = ref.read(authStateProvider).value;
    getIfVerified(user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final userDetails = ref.watch(usersProvider);

    return userDetails.when(
      data: (user) {
        if (user != null) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: Text(
                'Account Info',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: SizeConfig.safeBlockHorizontal * 6.5,
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture with Floating Edit Button
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: user.profilePicPath == ''
                            ? const AssetImage("assets/profile_pic.png")
                        as ImageProvider
                            : NetworkImage(user.profilePicPath),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: showProfileChange,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.5),
                                  blurRadius: 6,
                                )
                              ],
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name & Verified Status
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        value ? Icons.verified : Icons.error_outline,
                        color: value ? Colors.green : Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        value ? 'Verified' : 'Unverified',
                        style: TextStyle(
                          color: value ? Colors.green : Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Account Info Section
                  _buildSectionTitle('Basic Info'),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildListTile(
                        icon: Icons.person,
                        title: 'Name',
                        subtitle: user.name,
                        onTap: () => showNameChangePanel(user.name),
                      ),
                      _buildListTile(
                        icon: Icons.credit_card,
                        title: 'ID',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: const RouteSettings(name: '/IDPage'),
                              builder: (context) => IdPage(
                                id: user.uid,
                                birthday: user.birthday,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.phone,
                        title: 'Phone Number',
                        subtitle:
                        user.phoneNumber.isEmpty ? 'N/A' : user.phoneNumber,
                        onTap: () => showPhoneNumberChangePanel(
                          user.phoneNumber,
                          providerType,
                          context,
                        ),
                      ),
                      _buildListTile(
                        icon: Icons.email,
                        title: 'Email',
                        subtitle: user.email.isEmpty ? 'N/A' : user.email,
                        onTap: providerType != 'Google'
                            ? () => showEmailChangePanel(user.email)
                            : null,
                        enabled: providerType != 'Google',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // More Settings
                  _buildSectionTitle('More'),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildListTile(
                        icon: Icons.wallet,
                        title: 'Payment Methods',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PasswordChange(),
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.place,
                        title: 'Saved Places',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedPlaces(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _authService.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const ErrorCatch(error: 'No data found');
        }
      },
      error: (error, stack) => Text('Error: $error'),
      loading: () => const Loading(),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool enabled = true,a
  }) {
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: enabled ? primaryColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.black : Colors.grey,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: enabled
          ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
          : null,
      onTap: enabled ? onTap : null,
    );
  }
}
