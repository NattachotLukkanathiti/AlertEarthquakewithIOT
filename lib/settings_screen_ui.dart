import 'package:flutter/material.dart';
import 'alert_settings.dart';
import 'settings_screen.dart' show mqttService;
import 'threshold_service.dart';

class SettingsScreenUI extends StatefulWidget {
  const SettingsScreenUI({super.key});

  @override
  State<SettingsScreenUI> createState() => _SettingsScreenUIState();
}

class _SettingsScreenUIState extends State<SettingsScreenUI>
    with SingleTickerProviderStateMixin {
  double dangerValue = AlertSettings.dangerThreshold.toDouble();
  double warningValue = AlertSettings.warningThreshold.toDouble();
  bool _showValidationError = false;
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  static const Color _bgColor = Color(0xFF0B0F1A);
  static const Color _dangerRed = Color(0xFFE53935);
  static const Color _dangerRedLight = Color(0xFFFF5252);
  static const Color _warningAmber = Color(0xFFFFA000);
  static const Color _warningAmberLight = Color(0xFFFFD740);
  static const Color _safeGreen = Color(0xFF43A047);
  static const Color _accentGreen = Color(0xFF00E676);

  @override
  void initState() {
    super.initState();
    mqttService.connect();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (warningValue >= dangerValue) {
      setState(() => _showValidationError = true);
      return;
    }

    setState(() => _showValidationError = false);

    _buttonController.forward().then((_) => _buttonController.reverse());

    await AlertSettings.save(
      danger: dangerValue.round(),
      warning: warningValue.round(),
    );

    mqttService.publishThreshold(
      dangerValue.round(),
      warningValue.round(),
    );

    await ThresholdService.sendThreshold(
      dangerValue.round(),
      warningValue.round(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00E676)),
            SizedBox(width: 10),
            Text("บันทึกสำเร็จ", style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF1A2235),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          "ตั้งค่าการแจ้งเตือน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ─── Danger Card ───
              _ThresholdCard(
                label: "ระดับอันตราย",
                subtitle: "แจ้งเตือนเมื่อค่า ≥ ${dangerValue.round()}",
                value: dangerValue,
                min: 1,
                max: 10,
                activeColor: _dangerRed,
                thumbColor: _dangerRedLight,
                badgeColor: _dangerRed,
                icon: Icons.warning_amber_rounded,
                iconBgColor: const Color(0xFF3B1010),
                iconColor: _dangerRedLight,
                onChanged: (v) => setState(() => dangerValue = v),
              ),

              const SizedBox(height: 16),

              // ─── Warning Card ───
              _ThresholdCard(
                label: "ระดับเฝ้าระวัง",
                subtitle: "แจ้งเตือนเมื่อค่า ≥ ${warningValue.round()}",
                value: warningValue,
                min: 1,
                max: 10,
                activeColor: _warningAmber,
                thumbColor: _warningAmberLight,
                badgeColor: _warningAmber,
                icon: Icons.remove_red_eye_rounded,
                iconBgColor: const Color(0xFF2B1E07),
                iconColor: _warningAmberLight,
                onChanged: (v) => setState(() => warningValue = v),
              ),

              const SizedBox(height: 20),

              // ─── Validation hint ───
              AnimatedOpacity(
                opacity: _showValidationError ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _showValidationError
                        ? const Color(0xFF3B1010)
                        : const Color(0xFF151C2C),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _showValidationError
                          ? _dangerRed.withOpacity(0.7)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: _showValidationError ? _dangerRedLight : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "ค่าเฝ้าระวังต้องน้อยกว่าค่าอันตราย",
                        style: TextStyle(
                          fontSize: 13,
                          color: _showValidationError ? _dangerRedLight : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ─── Zone example bar ───
              _ZoneBar(
                dangerValue: dangerValue.round(),
                warningValue: warningValue.round(),
                safeGreen: _safeGreen,
                warningAmber: _warningAmber,
                dangerRed: _dangerRed,
              ),

              const SizedBox(height: 36),

              // ─── Save Button ───
              ScaleTransition(
                scale: _buttonScale,
                child: GestureDetector(
                  onTap: _onSave,
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C853), Color(0xFF00E676)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _accentGreen.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "บันทึก",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Threshold Card Widget
// ─────────────────────────────────────────────
class _ThresholdCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final Color thumbColor;
  final Color badgeColor;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final ValueChanged<double> onChanged;

  const _ThresholdCard({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.thumbColor,
    required this.badgeColor,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151C2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: activeColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Value badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  value.round().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor: activeColor.withOpacity(0.18),
              thumbColor: thumbColor,
              overlayColor: activeColor.withOpacity(0.18),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 5,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),

          // Min/max labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${min.round()}",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                Text("${max.round()}",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Zone Example Bar Widget
// ─────────────────────────────────────────────
class _ZoneBar extends StatelessWidget {
  final int dangerValue;
  final int warningValue;
  final Color safeGreen;
  final Color warningAmber;
  final Color dangerRed;

  const _ZoneBar({
    required this.dangerValue,
    required this.warningValue,
    required this.safeGreen,
    required this.warningAmber,
    required this.dangerRed,
  });

  @override
  Widget build(BuildContext context) {
    const int total = 9;
    final int safeCount = (warningValue - 1).clamp(0, total);
    final int warnCount = (dangerValue - warningValue).clamp(0, total - safeCount);
    final int dangerCount = (total - safeCount - warnCount).clamp(0, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ตัวอย่างโซนระดับ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              if (safeCount > 0)
                Expanded(
                  flex: safeCount,
                  child: Container(
                    height: 36,
                    color: safeGreen,
                    alignment: Alignment.center,
                    child: const Text("ปลอดภัย",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (warnCount > 0)
                Expanded(
                  flex: warnCount,
                  child: Container(
                    height: 36,
                    color: warningAmber,
                    alignment: Alignment.center,
                    child: const Text("เฝ้าระวัง",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (dangerCount > 0)
                Expanded(
                  flex: dangerCount,
                  child: Container(
                    height: 36,
                    color: dangerRed,
                    alignment: Alignment.center,
                    child: const Text("อันตราย",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("1", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              Text("10", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}