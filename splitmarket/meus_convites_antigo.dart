import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/widgets/custom_buttom_navbar.dart';

class InvitesPage extends StatelessWidget {
  const InvitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email =
        FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convites'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('group_invites')
            .where('email', isEqualTo: email)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final invites = snapshot.data!.docs;

          if (invites.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum convite recebido',
              ),
            );
          }

          return ListView.builder(
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        invite['groupName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final uid =
                                    FirebaseAuth
                                        .instance
                                        .currentUser!
                                        .uid;

                                final groupDoc =
                                    await FirebaseFirestore
                                        .instance
                                        .collection('groups')
                                        .doc(invite['groupId'])
                                        .get();

                                final membros =
                                    List<String>.from(
                                  groupDoc['membros'],
                                );

                                if (!membros.contains(uid)) {
                                  membros.add(uid);

                                  await FirebaseFirestore
                                      .instance
                                      .collection('groups')
                                      .doc(invite['groupId'])
                                      .update({
                                    'membros': membros,
                                  });
                                }

                                await invite.reference
                                    .update({
                                  'status': 'accepted',
                                });

                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Convite aceito',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Aceitar',
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: ElevatedButton(
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.red,
                              ),
                              onPressed: () async {
                                await invite.reference
                                    .update({
                                  'status': 'rejected',
                                });
                              },
                              child: const Text(
                                'Recusar',
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
       bottomNavigationBar: const CustomBottomNavbar(currentIndex: 0),
    );
  }
}