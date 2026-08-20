import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../utils/call_utils.dart';

/// Shows the name of the citizen who reported a complaint, with an optional
/// call button using their profile phone. Fetches the profile once.
///
/// Used by the Head app and the Worker app — RLS lets both read the citizen's
/// contact details (heads read all profiles; workers read citizens whose
/// complaint is assigned to them).
class CitizenContactBar extends StatefulWidget {
  const CitizenContactBar({
    super.key,
    required this.citizenId,
    this.showCallButton = true,
  });

  final String citizenId;

  /// When false, only the name is shown (no call button).
  final bool showCallButton;

  @override
  State<CitizenContactBar> createState() => _CitizenContactBarState();
}

class _CitizenContactBarState extends State<CitizenContactBar> {
  String? _name;
  String? _phone;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    String? name;
    String? phone;
    try {
      final profile =
          await ProfileService.instance.getProfile(widget.citizenId);
      name = profile?.fullName;
      phone = profile?.phone;
    } on Object {
      name = null;
      phone = null;
    }
    if (!mounted) return;
    setState(() {
      _name = name;
      _phone = phone;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 18);

    final name = (_name?.trim().isNotEmpty ?? false) ? _name!.trim() : null;
    final phone = _phone;
    final hasPhone = phone != null && phone.trim().isNotEmpty;

    return Row(
      children: [
        const Icon(Icons.person_outline, size: 15, color: Color(0xFF00838F)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name == null ? 'Citizen profile pending' : 'Reported by: $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00838F),
            ),
          ),
        ),
        if (widget.showCallButton && hasPhone) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Call citizen',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 26, height: 26),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.call_outlined,
                size: 17, color: Color(0xFF1565C0)),
            onPressed: () => callPhoneNumber(context, phone: phone!),
          ),
        ],
      ],
    );
  }
}
