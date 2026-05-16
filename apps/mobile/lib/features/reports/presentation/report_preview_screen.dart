import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/constants/app_constants.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/workflow_stepper.dart';
import '../../../theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../parcels/presentation/parcels_providers.dart';
import '../../recommendations/data/agro_rules_repository.dart';
import '../../recommendations/domain/agro_rule.dart';
import '../../../core/services/symptoms_catalog_service.dart';
import '../data/pdf_generator.dart';

class ReportPreviewScreen extends ConsumerStatefulWidget {
  const ReportPreviewScreen({super.key, required this.parcelId, this.filePath});
  final String parcelId;
  final String? filePath;

  @override
  ConsumerState<ReportPreviewScreen> createState() =>
      _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends ConsumerState<ReportPreviewScreen> {
  pw.Document? _doc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.filePath != null) {
        _loadFromFile(widget.filePath!);
      } else {
        _generate();
      }
    });
  }

  Future<void> _loadFromFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        setState(() {
          // Note: pw.Document doesn't have a direct "fromBytes", 
          // but we can store the bytes and use them in PdfPreview.
          _loading = false;
          _docBytes = bytes;
        });
      } else {
        _generate(); // Fallback if file missing
      }
    } catch (_) {
      _generate();
    }
  }

  Uint8List? _docBytes;

  Future<void> _generate() async {
    final parcel = ref.read(parcelByIdProvider(widget.parcelId));
    final user = ref.read(authStateProvider).value?.user;
    if (parcel == null) {
      setState(() => _loading = false);
      return;
    }

    // Load all observations for this parcel from Hive.
    final obsBox = Hive.box(AppConstants.boxObservations);
    final locale = Localizations.localeOf(context);
    final allObservations = <Map<String, dynamic>>[];
    
    // Ensure catalog is loaded in service
    await SymptomsCatalogService.load(locale);

    for (final key in obsBox.keys) {
      final raw = obsBox.get(key);
      if (raw is Map && raw['parcelId'] == widget.parcelId) {
        final obs = Map<String, dynamic>.from(raw);
        // Resolve symptoms to labels
        final ids = (obs['symptoms'] as List?)?.cast<String>() ?? [];
        obs['symptoms'] = ids.map((id) => SymptomsCatalogService.getLabelForId(id, locale)).toList();
        allObservations.add(obs);
      }
    }

    // Sort by date descending (latest first)
    allObservations.sort((a, b) => (b['at'] as String).compareTo(a['at'] as String));

    final latestObs = allObservations.isNotEmpty ? allObservations.first : null;

    // Extract symptoms from LATEST observation for rules matching.
    final symptoms = (latestObs?['symptoms'] as List?)?.cast<String>() ?? const <String>[];
    final severity = (latestObs?['severity'] as double?) ?? 0.4;
    final stage = (latestObs?['stage'] as String?) ?? parcel.growthStage;

    // Match agro rules based on latest status.
    List<AgroRule> matchedRules = const [];
    final rulesAsync = ref.read(agroRulesProvider);
    final allRules = rulesAsync.valueOrNull;
    if (allRules != null && symptoms.isNotEmpty) {
      matchedRules = matchRules(
        allRules: allRules,
        crop: parcel.crop,
        stage: stage,
        symptoms: symptoms,
        severity: severity,
        region: parcel.region,
      );
    }

    final doc = await PdfGenerator().build(
      parcel: parcel,
      technician: user?.name ?? 'Technicien Conseil',
      observations: allObservations,
      matchedRules: matchedRules,
    );

    // Persist report metadata + PDF file.
    await _persistReport(doc, parcel.name, parcel.crop);

    setState(() {
      _doc = doc;
      _loading = false;
    });
  }

  Future<void> _persistReport(
      pw.Document doc, String parcelName, String crop) async {
    try {
      final bytes = await doc.save();
      final dir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${dir.path}/reports');
      if (!reportsDir.existsSync()) reportsDir.createSync();

      final id = const Uuid().v4();
      final fileName = 'report_$id.pdf';
      final file = File('${reportsDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Hive.box(AppConstants.boxReports).put(id, {
        'id': id,
        'parcelId': widget.parcelId,
        'parcelName': parcelName,
        'crop': crop,
        'createdAt': DateTime.now().toIso8601String(),
        'filePath': file.path,
      });
    } catch (_) {
      // Non-blocking: report preview still works even if persistence fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final parcel = ref.watch(parcelByIdProvider(widget.parcelId));

    return Scaffold(
      appBar: AppBar(
        title: Text(parcel?.name ?? 'Rapport'),
        actions: [
          if (_doc != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _share,
              tooltip: 'Partager',
            ),
        ],
      ),
      body: _loading
          ? AppStateView.loading(
              title: widget.filePath != null ? 'Chargement du rapport…' : 'Génération du rapport…',
              message: widget.filePath != null ? 'Récupération du fichier PDF.' : 'Mise en page PDF en cours.',
            )
          : (_doc == null && _docBytes == null)
              ? AppStateView(
                  icon: Icons.error_outline_rounded,
                  title: 'Le rapport n\'a pas pu être créé',
                  message: 'Vérifiez que la parcelle existe et réessayez.',
                  accent: AppColors.danger,
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Retour'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() => _loading = true);
                          _generate();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: WorkflowStepper(currentStep: 2),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: PdfPreview(
                        build: (_) => _docBytes ?? _doc!.save(),
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                        pdfFileName:
                            'report_${parcel?.name.replaceAll(' ', '_') ?? 'parcel'}.pdf',
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Printing.layoutPdf(
                                        onLayout: (_) => _docBytes ?? _doc!.save()),
                                    icon: const Icon(Icons.print_rounded),
                                    label: const Text('Imprimer'),
                                    style: OutlinedButton.styleFrom(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PrimaryButton(
                                    label: 'Partager le rapport',
                                    icon: Icons.share_rounded,
                                    onPressed: _share,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => context.go(Routes.dashboard),
                                icon: const Icon(Icons.home_rounded),
                                label: const Text('Retour à l\'accueil'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _share() async {
    if (_doc == null && _docBytes == null) return;
    final bytes = _docBytes ?? await _doc!.save();
    final dir = await getTemporaryDirectory();
    final parcel = ref.read(parcelByIdProvider(widget.parcelId));
    final name =
        'report_${parcel?.name.replaceAll(' ', '_') ?? 'parcel'}.pdf';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)]);
  }
}
