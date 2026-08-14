import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enablePasswordToggle = false,
    this.validator,
    this.inputFormatters,
    this.autocorrect = true,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enablePasswordToggle;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool autocorrect;
  final void Function(String)? onFieldSubmitted;
  final int maxLines;
  final int? minLines;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscureText,
          validator: widget.validator,
          inputFormatters: widget.inputFormatters,
          autocorrect: widget.autocorrect,
          onFieldSubmitted: widget.onFieldSubmitted,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          decoration: InputDecoration(
            hintText: widget.hint ?? widget.label,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 22, color: const Color(0xFF2E7D32))
                : null,
            suffixIcon: widget.enablePasswordToggle
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF616161),
                    ),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
