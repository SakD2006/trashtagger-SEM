import 'package:flutter/material.dart';
import 'package:trashtagger/core/models/report_model.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      clipBehavior: Clip.antiAlias, // Ensures the image corners are rounded
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Before Image
          Image.network(
            report.beforeImageUrl,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            // Show a loading indicator while the image loads
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            // Show an error icon if the image fails to load
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              height: 250,
              child: Icon(Icons.error, color: Colors.red, size: 40),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LLM Description
                Text(
                  report.llmDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                // Attribution Text
                Text(
                  "Reported by: ${report.reporterUsername}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // Show "Cleaned by" only if the work is done
                if (report.status == 'completed' && report.cleanedBy != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Cleaned by: ${report.cleanedBy}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
