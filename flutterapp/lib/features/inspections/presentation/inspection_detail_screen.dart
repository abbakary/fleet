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
    final profile = context.read<SessionController>().currentProfile;

    // Determine if current user is inspector or customer
    final isInspector = profile.isInspector;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Improved Summary Card
        InspectionSummaryCard(
          reference: detail.reference,
          vehicle: detail.vehicle,
          customer: detail.customer,
          status: detail.status,
          createdAt: detail.createdAt,
          inspector: detail.inspectorId != null
              ? InspectorProfileModel(
                  id: detail.inspectorId ?? 0,
                  badgeId: '',
                  certifications: '',
                  isActive: true,
                  maxDailyInspections: 0,
                  profile: PortalProfile(
                    id: detail.inspectorId ?? 0,
                    role: PortalProfile.roleInspector,
                    fullName: 'Inspector',
                    organization: '',
                  ),
                )
              : null,
        ),
        const SizedBox(height: 20),

        // Progress & Statistics Section
        InspectionProgressSection(responses: detail.responses),
        const SizedBox(height: 20),

        // Organized Findings by Category
        InspectionFindingsByCategorySection(
          responses: detail.responses,
          resolveMediaUrl: repo.resolveMediaUrl,
        ),
        const SizedBox(height: 20),

        // General notes if available
        if (detail.generalNotes.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.note_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'General Notes',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(detail.generalNotes, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Customer report if available
        if (detail.customerReport != null) ...[
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assessment, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Customer Report Summary',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(detail.customerReport!.summary, style: Theme.of(context).textTheme.bodyMedium),
                  if (detail.customerReport!.recommendedActions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Recommended Actions:', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(detail.customerReport!.recommendedActions, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  if (detail.customerReport!.publishedAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Published: ${DateFormat.yMMMd().add_jm().format(detail.customerReport!.publishedAt!)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Comments section for customer view
        if (!isInspector) ...[
          CommentsSection(
            inspectorName: 'Inspector',
            comments: [
              {
                'author': 'Inspector',
                'date': DateFormat.yMMMd().add_jm().format(detail.createdAt),
                'text': 'Inspection in progress. You will receive updates as sections are completed.',
              },
            ],
          ),
          const SizedBox(height: 20),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}
