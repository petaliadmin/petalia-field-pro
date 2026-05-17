import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/catalog_service.dart';
import '../../../theme/app_colors.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String _searchQuery = '';
  String _selectedZone = 'Toutes';
  bool _isMapView = false;

  final List<String> _zones = [
    'Toutes',
    'Niayes',
    'Bassin Arachidier',
    'Vallée du Fleuve',
    'Casamance',
    'Tambacounda'
  ];

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogServiceProvider);
    final catalogService = ref.watch(catalogServiceProvider.notifier);

    final cropsData = catalogService.getCropsData();
    final suppliers = catalogService.getSuppliers();
    final equipments = catalogService.getEquipments();
    final institutions = catalogService.getInstitutions();

    final rawCrops = (cropsData?['crops'] as List<dynamic>?) ?? [];

    // Filtrage
    final filteredCrops = rawCrops.where((c) {
      final nameFr = (c['labelFr'] as String?)?.toLowerCase() ?? '';
      final nameWo = (c['labelWo'] as String?)?.toLowerCase() ?? '';
      final matchesSearch = nameFr.contains(_searchQuery.toLowerCase()) || nameWo.contains(_searchQuery.toLowerCase());
      final zones = (c['zones'] as List<dynamic>?)?.map((z) => z.toString()).toList() ?? [];
      final matchesZone = _selectedZone == 'Toutes' || zones.any((z) => z.toLowerCase().contains(_selectedZone.toLowerCase()));
      return matchesSearch && matchesZone;
    }).toList();

    final filteredSuppliers = suppliers.where((s) {
      final name = (s['name'] as String?)?.toLowerCase() ?? '';
      final zone = (s['zone'] as String?)?.toLowerCase() ?? '';
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      final matchesZone = _selectedZone == 'Toutes' || zone.contains(_selectedZone.toLowerCase());
      return matchesSearch && matchesZone;
    }).toList();

    final filteredEquipments = equipments.where((e) {
      final name = (e['name'] as String?)?.toLowerCase() ?? '';
      final zone = (e['zone'] as String?)?.toLowerCase() ?? '';
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      final matchesZone = _selectedZone == 'Toutes' || zone.contains(_selectedZone.toLowerCase());
      return matchesSearch && matchesZone;
    }).toList();

    final filteredInstitutions = institutions.where((i) {
      final name = (i['name'] as String?)?.toLowerCase() ?? '';
      final zone = (i['zone'] as String?)?.toLowerCase() ?? '';
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      final matchesZone = _selectedZone == 'Toutes' || zone.contains(_selectedZone.toLowerCase());
      return matchesSearch && matchesZone;
    }).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catalogue & Ressources', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Actualiser le catalogue',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mise à jour du catalogue en cours...')),
                );
                catalogService.hydrate(force: true);
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.grass_rounded), text: 'Cultures'),
              Tab(icon: Icon(Icons.storefront_rounded), text: 'Fournisseurs'),
              Tab(icon: Icon(Icons.agriculture_rounded), text: 'Matériel'),
              Tab(icon: Icon(Icons.account_balance_rounded), text: 'Institutions'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Barre de recherche et filtres de zone
            Container(
              color: AppColors.primary.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Rechercher (culture, fournisseur...)',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _zones.map((zone) {
                        final isSelected = _selectedZone == zone;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(zone, style: TextStyle(color: isSelected ? Colors.white : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3))),
                            onSelected: (_) => setState(() => _selectedZone = zone),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Bannière de téléchargement si en cours
            if (catalogState.isHydrating && !catalogState.isCompleted)
              Container(
                color: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(catalogState.statusText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            // Contenu des onglets
            Expanded(
              child: TabBarView(
                children: [
                  _buildCropsTab(filteredCrops),
                  _buildSuppliersTab(filteredSuppliers),
                  _buildEquipmentsTab(filteredEquipments),
                  _buildInstitutionsTab(filteredInstitutions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropsTab(List<dynamic> crops) {
    if (crops.isEmpty) {
      return const Center(child: Text('Aucune culture trouvée pour ces critères.', style: TextStyle(fontStyle: FontStyle.italic)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: crops.length,
      itemBuilder: (context, index) {
        final crop = crops[index];
        final labelFr = crop['labelFr'] ?? '';
        final labelWo = crop['labelWo'] ?? '';
        final scientific = crop['scientificName'] ?? 'Non spécifié';
        final cycle = crop['cycle'] ?? 'Non spécifié';
        final zones = (crop['zones'] as List<dynamic>?)?.map((z) => z.toString()).toList() ?? ['Toutes zones'];

        final diseases = (crop['diseases'] as List<dynamic>?)?.map((d) => d.toString()).toList() ?? [];
        final stresses = (crop['stresses'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [];
        final symptoms = (crop['symptoms'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [];
        final causes = (crop['causes'] as List<dynamic>?)?.map((c) => c.toString()).toList() ?? [];
        final recommendations = (crop['recommendations'] as List<dynamic>?)?.map((r) => r.toString()).toList() ?? [];
        final goodPractices = crop['goodPractices']?.toString() ?? 'Aucune bonne pratique spécifique renseignée.';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.eco_rounded, color: AppColors.primary),
            ),
            title: Text('$labelFr ($labelWo)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(scientific, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.grey)),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text('Cycle : $cycle', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: zones.map((z) => Chip(label: Text(z, style: const TextStyle(fontSize: 11)), backgroundColor: Colors.grey.withValues(alpha: 0.1), visualDensity: VisualDensity.compact)).toList(),
              ),
              const Divider(height: 24),
              if (diseases.isNotEmpty) ...[
                const Text('🦠 Maladies courantes', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                const SizedBox(height: 4),
                ...diseases.map((d) => Text('• $d', style: const TextStyle(fontSize: 13))),
                const SizedBox(height: 12),
              ],
              if (stresses.isNotEmpty) ...[
                const Text('⚠️ Stress majeurs', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                const SizedBox(height: 4),
                ...stresses.map((s) => Text('• $s', style: const TextStyle(fontSize: 13))),
                const SizedBox(height: 12),
              ],
              if (symptoms.isNotEmpty) ...[
                const Text('🔍 Symptômes & Causes', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 4),
                for (int i = 0; i < symptoms.length; i++)
                  Text('• ${symptoms[i]} ➔ ${causes.length > i ? causes[i] : "Cause inconnue"}', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
              ],
              if (recommendations.isNotEmpty) ...[
                const Text('💡 Recommandations', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                const SizedBox(height: 4),
                ...recommendations.map((r) => Text('• $r', style: const TextStyle(fontSize: 13))),
                const SizedBox(height: 12),
              ],
              const Text('⭐ Bonnes Pratiques', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
              const SizedBox(height: 4),
              Text(goodPractices, style: const TextStyle(fontSize: 13, height: 1.3)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuppliersTab(List<dynamic> suppliers) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${suppliers.length} fournisseur(s) répertorié(s)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Row(
                children: [
                  const Text('Vue Carte', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: _isMapView,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isMapView = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isMapView ? _buildSuppliersMapView(suppliers) : _buildSuppliersListView(suppliers),
        ),
      ],
    );
  }

  Widget _buildSuppliersListView(List<dynamic> suppliers) {
    if (suppliers.isEmpty) return const Center(child: Text('Aucun fournisseur trouvé.', style: TextStyle(fontStyle: FontStyle.italic)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suppliers.length,
      itemBuilder: (context, index) {
        final sup = suppliers[index];
        final name = sup['name'] ?? '';
        final type = sup['type'] ?? '';
        final zone = sup['zone'] ?? '';
        final phone = sup['phone'] ?? '';
        final address = sup['address'] ?? '';
        final products = (sup['products'] as List<dynamic>?)?.map((p) => p.toString()).toList() ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary))),
                    Chip(label: Text(type, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: AppColors.accent, visualDensity: VisualDensity.compact),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text('$address ($zone)', style: const TextStyle(fontSize: 13, color: Colors.grey))),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Produits & Services :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: products.map((p) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('• $p', style: const TextStyle(fontSize: 12)))).toList(),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.message_rounded, size: 16),
                      label: const Text('SMS'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                      onPressed: () => _launchUrl('sms:$phone'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: const Text('Appeler'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: () => _launchUrl('tel:$phone'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuppliersMapView(List<dynamic> suppliers) {
    // Mode carte interactive simulée pour stabilité 100% hors-ligne
    return Stack(
      children: [
        Container(
          color: AppColors.primary.withValues(alpha: 0.05),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_rounded, size: 64, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text('Carte des Fournisseurs (Mode Offline Actif)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text('${suppliers.length} point(s) de distribution géolocalisé(s)', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: suppliers.map((sup) {
                    final name = sup['name'] ?? '';
                    final zone = sup['zone'] ?? '';
                    final phone = sup['phone'] ?? '';
                    return InkWell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(name),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Zone : $zone'),
                              const SizedBox(height: 8),
                              Text('Tél : $phone'),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.phone),
                              label: const Text('Appeler'),
                              onPressed: () { Navigator.pop(ctx); _launchUrl('tel:$phone'); },
                            ),
                          ],
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          border: Border.all(color: AppColors.accent, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 18),
                            const SizedBox(width: 6),
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentsTab(List<dynamic> equipments) {
    if (equipments.isEmpty) return const Center(child: Text('Aucun matériel agricole trouvé.', style: TextStyle(fontStyle: FontStyle.italic)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: equipments.length,
      itemBuilder: (context, index) {
        final eq = equipments[index];
        final name = eq['name'] ?? '';
        final category = eq['category'] ?? '';
        final zone = eq['zone'] ?? '';
        final supplier = eq['supplier'] ?? '';
        final price = eq['priceFcfa'] ?? 0;
        final rental = eq['rentalAvailable'] ?? false;
        final rentalPrice = eq['rentalPriceFcfaPerDay'] ?? 0;
        final desc = eq['description'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary))),
                    Chip(label: Text(category, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: AppColors.info, visualDensity: VisualDensity.compact),
                  ],
                ),
                const SizedBox(height: 8),
                Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Prix d\'achat estimé :', style: TextStyle(fontSize: 13)),
                          Text('$price FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                        ],
                      ),
                      if (rental) ...[
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Location journalière :', style: TextStyle(fontSize: 13)),
                            Text('$rentalPrice FCFA / jour', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accent)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Distributeur : $supplier ($zone)', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.handshake_rounded, size: 16),
                      label: const Text('Contacter'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mise en relation avec $supplier en cours...'))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstitutionsTab(List<dynamic> institutions) {
    if (institutions.isEmpty) return const Center(child: Text('Aucune institution trouvée.', style: TextStyle(fontStyle: FontStyle.italic)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: institutions.length,
      itemBuilder: (context, index) {
        final inst = institutions[index];
        final name = inst['name'] ?? '';
        final role = inst['role'] ?? '';
        final contact = inst['contactPerson'] ?? '';
        final phone = inst['phone'] ?? '';
        final email = inst['email'] ?? '';
        final zone = inst['zone'] ?? '';
        final desc = inst['description'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundColor: AppColors.primary, child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(role, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.accent)),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3)),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Contact : $contact ($zone)', style: const TextStyle(fontSize: 13, color: Colors.grey))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (email.isNotEmpty)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.email_rounded, size: 16),
                        label: const Text('Email'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                        onPressed: () => _launchUrl('mailto:$email'),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: const Text('Appeler'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: () => _launchUrl('tel:$phone'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String urlStr) async {
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le lien.')));
      }
    }
  }
}
