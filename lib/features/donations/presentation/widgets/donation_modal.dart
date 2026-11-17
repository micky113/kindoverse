import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../campaigns/domain/models/project.dart';
import '../../../campaigns/presentation/providers/campaign_providers.dart';

/// Multi-tier donation modal with quick amounts, custom input, 80G tax exemption
/// PAN capture, anonymize donor toggle, and Razorpay/Stripe checkout hook.
class DonationModal extends ConsumerStatefulWidget {
  final Project project;

  const DonationModal({super.key, required this.project});

  static Future<void> show(BuildContext context, Project project) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => DonationModal(project: project),
    );
  }

  @override
  ConsumerState<DonationModal> createState() => _DonationModalState();
}

class _DonationModalState extends ConsumerState<DonationModal> {
  static const List<int> _quickTiers = [1000, 2500, 5000, 15000, 50000];

  int _selectedTier = 2500;
  late final TextEditingController _amountController;
  late final TextEditingController _nameController;
  late final TextEditingController _panController;
  bool _claim80GTaxExemption = true;
  bool _isAnonymous = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final activeUser = ref.read(activeUserProvider);
    _amountController = TextEditingController(text: _selectedTier.toString());
    _nameController = TextEditingController(text: activeUser.name);
    _panController = TextEditingController(text: activeUser.panOrTaxId ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout() async {
    final parsedAmount = num.tryParse(_amountController.text.trim()) ?? 0;
    if (parsedAmount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum contribution is ₹100.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate Razorpay / Stripe payment gateway intent + Firestore creation
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final donation = await ref
        .read(campaignRepositoryProvider)
        .submitDonation(
          projectId: widget.project.id,
          donorName: _nameController.text,
          isAnonymous: _isAnonymous,
          amount: parsedAmount,
          panOrTaxId: _claim80GTaxExemption ? _panController.text.trim() : null,
        );

    if (!mounted) return;
    setState(() => _isProcessing = false);
    Navigator.of(context).pop();

    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryEmerald,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Thank you! ${currencyFmt.format(donation.amount)} verified (Ref: ${donation.paymentGatewayRef}). 80G Receipt queued.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_rounded,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fund Verified Impact',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          widget.project.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Quick Tier Pills
              const Text(
                'Select Impact Tier (INR)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _quickTiers.map((tier) {
                      final isSelected = _selectedTier == tier;
                      return ChoiceChip(
                        label: Text(currencyFmt.format(tier)),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedTier = tier;
                            _amountController.text = tier.toString();
                          });
                        },
                        selectedColor: AppColors.primaryEmerald,
                        labelStyle: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              // Custom Amount Input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null) {
                    setState(() => _selectedTier = parsed);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Custom Contribution Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // Donor Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name / Corporate Entity Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Anonymize Donor Toggle
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v),
                title: const Text(
                  'Make my contribution anonymous on public ledger',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Your identity remains recorded only on your official 80G tax receipt.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),

              // 80G Tax Exemption Toggle & PAN Capture
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _claim80GTaxExemption,
                onChanged:
                    (v) => setState(() => _claim80GTaxExemption = v ?? false),
                title: const Text(
                  'Claim 80G Income Tax Exemption Certificate (50% Deduction)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              if (_claim80GTaxExemption) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _panController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'PAN / CSR Tax Identification Number',
                    hintText: 'e.g. ABCDE1234F',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon:
                    _isProcessing
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.lock_outline_rounded, size: 18),
                label: Text(
                  _isProcessing
                      ? 'Verifying Gateway Webhook...'
                      : 'Complete Contribution via Razorpay / Stripe',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
