import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../auth/presentation/session_controller.dart';
import '../data/inspections_repository.dart';
import '../data/models.dart';
import '../data/report_generator.dart';
import 'widgets/inspection_detail_sections.dart';
import 'widgets/inspection_detail_organized.dart';

class InspectionDetailScreen extends StatefulWidget {
  const InspectionDetailScreen({required this.summary, super.key});

  final InspectionSummaryModel summary;

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  Future<InspectionDetailModel>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<InspectionDetailModel> _load() async {
    final repo = context.read<InspectionsRepository>();
    return repo.fetchInspectionDetail(widget.summary.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'View HTML report',
            onPressed: () => _openReport(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download PDF',
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<InspectionDetailModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('Failed to load inspection.'));
            }
            final detail = snapshot.data!;
            return _DetailView(detail: detail);
          },
        ),
      ),
    );
  }

  Future<void> _openReport(BuildContext context) async {
    final repo = context.read<InspectionsRepository>();
    final html = await repo.fetchReportHtml(widget.summary.id);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReportHtmlScreen(html: html),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final repo = context.read<InspectionsRepository>();
    try {
      final path = await repo.downloadReportPdf(widget.summary.id);
      if (!context.mounted) return;
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No PDF available.')));
        return;
      }
      await OpenFilex.open(path);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download PDF')));
    }
  }
}

class _ReportHtmlScreen extends StatelessWidget {
  const _ReportHtmlScreen({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share report',
            onPressed: () {
              // Share functionality can be added here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: html.isEmpty
          ? Center(
              child: Text(
                'No report available.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: _HtmlRenderWidget(html: html),
              ),
            ),
    );
  }
}

class _HtmlRenderWidget extends StatelessWidget {
  const _HtmlRenderWidget({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    // For web and mobile, render as formatted text with basic HTML parsing
    // A production app would use html widget or webview
    return SelectableText(
      html,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.detail});

  final InspectionDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<InspectionsRepository>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header with key inspection info
        InspectionHeaderCard(
          reference: detail.reference,
          vehicle: detail.vehicle,
          customer: detail.customer,
          status: detail.status,
          createdAt: detail.createdAt,
          odometerReading: detail.odometerReading,
        ),
        const SizedBox(height: 20),

        // Statistics summary
        InspectionStatisticsSection(responses: detail.responses),
        const SizedBox(height: 20),

        // Customer report if available
        if (detail.customerReport != null) ...[
          CustomerReportSection(report: detail.customerReport!),
          const SizedBox(height: 20),
        ],

        // General notes if available
        if (detail.generalNotes.isNotEmpty)
          GeneralNotesSection(notes: detail.generalNotes),
        if (detail.generalNotes.isNotEmpty) const SizedBox(height: 20),

        // Detailed responses/findings
        InspectionResponsesSection(
          responses: detail.responses,
          resolveMediaUrl: repo.resolveMediaUrl,
          showFindings: true,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
