import 'package:flutter/material.dart';

/// Wraps a thumbnail photo; tapping it opens a small dialog box showing the
/// full image (fit to the dialog) with a close (✕) button at the top-right.
///
/// Use [dialogImage] to provide a version of the image rendered for the
/// dialog (e.g. without a fixed height and with `BoxFit.contain`) so the
/// whole photo is visible. Defaults to [thumbnail].
class ViewableImage extends StatelessWidget {
  const ViewableImage({
    super.key,
    required this.thumbnail,
    this.dialogImage,
  });

  /// The thumbnail shown in place (e.g. a rounded `Image.network`/`Image.file`).
  final Widget thumbnail;

  /// Optional image shown inside the dialog. Defaults to [thumbnail].
  final Widget? dialogImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDialog(context),
      child: thumbnail,
    );
  }

  void _openDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _ImageViewDialog(image: dialogImage ?? thumbnail),
    );
  }
}

class _ImageViewDialog extends StatelessWidget {
  const _ImageViewDialog({required this.image});

  final Widget image;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width * 0.85,
              maxHeight: size.height * 0.6,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  child: image,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
