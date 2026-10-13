import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/injector.dart';
import '../../../utils/helper/storage_helper.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../products/cubit/product_cubit.dart';
import '../../../main.dart';

class BackendSelectionScreen extends StatefulWidget {
  final bool isInitialSetup;

  const BackendSelectionScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  State<BackendSelectionScreen> createState() => _BackendSelectionScreenState();
}

class _BackendSelectionScreenState extends State<BackendSelectionScreen> {
  late BackendType _selectedType;
  final TextEditingController _customUrlController = TextEditingController();
  bool _useCustomUrl = false;
  bool _isSaving = false;

  // Health ping state
  bool _isPingingSupabase = false;
  String? _supabasePingResult;
  bool? _supabasePingSuccess;

  bool _isPingingMongo = false;
  String? _mongoPingResult;
  bool? _mongoPingSuccess;

  @override
  void initState() {
    super.initState();
    _selectedType = StorageHelper().getSelectedBackend() ?? ApiConstants.activeBackend;
    final savedCustom = StorageHelper().getCustomBackendUrl(_selectedType);
    if (savedCustom != null && savedCustom.isNotEmpty) {
      _useCustomUrl = true;
      _customUrlController.text = savedCustom;
    } else {
      _customUrlController.text = _selectedType.defaultUrl;
    }
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _pingBackend(BackendType type) async {
    final targetUrl = _useCustomUrl && _selectedType == type && _customUrlController.text.trim().isNotEmpty
        ? _customUrlController.text.trim()
        : type.defaultUrl;

    if (type == BackendType.supabase) {
      setState(() {
        _isPingingSupabase = true;
        _supabasePingResult = null;
        _supabasePingSuccess = null;
      });
    } else {
      setState(() {
        _isPingingMongo = true;
        _mongoPingResult = null;
        _mongoPingSuccess = null;
      });
    }

    final res = await Injector.testConnection(targetUrl);
    final isSuccess = res['success'] == true;
    final message = isSuccess
        ? 'Online (${res['data']?['database'] ?? 'Ready'})'
        : (res['message']?.toString() ?? 'Unreachable');

    if (!mounted) return;
    setState(() {
      if (type == BackendType.supabase) {
        _isPingingSupabase = false;
        _supabasePingSuccess = isSuccess;
        _supabasePingResult = message;
      } else {
        _isPingingMongo = false;
        _mongoPingSuccess = isSuccess;
        _mongoPingResult = message;
      }
    });
  }

  Future<void> _applySelection() async {
    setState(() => _isSaving = true);

    final customUrl = _useCustomUrl && _customUrlController.text.trim().isNotEmpty
        ? _customUrlController.text.trim()
        : null;

    // Save preferences
    await StorageHelper().saveSelectedBackend(_selectedType);
    await StorageHelper().saveCustomBackendUrl(_selectedType, customUrl);

    // Apply to ApiConstants & Injector
    ApiConstants.setBackend(_selectedType, customUrl: customUrl);
    Injector.updateBaseUrl();

    if (!mounted) return;

    // Refresh Cubits to re-evaluate auth status & reload products for the newly selected backend
    context.read<AuthCubit>().checkAuthStatus();
    context.read<ProductCubit>().fetchProducts();

    if (widget.isInitialSetup) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connected to ${_selectedType.displayName}',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isInitialSetup ? 'Backend Configuration' : 'Switch Backend Server',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.dns_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Database Engine',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select whether this app connects to PostgreSQL via Supabase or NoSQL via MongoDB Atlas.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Option 1: Supabase
                _buildBackendOptionCard(
                  type: BackendType.supabase,
                  title: 'Supabase (PostgreSQL)',
                  subtitle: 'Relational Cloud SQL Backend',
                  tag: 'PostgreSQL',
                  tagColor: const Color(0xFF6366F1),
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFF6366F1),
                  url: BackendType.supabase.defaultUrl,
                  isPinging: _isPingingSupabase,
                  pingSuccess: _supabasePingSuccess,
                  pingMessage: _supabasePingResult,
                  onPing: () => _pingBackend(BackendType.supabase),
                ),
                const SizedBox(height: 16),

                // Option 2: MongoDB
                _buildBackendOptionCard(
                  type: BackendType.mongodb,
                  title: 'MongoDB (NoSQL)',
                  subtitle: 'MongoDB Atlas + Mongoose Node.js Backend',
                  tag: 'NoSQL Atlas',
                  tagColor: const Color(0xFF10B981),
                  icon: Icons.eco_rounded,
                  iconColor: const Color(0xFF10B981),
                  url: BackendType.mongodb.defaultUrl,
                  isPinging: _isPingingMongo,
                  pingSuccess: _mongoPingSuccess,
                  pingMessage: _mongoPingResult,
                  onPing: () => _pingBackend(BackendType.mongodb),
                ),
                const SizedBox(height: 24),

                // Advanced Custom URL Configuration
                Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: _useCustomUrl,
                    tilePadding: EdgeInsets.zero,
                    leading: const Icon(Icons.settings_ethernet_rounded),
                    title: const Text(
                      'Advanced Server URL / Localhost',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      _useCustomUrl
                          ? 'Using custom URL override'
                          : 'Using default cloud URL on Render',
                      style: const TextStyle(fontSize: 12),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Enable Custom URL Override'),
                              subtitle: const Text('Useful for local Node.js server or emulator testing'),
                              value: _useCustomUrl,
                              onChanged: (val) {
                                setState(() {
                                  _useCustomUrl = val;
                                  if (!val) {
                                    _customUrlController.text = _selectedType.defaultUrl;
                                  }
                                });
                              },
                            ),
                            if (_useCustomUrl) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _customUrlController,
                                decoration: InputDecoration(
                                  labelText: 'Base URL',
                                  hintText: 'http://10.0.2.2:3000 or http://localhost:3000',
                                  prefixIcon: const Icon(Icons.link),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ActionChip(
                                    label: const Text('Render Cloud'),
                                    onPressed: () {
                                      _customUrlController.text = _selectedType.defaultUrl;
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text('Android (10.0.2.2:3000)'),
                                    onPressed: () {
                                      _customUrlController.text = 'http://10.0.2.2:3000';
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text('Localhost (localhost:3000)'),
                                    onPressed: () {
                                      _customUrlController.text = 'http://localhost:3000';
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                FilledButton.icon(
                  onPressed: _isSaving ? null : _applySelection,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    widget.isInitialSetup
                        ? 'Continue with ${_selectedType.shortName}'
                        : 'Apply & Switch to ${_selectedType.shortName}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackendOptionCard({
    required BackendType type,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required IconData icon,
    required Color iconColor,
    required String url,
    required bool isPinging,
    required bool? pingSuccess,
    required String? pingMessage,
    required VoidCallback onPing,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (!_useCustomUrl) {
            _customUrlController.text = type.defaultUrl;
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? tagColor.withValues(alpha: 0.08)
              : theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? tagColor : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tagColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon Avatar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tagColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tagColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? tagColor : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: tagColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Endpoint & Live Ping Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      url,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: isPinging ? null : onPing,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: isPinging
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_tethering,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Test Ping',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            if (pingMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    pingSuccess == true ? Icons.check_circle : Icons.error_outline,
                    size: 14,
                    color: pingSuccess == true ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pingMessage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: pingSuccess == true ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
