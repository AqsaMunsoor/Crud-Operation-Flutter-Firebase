// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'dart:core';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:status_alert/status_alert.dart';
import 'package:uuid/uuid.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  File? profilepic;

  void saveUser() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String ageString = ageController.text.trim();
    int age = int.parse(ageString);

    nameController.clear();
    emailController.clear();
    passwordController.clear();
    ageController.clear();

    if (name != "" && email != "" && profilepic != null) {
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child("profilepictures")
          .child(const Uuid().v1())
          .putFile(profilepic!);

      StreamSubscription taskSubscription =
          uploadTask.snapshotEvents.listen((snapshot) {
        double percentage =
            snapshot.bytesTransferred / snapshot.totalBytes * 100;
        log(percentage.toString());
      });

      TaskSnapshot taskSnapshot = await uploadTask; //task launch
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      taskSubscription.cancel(); // to stop streamsubscription
      Map<String, dynamic> userData = {
        "name": name,
        "email": email,
        "password": password,
        "age": age,
        "profilepic": downloadUrl,
      };

      FirebaseFirestore.instance
          .collection("students")
          .add(userData)
          .then((value) => log("User Added"));
    } else {
      log('Please fill all fields.');
    }
    setState(() {
      profilepic = null;
    });
  }

  void showSuccessDialog() {
    StatusAlert.show(
      context,
      duration: const Duration(seconds: 2),
      title: 'Success',
      subtitle: 'Student added.',
      configuration:
          const IconConfiguration(icon: Icons.done, color: Colors.green),
      maxWidth: 250,
    );
  }

  void reset() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    ageController.clear();
  }

  final _formKey = GlobalKey<FormState>();

  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,

        // backgroundColor: Colors.purple,
        title: const Text("Add New Student"),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  CupertinoButton(
                      onPressed: () async {
                        XFile? selectedImage = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (selectedImage != null) {
                          File convertedFile = File(selectedImage.path);
                          setState(() {
                            profilepic = convertedFile;
                          });
                          log("Image selected!");
                        } else {
                          log("No image selected!");
                        }
                      },
                      padding: EdgeInsets.zero,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          shape: BoxShape.rectangle,
                          image: (profilepic != null)
                              ? DecorationImage(
                                  image: FileImage(profilepic!),
                                  fit: BoxFit.cover)
                              : null,
                          color: Colors.grey,
                        ),
                        child: Center(
                          child: (profilepic == null)
                              ? const Text(
                                  'Select Photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                )
                              : null,
                        ),
                      )),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "Age"),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your age';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null; // Return null if the input is valid
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Email: ',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Email';
                      } else if (!value.contains('@')) {
                        return 'Please Enter Valid Email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    controller: passwordController,
                    autofocus: false,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        child: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      hintText: 'Password: ',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CupertinoButton(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        color: Colors.purple,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              saveUser();
                              showSuccessDialog();
                            });
                          }
                        },
                        child: const Text("Save"),
                      ),
                      CupertinoButton(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        color: Colors.grey,
                        onPressed: () {
                          reset();
                        },
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
