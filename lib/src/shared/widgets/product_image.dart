import 'package:flutter/material.dart';

/// ProductImage: displays a product image with automatic cover/contain heuristic.
/// Heuristic: if aspect ratio of available box is close to square and we don't know
/// intrinsic size yet, start with contain; when image resolves we compare its
/// aspect ratio to the box; if the difference is small (<15%) we keep contain,
/// else we choose contain when image is very tall or wide (extreme ratios) and
/// cover otherwise.
/// Provides optional rounding, padding, placeholder and error fallback.
class ProductImage extends StatefulWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.borderRadius,
    this.backgroundColor,
    this.padding,
    this.fitMode,
    this.placeholder,
    this.errorIcon = const Icon(Icons.pets),
    this.cacheWidth,
    this.cacheHeight,
    this.clipBehavior = Clip.antiAlias,
    this.semanticLabel,
    this.aspectRatio,
    this.circular = false,
  });

  final String? url;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final BoxFit? fitMode; // Force a fit when provided.
  final Widget? placeholder;
  final Widget errorIcon;
  final int? cacheWidth;
  final int? cacheHeight;
  final Clip clipBehavior;
  final String? semanticLabel;
  final double? aspectRatio; // to reserve layout before load.
  final bool circular;

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  ImageStream? _stream;
  ImageInfo? _info;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _info = null;
      _resolveImage();
    }
  }

  void _resolveImage() {
    final url = widget.url;
    if (url == null || url.isEmpty) return;
    // Detach old listener if any
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    final image = Image.network(url, cacheWidth: widget.cacheWidth, cacheHeight: widget.cacheHeight);
    _stream = image.image.resolve(const ImageConfiguration());
    _listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      if (_info == null) {
        _info = info;
        setState(() {});
      }
    }, onError: (_, __) {
      if (mounted) setState(() {});
    });
    _stream!.addListener(_listener!);
  }

  BoxFit _decideFit(BoxConstraints constraints) {
    if (widget.fitMode != null) return widget.fitMode!;
    final boxRatio = constraints.maxWidth / constraints.maxHeight;
    if (_info == null) {
      // Pre-image heuristic: show contain for square-ish boxes to avoid cropping.
      if (boxRatio > 0.85 && boxRatio < 1.25) return BoxFit.contain;
      return BoxFit.cover; // rectangular placeholder can use cover.
    }
    final imgRatio = _info!.image.width / _info!.image.height;
    final diff = (imgRatio - boxRatio).abs() / boxRatio;
    if (diff < 0.15) return BoxFit.contain; // similar shape
    // extreme tall or wide images: contain
    if (imgRatio > 1.9 || imgRatio < 0.55) return BoxFit.contain;
    return BoxFit.cover;
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    final borderRadius = widget.borderRadius ?? (widget.circular ? BorderRadius.circular(1000) : BorderRadius.circular(12));
  final theme = Theme.of(context);
  final isLight = theme.brightness == Brightness.light;
  final bg = widget.backgroundColor ?? (isLight
    ? const Color(0xFFF3E9DC) // matches AppColors.neutralContainer
    : theme.colorScheme.surfaceContainerHighest);

    Widget child;
    if (url == null || url.isEmpty) {
      child = widget.errorIcon;
    } else {
      child = LayoutBuilder(builder: (context, constraints) {
        final fit = _decideFit(constraints);
        return Image.network(
          url,
          fit: fit,
          semanticLabel: widget.semanticLabel,
          cacheWidth: widget.cacheWidth,
          cacheHeight: widget.cacheHeight,
          errorBuilder: (context, error, stack) => widget.errorIcon,
        );
      });
    }

    final padding = widget.padding ?? const EdgeInsets.all(4);

    Widget painted = Container(
      padding: padding,
      color: bg,
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _info == null && url != null && url.isNotEmpty
            ? (widget.placeholder ?? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
            : child,
      ),
    );

    painted = ClipRRect(borderRadius: borderRadius, clipBehavior: widget.clipBehavior, child: painted);

    if (widget.aspectRatio != null) {
      painted = AspectRatio(aspectRatio: widget.aspectRatio!, child: painted);
    }

    return painted;
  }

  @override
  void dispose() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    super.dispose();
  }
}
