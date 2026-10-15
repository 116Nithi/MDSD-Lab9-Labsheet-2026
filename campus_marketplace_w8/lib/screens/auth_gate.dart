import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'main_scaffold.dart';
import '../repositories/item_repository_api.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.draftRepository});

  final ListingDraftRepository draftRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}')),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        // User is signed in - show the normal HomePage (using the existing API repository)
        return MainScaffold(
          itemRepositories: [ItemRepositoryApi(), ItemRepositoryFirestore()],
          draftRepository: draftRepository,
        );
      },
    );
  }
}
