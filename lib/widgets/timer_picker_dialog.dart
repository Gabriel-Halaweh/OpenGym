import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class TimerPickerDialog extends StatefulWidget {
  final int initialSeconds;

  const TimerPickerDialog({super.key, this.initialSeconds = 0});

  static Future<int?> show(BuildContext context, {int initialSeconds = 0}) {
    return showDialog<int?>(
      context: context,
      builder: (ctx) => TimerPickerDialog(initialSeconds: initialSeconds),
    );
  }

  @override
  State<TimerPickerDialog> createState() => _TimerPickerDialogState();
}

class _TimerPickerDialogState extends State<TimerPickerDialog> {
  String _digits = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialSeconds > 0) {
      final h = widget.initialSeconds ~/ 3600;
      final m = (widget.initialSeconds % 3600) ~/ 60;
      final s = widget.initialSeconds % 60;
      final formattedString = '${h.toString()}${m.toString().padLeft(2, '0')}${s.toString().padLeft(2, '0')}';
      _digits = int.parse(formattedString).toString(); // remove leading zeros
      if (_digits == '0') _digits = '';
    }
  }

  void _onNumPress(String num) {
    setState(() {
      if (_digits.length < 6) {
        _digits += num;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_digits.isNotEmpty) {
        _digits = _digits.substring(0, _digits.length - 1);
      }
    });
  }

  void _onClear() {
    setState(() {
      _digits = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pad to 6
    String padded = _digits.padLeft(6, '0');
    String h = padded.substring(0, 2);
    String m = padded.substring(2, 4);
    String s = padded.substring(4, 6);

    return Dialog(
      backgroundColor: AppConstants.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildTimeDisplay(h, 'h', _digits.length > 4),
                const SizedBox(width: 8),
                _buildTimeDisplay(m, 'm', _digits.length > 2),
                const SizedBox(width: 8),
                _buildTimeDisplay(s, 's', _digits.isNotEmpty),
              ],
            ),
            const SizedBox(height: 32),
            // Numpad
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumButton('1'),
                    _buildNumButton('2'),
                    _buildNumButton('3'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumButton('4'),
                    _buildNumButton('5'),
                    _buildNumButton('6'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumButton('7'),
                    _buildNumButton('8'),
                    _buildNumButton('9'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNumButton('00'),
                    _buildNumButton('0'),
                    _buildIconBtn(Icons.backspace_rounded, _onBackspace, onLongPress: _onClear),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('CANCEL', style: TextStyle(color: AppConstants.textMuted)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final hv = int.tryParse(h) ?? 0;
                    final mv = int.tryParse(m) ?? 0;
                    final sv = int.tryParse(s) ?? 0;
                    final totalSeconds = hv * 3600 + mv * 60 + sv;
                    Navigator.pop(context, totalSeconds);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.accentPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SET'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(String val, String label, bool isActive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(val, style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w600, color: isActive ? AppConstants.textPrimary : AppConstants.textMuted.withValues(alpha: 0.5))),
        const SizedBox(width: 2),
        Text(label, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: isActive ? AppConstants.accentPrimary : AppConstants.textMuted.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildNumButton(String num) {
    return GestureDetector(
      onTap: () {
        if (num == '00') {
           _onNumPress('0');
           _onNumPress('0');
        } else {
           _onNumPress(num);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppConstants.bgSurface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(num, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w500, color: AppConstants.textPrimary)),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap, {VoidCallback? onLongPress}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.transparent, // transparent bg unlike num buttons
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: AppConstants.textPrimary),
      ),
    );
  }
}
