import 'package:flutter/material.dart';
import 'package:trashtagger/core/models/report_model.dart';
import 'package:trashtagger/features/3_complete_report/screens/complete_report_screen.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final String? userRole;

  const ReportCard({super.key, required this.report, this.userRole});

  // --- NEW: Helper function to build the image display ---
  Widget _buildImageDisplay() {
    // Check if the 'after' image is available
    final bool isCompleted =
        report.afterImageUrl != null && report.afterImageUrl!.isNotEmpty;

    if (isCompleted) {
      // --- SHOW SIDE-BY-SIDE ---
      return Column(
        children: [
          Row(
            children: [
              _buildImageWithLabel(
                'BEFORE',
                report.beforeImageUrl,
                Colors.orange,
              ),
              _buildImageWithLabel(
                'AFTER',
                report.afterImageUrl!,
                Colors.green,
              ),
            ],
          ),
          // Add a divider for a clean look
          const Divider(height: 1, thickness: 1),
        ],
      );
    } else {
      // --- SHOW ONLY 'BEFORE' IMAGE ---
      return Image.network(
        report.beforeImageUrl,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                height: 250,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
        errorBuilder: (context, error, stackTrace) => Container(
          height: 250,
          alignment: Alignment.center,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }

  // --- NEW: Helper for the side-by-side image + label ---
  Widget _buildImageWithLabel(String label, String imageUrl, Color labelColor) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: labelColor.withOpacity(0.1),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: labelColor),
            ),
          ),
          Image.network(
            imageUrl,
            height: 200, // Slightly smaller for side-by-side
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              alignment: Alignment.center,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This logic is still correct: show button if NGO and pending
    final bool canComplete =
        (userRole == 'ngo') && (report.status == 'pending');

    final bool isCompleted = report.status == 'completed';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- USE THE NEW HELPER FUNCTION HERE ---
          _buildImageDisplay(),

          // Report Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reported by ${report.reporterUsername}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.llmDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // This Row shows the status
                Row(
                  children: [
                    Icon(
                      report.status == 'pending'
                          ? Icons.watch_later
                          : Icons.check_circle,
                      color: report.status == 'pending'
                          ? Colors.orange
                          : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      report.status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: report.status == 'pending'
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ],
                ), // <-- *** THE ROW ENDS HERE ***
                // --- MOVE THE RATING BLOCK TO HERE ---
                // It should be a child of the Column, not the Row.
                if (isCompleted && report.aiRating != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🤖 AI Cleanup Rating:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.aiRating!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // THE CONDITIONAL BUTTON (this logic is unchanged)
          if (canComplete)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            CompleteReportScreen(report: report),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
