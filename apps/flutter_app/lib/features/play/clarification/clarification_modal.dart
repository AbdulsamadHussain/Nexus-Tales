import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../data/services/network_exception.dart';
import '../../../shared/widgets/index.dart';

/// Modal dialog for handling ambiguous player actions
/// Shows clarification prompt and collects player's choice
class ClarificationModal extends ConsumerStatefulWidget {
  final String prompt;
  final Map<String, dynamic> context;
  final String previousClientTurnId;
  final Future<void> Function(String answer) onSubmit;

  const ClarificationModal({
    Key? key,
    required this.prompt,
    required this.context,
    required this.previousClientTurnId,
    required this.onSubmit,
  }) : super(key: key);

  @override
  ConsumerState<ClarificationModal> createState() =>
      _ClarificationModalState();
}

class _ClarificationModalState extends ConsumerState<ClarificationModal> {
  late final TextEditingController _answerController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final answer = _answerController.text.trim();

    if (answer.isEmpty) {
      setState(() {
        _errorMessage = 'Please provide a clarification answer.';
      });
      return;
    }

    if (answer.length > 200) {
      setState(() {
        _errorMessage = 'Answer too long (max 200 characters).';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(answer);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on ClarificationRequiredException catch (e) {
      // Still ambiguous - show new clarification prompt
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show another clarification modal with new prompt
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => ClarificationModal(
            prompt: e.prompt,
            context: e.clarificationContext ?? {},
            previousClientTurnId: e.clientTurnIdForRetry,
            onSubmit: widget.onSubmit,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting clarification: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'The story needs clarification',
                  style: AppTypography.headingMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: !_isSubmitting
                      ? () => Navigator.of(context).pop()
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Clarification prompt
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceHover,
                border: Border.all(color: AppColors.accentGold),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                widget.prompt,
                style: AppTypography.bodyLarge.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.accentGold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Context display (if available)
            if (widget.context.isNotEmpty) ...[
              Text(
                'Context:',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildContextDisplay(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Answer input
            TextField(
              controller: _answerController,
              enabled: !_isSubmitting,
              maxLines: 3,
              maxLength: 200,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Provide clarification...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surfaceHover,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: AppBorders.thin,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusDanger,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(
                  label: 'Cancel',
                  isEnabled: !_isSubmitting,
                  onPressed: !_isSubmitting ? () => Navigator.of(context).pop() : () {},
                ),
                const SizedBox(width: 12),
                PrimaryButton(
                  label: _isSubmitting ? 'Submitting...' : 'Continue',
                  icon: Icons.send,
                  isLoading: _isSubmitting,
                  isEnabled: !_isSubmitting,
                  onPressed: !_isSubmitting ? _handleSubmit : () async {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextDisplay() {
    // Extract meaningful context info for display
    final entries = widget.context.entries.toList();
    
    if (entries.isEmpty) {
      return Text(
        'No additional context',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: entries.map((entry) {
        final value = entry.value;
        final displayValue = value is List
            ? value.join(', ')
            : value.toString();
        
        return Chip(
          label: Text('${entry.key}: $displayValue'),
          backgroundColor: AppColors.surfaceCard,
          side: BorderSide(color: AppColors.accentGold),
        );
      }).toList(),
    );
  }
}
