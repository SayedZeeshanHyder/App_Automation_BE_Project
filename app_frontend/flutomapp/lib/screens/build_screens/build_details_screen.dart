import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/build_model.dart';

class BuildDetailsSheet extends StatelessWidget {
  final BuildModel buildModel;

  const BuildDetailsSheet({Key? key, required this.buildModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Build Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailRow('Build ID', buildModel.buildId),
                    _buildDetailRow('Version', buildModel.buildVersion ?? "N/A"),
                    _buildDetailRow('Project ID', buildModel.projectId),
                    _buildDetailRow('Status', buildModel.statusMessage),
                    _buildDetailRow('Created By', buildModel.createdBy.userName),
                    _buildDetailRow('Email', buildModel.createdBy.email),
                    _buildDetailRow(
                      'Created At',
                      DateFormat('MMM dd, yyyy - hh:mm a')
                          .format(DateTime.parse(buildModel.createdAt)),
                    ),
                    if (buildModel.completedAt != null)
                      _buildDetailRow(
                        'Completed At',
                        DateFormat('MMM dd, yyyy - hh:mm a')
                            .format(DateTime.parse(buildModel.completedAt!)),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Build Logs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        buildModel.logs.join('\n'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}