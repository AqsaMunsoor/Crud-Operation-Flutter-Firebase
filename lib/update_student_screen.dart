import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:status_alert/status_alert.dart';
import 'package:uuid/uuid.dart';

class UpdateStudentPage extends StatefulWidget {
  UpdateStudentPage({Key? key, required this.id}) : super(key: key);

  final String id;

  @override
  _UpdateStudentPageState createState() => _UpdateStudentPageState();
}

class _UpdateStudentPageState extends State<UpdateStudentPage> {
  File? selectedProfilePic;
  // Updaing Student
  CollectionReference students =
      FirebaseFirestore.instance.collection('students');

  Future<void> updateUser(id, name, email, password, age, downloadUrl) async {
    Map<String, dynamic> userData = {
      "name": name,
      "email": email,
      "password": password,
      "age": age,
      "profilepic": downloadUrl,
    };
    if (selectedProfilePic != null) {
      // Upload the new profile picture and get the download URL
      String newDownloadUrl = await uploadProfilePic(selectedProfilePic!);
      userData["profilepic"] = newDownloadUrl;
    }

    await FirebaseFirestore.instance
        .collection("students")
        .doc(id)
        .update(userData)
        .then((value) => log("User Updated"));
  }

  Future<String> uploadProfilePic(File file) async {
    if (file.path.startsWith('http')) {
      // The file is already stored in Firebase Storage, return the existing download URL
      return file.path;
    } else {
      // Upload the new profile picture and get the download URL
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child("profilepictures")
          .child(Uuid().v1())
          .putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    }
  }

  void showSuccessDialog() {
    StatusAlert.show(
      context,
      duration: const Duration(seconds: 2),
      title: 'Success',
      subtitle: 'Student updated.',
      configuration:
          const IconConfiguration(icon: Icons.done, color: Colors.green),
      maxWidth: 250,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Update Student"),
        ),
        body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('students')
              .doc(widget.id)
              .get(),
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              print('Something Went Wrong');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            var data = snapshot.data!.data();
            var name = data!['name'];
            var email = data['email'];
            var password = data['password'];
            var age = data['age'];
            var profilepic = data['profilepic'];
            return Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  CupertinoButton(
                      onPressed: () async {
                        XFile? selectedImage = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (selectedImage != null) {
                          File convertedFile = File(selectedImage.path);
                          setState(() {
                            selectedProfilePic = convertedFile;
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
                          image: (selectedProfilePic != null)
                              ? DecorationImage(
                                  image: FileImage(selectedProfilePic!),
                                  fit: BoxFit.cover)
                              : (profilepic != null)
                                  ? DecorationImage(
                                      image: FileImage(File(profilepic)),
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
                  TextField(
                    onChanged: (value) => name = value,
                    controller: TextEditingController(text: name),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    onChanged: (value) => age = value,
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: age.toString()),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    onChanged: (value) => email = value,
                    controller: TextEditingController(text: email),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    onChanged: (value) => password = value,
                    controller: TextEditingController(text: password),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  CupertinoButton(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: Colors.purple,
                    onPressed: () {
                      updateUser(
                          widget.id, name, email, password, age, profilepic);
                      showSuccessDialog();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }
}
