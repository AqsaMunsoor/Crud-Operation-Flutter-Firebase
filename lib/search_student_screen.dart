import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crud_operations/update_student_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchStudentScreen extends StatefulWidget {
  const SearchStudentScreen({
    Key? key,
  }) : super(key: key);

  @override
  _SearchStudentScreenState createState() => _SearchStudentScreenState();
}

class _SearchStudentScreenState extends State<SearchStudentScreen> {
  TextEditingController searchNameController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: Column(
            children: [
              TextField(
                controller: searchNameController,
                decoration:
                    const InputDecoration(labelText: "Search Students by name"),
              ),
              const SizedBox(
                height: 20,
              ),
              CupertinoButton(
                onPressed: () {
                  setState(() {});
                },
                color: Theme.of(context).colorScheme.secondary,
                child: const Text("Search"),
              ),
              const SizedBox(
                height: 20,
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("students")
                    .where("name", isEqualTo: searchNameController.text)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData && snapshot.data != null) {
                      QuerySnapshot dataSnapshot =
                          snapshot.data as QuerySnapshot;

                      if (dataSnapshot.docs.length > 0) {
                        return Column(
                          children: [
                            SingleChildScrollView(
                              child: SizedBox(
                                height: MediaQuery.sizeOf(context).height / 2,
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
                                            backgroundImage: NetworkImage(
                                                userMap["profilepic"]),
                                          ),
                                          title: Text(userMap["name"] +
                                              " (${userMap["age"]})"),
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
                                                                  .data!
                                                                  .docs[index]
                                                                  .id),
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
                                                  deleteUser(snapshot
                                                      .data!.docs[index].id);
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
                        return const Text("No results found!");
                      }
                    } else if (snapshot.hasError) {
                      return const Text("An error occured!");
                    } else {
                      return const Text("No results found!");
                    }
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
