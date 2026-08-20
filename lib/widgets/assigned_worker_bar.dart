import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/call_utils.dart';

/// Shows the worker assigned to a citizen's complaint: the worker's **name**
/// (instead of just the Worker ID) plus a call button using their profile
/// phone. Falls back to the Worker ID when the profile cannot be read.
class AssignedWorkerBar extends StatefulWidget {
  const AssignedWorkerBar({super.key, required this.workerId});

  /// The department Worker ID stored on the complaint (e.g. `WK-1001`).
  final String workerId;

  @override
  State<AssignedWorkerBar> createState() => _AssignedWorkerBarState();
}

class _AssignedWorkerBarState extends State<AssignedWorkerBar> {
  AppUser? _worker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    AppUser? worker;
    try {
      worker =
          await AuthService.instance.getWorkerByWorkerId(widget.workerId);
    } on Object {
      worker = null;
    }
    if (!mounted) return;
    setState(() {
      _worker = worker;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 18);

    final worker = _worker;
    final name = worker?.name;
    final hasName = name != null && name.trim().isNotEmpty;
    final phone = worker?.phone;
    final hasPhone = phone != null && phone.trim().isNotEmpty;

    return Row(
      children: [
        const Icon(Icons.local_shipping_outlined,
            size: 15, color: Color(0xFF1565C0)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            hasName ? '${name!.trim()} (${widget.workerId})' : widget.workerId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (hasPhone) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Call worker',
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
