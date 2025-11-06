import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trashtagger/core/models/report_model.dart';
import 'package:trashtagger/core/models/user_model.dart';
import 'package:trashtagger/core/services/auth_service.dart';
import 'package:trashtagger/core/services/firestore_service.dart';
import 'package:trashtagger/features/1_reports_feed/widgets/report_card.dart';
import 'package:trashtagger/features/3_complete_report/screens/create_report_screen.dart';

class ReportsFeedScreen extends StatefulWidget {
  const ReportsFeedScreen({super.key});

  @override
  State<ReportsFeedScreen> createState() => _ReportsFeedScreenState();
}

class _ReportsFeedScreenState extends State<ReportsFeedScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // We only want to show the full screen loader on the *first* load
    if (!_isLoadingUser) {
      setState(() {
        _isLoadingUser = true;
      });
    }

    final user = _authService.currentUser;
    if (user != null) {
      final userDataMap = await _firestoreService.getUser(user.uid);
      if (userDataMap != null && mounted) {
        setState(() {
          _currentUser = UserModel.fromMap(userDataMap, user.uid);
          _isLoadingUser = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trashtagger Feed")),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          // 2. ADDED: RefreshIndicator for pull-to-refresh
          : RefreshIndicator(
              onRefresh: _loadUserData, // Refreshes user data
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getReportsStream(),
                builder: (context, snapshot) {
                  // 3. CHANGED: Improved loading logic
                  // Only show a full-screen loader if there is NO data yet.
                  // This prevents the "double loader" flicker when data reloads.
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text("Something went wrong!"));
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    // 4. CHANGED: Enhanced the "Empty State" UI
                    return LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "No reports yet. Be the first to tag some trash!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // 5. If we have data, display it in a list
                  final reports = snapshot.data!.docs
                      .map((doc) => ReportModel.fromFirestore(doc))
                      .toList();

                  return ListView.builder(
                    // 6. ADDED: Padding for better spacing
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      return ReportCard(
                        report: reports[index],
                        userRole: _currentUser?.role,
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateReportScreen()),
          );
        },
        tooltip: 'Report Trash',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
