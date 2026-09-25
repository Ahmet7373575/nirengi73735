import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/note_merge_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Result returned from the merge dialog.
enum MergeChoice { keepLocal, useCloud, manualMerge }

class MergeDialogResult {
  final MergeChoice choice;

  /// Only populated when [choice] == [MergeChoice.manualMerge].
  final Map<String, String>? mergedValues;

  const MergeDialogResult({required this.choice, this.mergedValues});
}

/// Shows a conflict resolution dialog with three options:
/// 1. Keep local version
/// 2. Use cloud version
/// 3. Manually merge field by field
class NoteMergeDialog extends StatefulWidget {
  final DraftConflict conflict;

  const NoteMergeDialog({super.key, required this.conflict});

  /// Convenience static method to show the dialog.
  static Future<MergeDialogResult?> show(
    BuildContext context,
    DraftConflict conflict,
  ) {
    return showDialog<MergeDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NoteMergeDialog(conflict: conflict),
    );
  }

  @override
  State<NoteMergeDialog> createState() => _NoteMergeDialogState();
}

class _NoteMergeDialogState extends State<NoteMergeDialog>
    with SingleTickerProviderStateMixin {
  bool _showManualMerge = false;

  /// For manual merge: key → selected source ('local' or 'cloud')
  late Map<String, String> _fieldChoices;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    // Default: prefer local for all conflicting fields
    _fieldChoices = {
      for (final key in widget.conflict.diffFields.keys) key: 'local',
    };
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Map<String, String> _buildMergedValues() {
    final result = <String, String>{};
    for (final entry in _fieldChoices.entries) {
      final diff = widget.conflict.diffFields[entry.key]!;
      result[entry.key] =
          (entry.value == 'local' ? diff['local'] : diff['cloud']).toString();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
        child: Container(
          constraints: BoxConstraints(maxHeight: 80.h),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: AppTheme.primary.withAlpha(80),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(120),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _showManualMerge
                      ? _buildManualMergeView()
                      : _buildChoiceView(),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 3.w, 2.w, 2.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.primary.withAlpha(60), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: CustomIconWidget(
              iconName: 'merge_type',
              color: Colors.orange,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Senkronizasyon Çakışması',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.conflict.diffFields.length} alanda yerel ve bulut sürümü farklı',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          if (_showManualMerge)
            IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: Colors.white54,
                size: 20,
              ),
              onPressed: () => setState(() => _showManualMerge = false),
              tooltip: 'Geri',
            ),
        ],
      ),
    );
  }

  Widget _buildChoiceView() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diff summary
          _buildDiffSummary(),
          SizedBox(height: 2.h),
          Text(
            'Nasıl devam etmek istersiniz?',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildOptionCard(
            icon: 'phone_android',
            iconColor: AppTheme.primary,
            title: 'Yerel Sürümü Koru',
            subtitle: 'Cihazınızdaki değişiklikler geçerli olur',
            onTap: () => Navigator.of(
              context,
            ).pop(const MergeDialogResult(choice: MergeChoice.keepLocal)),
          ),
          SizedBox(height: 1.h),
          _buildOptionCard(
            icon: 'cloud_download',
            iconColor: Colors.blue,
            title: 'Bulut Sürümünü Kullan',
            subtitle: 'Sunucudaki veriler yerel değişikliklerin üzerine yazar',
            onTap: () => Navigator.of(
              context,
            ).pop(const MergeDialogResult(choice: MergeChoice.useCloud)),
          ),
          SizedBox(height: 1.h),
          _buildOptionCard(
            icon: 'compare_arrows',
            iconColor: Colors.orange,
            title: 'Manuel Birleştir',
            subtitle: 'Her alan için yerel veya bulut sürümünü seçin',
            onTap: () => setState(() => _showManualMerge = true),
          ),
          SizedBox(height: 1.h),
        ],
      ),
    );
  }

  Widget _buildDiffSummary() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(20),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'info_outline',
                color: Colors.orange,
                size: 16,
              ),
              SizedBox(width: 2.w),
              Text(
                'Farklı Alanlar',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...widget.conflict.diffFields.entries.map((entry) {
            final label = NoteMergeService.fieldLabels[entry.key] ?? entry.key;
            final localVal = entry.value['local']?.toString() ?? '';
            final cloudVal = entry.value['cloud']?.toString() ?? '';
            return Padding(
              padding: EdgeInsets.only(bottom: 0.8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22.w,
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 9.5.sp,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _diffChip(
                          'Yerel',
                          localVal,
                          AppTheme.primary.withAlpha(180),
                        ),
                        SizedBox(height: 0.3.h),
                        _diffChip(
                          'Bulut',
                          cloudVal,
                          Colors.blue.withAlpha(180),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _diffChip(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: color.withAlpha(100)),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8.5.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 1.5.w),
        Expanded(
          child: Text(
            value.isEmpty ? '(boş)' : value,
            style: GoogleFonts.inter(
              fontSize: 9.5.sp,
              color: value.isEmpty ? Colors.white30 : Colors.white70,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.0),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark.withAlpha(180),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: iconColor.withAlpha(60), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: CustomIconWidget(
                  iconName: icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 9.5.sp,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: 'chevron_right',
                color: Colors.white30,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualMergeView() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Her alan için bir sürüm seçin',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.5.h),
          ...widget.conflict.diffFields.entries.map((entry) {
            final label = NoteMergeService.fieldLabels[entry.key] ?? entry.key;
            final localVal = entry.value['local']?.toString() ?? '';
            final cloudVal = entry.value['cloud']?.toString() ?? '';
            final selected = _fieldChoices[entry.key] ?? 'local';

            return Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.white60,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.6.h),
                  Row(
                    children: [
                      Expanded(
                        child: _mergeFieldOption(
                          label: 'Yerel',
                          value: localVal,
                          color: AppTheme.primary,
                          isSelected: selected == 'local',
                          onTap: () => setState(
                            () => _fieldChoices[entry.key] = 'local',
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: _mergeFieldOption(
                          label: 'Bulut',
                          value: cloudVal,
                          color: Colors.blue,
                          isSelected: selected == 'cloud',
                          onTap: () => setState(
                            () => _fieldChoices[entry.key] = 'cloud',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 1.h),
        ],
      ),
    );
  }

  Widget _mergeFieldOption({
    required String label,
    required String value,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(2.5.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(30) : AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? color : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 1.5.w),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9.5.sp,
                    color: isSelected ? color : Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              value.isEmpty ? '(boş)' : value,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: value.isEmpty ? Colors.white30 : Colors.white70,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.primary.withAlpha(40))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white38,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              child: Text('İptal', style: GoogleFonts.inter(fontSize: 10.sp)),
            ),
          ),
          if (_showManualMerge) ...[
            SizedBox(width: 2.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    MergeDialogResult(
                      choice: MergeChoice.manualMerge,
                      mergedValues: _buildMergedValues(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Birleştirmeyi Uygula',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
