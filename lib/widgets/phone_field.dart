import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/config/countries.dart';

class CountryFlag extends StatelessWidget {
  const CountryFlag(this.code, {super.key, this.width = 24});

  final String code;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SvgPicture.asset(
        'assets/flags/${code.toLowerCase()}.svg',
        width: width,
        height: width * 3 / 4,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Mobile number with a flag and calling-code picker.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryCode,
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryCode;

  static const _border = Color(0xFFD5DBE5);
  static const _ink = Color(0xFF16233A);

  @override
  Widget build(BuildContext context) {
    final selected = Countries.byCode(countryCode);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mobile Number', style: TextStyle(fontSize: 13, color: Color(0xFF6B7A90))),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _openPicker(context),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CountryFlag(selected.code),
                        const SizedBox(width: 6),
                        Text(selected.dialCode, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink)),
                        const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF6B7A90)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 1, height: 28, child: ColoredBox(color: _border)),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14.5, color: _ink),
                    decoration: const InputDecoration(
                      hintText: '202 555 0123',
                      hintStyle: TextStyle(color: Color(0xFF8A95A6)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => _DialCodePicker(selected: countryCode),
    );
    if (picked != null && picked != countryCode) onCountryCode(picked);
  }
}

/// Joins the chosen calling code and the typed number. Empty when no digits were entered.
String composePhone(String countryCode, String raw) {
  final dial = Countries.byCode(countryCode).dialCode;
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty || dial.isEmpty) return digits.isEmpty ? '' : raw.trim();
  final codeDigits = dial.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith(codeDigits)) digits = digits.substring(codeDigits.length);
  digits = digits.replaceFirst(RegExp(r'^0+'), '');
  if (digits.isEmpty) return '';
  return '$dial $digits';
}

class _DialCodePicker extends StatefulWidget {
  const _DialCodePicker({required this.selected});

  final String selected;

  @override
  State<_DialCodePicker> createState() => _DialCodePickerState();
}

class _DialCodePickerState extends State<_DialCodePicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final rows = Countries.all.where((country) {
      if (query.isEmpty) return true;
      return country.name.toLowerCase().contains(query) ||
          country.dialCode.contains(query) ||
          country.code.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search country or code',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final country = rows[index];
                  final chosen = country.code == widget.selected;
                  return ListTile(
                    leading: CountryFlag(country.code, width: 28),
                    title: Text(country.name),
                    trailing: Text(country.dialCode, style: const TextStyle(fontWeight: FontWeight.w700)),
                    selected: chosen,
                    onTap: () => Navigator.pop(context, country.code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
