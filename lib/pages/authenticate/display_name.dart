import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/services/storage.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';
import 'package:file_picker/file_picker.dart';

class DiscountUpload {
  File? image;
  String fileName;
  Timestamp? expiry;
  String? url;
  bool verified = false;

  DiscountUpload({
    required this.image,
    required this.fileName,
    this.expiry,
    this.url,
  });
}

class SetName extends ConsumerStatefulWidget {
  const SetName({super.key});

  @override
  ConsumerState<SetName> createState() => _SetNameState();
}

class _SetNameState extends ConsumerState<SetName> {
  final StorageService storage = StorageService();
  final _formKey = GlobalKey<FormState>();

  bool? student = false;
  bool? pwd = false;
  bool? seniorCitizen = false;

  Map<String, DiscountUpload> toUpload = {};

  String fname = '';
  String lname = '';
  int age = 0;

  TextEditingController expiryDate = TextEditingController();

  // Colors
  final Color primaryColor = const Color(0xFF83358E);
  final Color accentColor = const Color(0xFFFFD41C);

  Future<void> _selectDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 12)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 12)),
    );

    if (date != null) {
      setState(() {
        expiryDate.text = date.toString().split(" ")[0];
        final currentDate = DateTime.now();
        age = currentDate.year - date.year;
        if (currentDate.month < date.month ||
            (currentDate.month == date.month && currentDate.day < date.day)) {
          age--;
        }
      });
    }
  }

  bool isImageFile(String filePath) {
    final imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "webp", "tiff"];
    String extension = filePath.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  Future<void> pickFile(String reqId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        toUpload[reqId] = DiscountUpload(
          image: File(result.files.single.path!),
          fileName: result.files.single.name,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final _dbService = ref.watch(databaseServiceProvider);
    final _authService = ref.watch(authStateProvider);

    return _authService.when(
      data: (user) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: primaryColor,
            title: const Text(
              "Complete Your Profile",
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "What's your name?",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Let us know how to properly address you.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 30),

                    // First Name
                    _buildTextField(
                      label: "First Name",
                      onChanged: (val) => fname = val,
                      validator: (val) =>
                      val!.isEmpty ? 'First name is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Last Name
                    _buildTextField(
                      label: "Last Name",
                      onChanged: (val) => lname = val,
                      validator: (val) =>
                      val!.isEmpty ? 'Last name is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Birthday
                    const Text(
                      'Birthday',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: expiryDate,
                          decoration: InputDecoration(
                            hintText: "Select your birthdate",
                            prefixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (val) =>
                          val!.isEmpty ? 'Birthdate is required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      "Are you any of these?",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Verification of submitted ID's will take 3-5 business days.",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 15),

                    _buildCheckBoxRow(),

                    const SizedBox(height: 30),
                    if (student!) _buildUploadSection('Student', "Student ID"),
                    if (pwd!) _buildUploadSection('PWD', "PWD ID"),
                    if (seniorCitizen!)
                      _buildUploadSection('Senior Citizen', "Senior Citizen ID"),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // BACK BUTTON
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Back",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // NEXT BUTTON
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF83358E), // Primary color
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        String fullName = '$fname $lname';

                        // Upload images
                        await Future.wait(toUpload.entries.map((entry) async {
                          final reqId = entry.key;
                          final form = entry.value;
                          final url = await storage.uploadPassengerIDPic(
                            reqId,
                            user!.uid,
                            form.image,
                            form.fileName,
                          );
                          toUpload[reqId]!.url = url;
                          toUpload[reqId]!.expiry = Timestamp.fromDate(
                            DateTime.now().add(const Duration(days: 365)),
                          );
                        }));

                        _dbService.createUser(
                          user!.uid,
                          fullName,
                          fname,
                          lname,
                          user.phoneNumber,
                          user.email,
                          expiryDate.text,
                          toUpload,
                        );

                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/Home',
                              (r) => false,
                        );
                      }
                    },
                    child: const Text(
                      "Next",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        );
      },
      error: (e, trace) => const Center(child: Text("Something went wrong")),
      loading: () => const Loading(),
    );
  }

  /// TEXT FIELD
  Widget _buildTextField({
    required String label,
    required Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            hintText: label,
          ),
        ),
      ],
    );
  }

  /// CHECKBOX ROW
  Widget _buildCheckBoxRow() {
    return Row(
      children: [
        Expanded(
          child: _buildCheckboxCard("Student", student, (val) {
            setState(() => student = val);
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCheckboxCard("PWD", pwd, (val) {
            setState(() => pwd = val);
          }),
        ),
        if (age >= 60) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _buildCheckboxCard("Senior Citizen", seniorCitizen, (val) {
              setState(() => seniorCitizen = val);
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckboxCard(String title, bool? value, Function(bool?) onChanged) {
    return Card(
      elevation: value! ? 6 : 2,
      shadowColor: value ? accentColor.withOpacity(0.5) : Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        title: Text(title),
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  /// UPLOAD SECTION
  Widget _buildUploadSection(String key, String title) {
    final data = toUpload[key];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        // Image Preview
        if (data != null && data.image != null)
          Container(
            height: 150,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: FileImage(data.image!),
                fit: BoxFit.cover,
              ),
            ),
          ),

        // Upload Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.upload, color: Colors.white),
          label: const Text(
            "Choose Image",
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () => pickFile(key),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
