import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crud_operations/search_student_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:status_alert/status_alert.dart';

import 'update_student_screen.dart';

class StudentListScreen extends StatefulWidget {
  StudentListScreen({Key? key}) : super(key: key);

  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  // For Deleting User
  CollectionReference<Map<String, dynamic>> students =
      FirebaseFirestore.instance.collection('students');

  void deleteUser(String id) async {
    FirebaseFirestore.instance
        .collection('students')
        .doc(id)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> userData =
            documentSnapshot.data()! as Map<String, dynamic>;
        String profilepicUrl = userData['profilepic'];

        // Delete user document from Firestore
        FirebaseFirestore.instance
            .collection('students')
            .doc(id)
            .delete()
            .then((value) => log("User Deleted"))
            .catchError((error) => log("Failed to delete user: $error"));

        // Delete profile picture from Firebase Storage
        if (profilepicUrl != null) {
          Reference storageRef =
              FirebaseStorage.instance.refFromURL(profilepicUrl);
          storageRef
              .delete()
              .then((_) => log("Profile picture deleted"))
              .catchError(
                  (error) => log("Failed to delete profile picture: $error"));
        }
      }
    });
  }

  void deleteCollection() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await students.get();
    for (DocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      await doc.reference.delete();
    }
    log("Collection deleted!");
  }

  bool isAscending = true; // Default to ascending order

  Stream<QuerySnapshot> getStudentsStream() {
    Query query = FirebaseFirestore.instance.collection("students");

    if (isAscending) {
      query = query.orderBy("name", descending: false);
    } else {
      query = query.orderBy("name", descending: true);
    }

    return query.snapshots();
  }

  void _showOrderSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Order Ascending'),
                onTap: () {
                  setState(() {
                    isAscending = true;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Order Descending'),
                onTap: () {
                  setState(() {
                    isAscending = false;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  TextEditingController searchNameController = TextEditingController();
  void showSuccessDialog() {
    StatusAlert.show(
      context,
      duration: const Duration(seconds: 2),
      title: 'Success',
      subtitle: 'Student deleted.',
      configuration:
          const IconConfiguration(icon: Icons.done, color: Colors.green),
      maxWidth: 250,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: getStudentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData && snapshot.data != null) {
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                        child: const Text(
                          'Clear All Data',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          deleteCollection();
                        }),
                    Row(
                      children: [
                        CupertinoButton(
                            child: Icon(Icons.sort),
                            onPressed: () {
                              _showOrderSheet();
                            }),
                        CupertinoButton(
                            child: Icon(Icons.search),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SearchStudentScreen()));
                            }),
                      ],
                    ),
                  ],
                ),
                SingleChildScrollView(
                  child: SizedBox(
                    height: MediaQuery.sizeOf(context).height / 1.35,
                    child: ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> userMap =
                            snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;

                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(userMap["profilepic"]),
                              ),
                              title: Text(
                                  userMap["name"] + " (${userMap["age"]})"),
                              subtitle: Text(userMap["email"]),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              UpdateStudentPage(
                                                  id: snapshot
                                                      .data!.docs[index].id),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.green,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      deleteUser(snapshot.data!.docs[index].id);
                                      showSuccessDialog();
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Text("No data!");
          }
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
