import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trashtagger/core/models/report_model.dart';
import 'package:trashtagger/core/services/firestore_service.dart';
import 'package:trashtagger/features/1_reports_feed/widgets/report_card.dart';

import '../../3_create_report/screens/create_report_screen.dart';

class ReportsFeedScreen extends StatefulWidget {
  const ReportsFeedScreen({super.key});

  @override
  State<ReportsFeedScreen> createState() => _ReportsFeedScreenState();
}

class _ReportsFeedScreenState extends State<ReportsFeedScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trashtagger Feed"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getReportsStream(),
        builder: (context, snapshot) {
          // 1. If waiting for data, show a loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. If there's an error
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong!"));
          }
          // 3. If there is no data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No reports yet. Be the first to tag some trash!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // 4. If we have data, display it in a list
          final reports = snapshot.data!.docs
              .map((doc) => ReportModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return ReportCard(report: reports[index]);
            },
          );
        },
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
