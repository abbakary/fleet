import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/localization_extensions.dart';

class PhotoAnnotationScreen extends StatefulWidget {
  const PhotoAnnotationScreen({
    this.imageFile,
    this.imageBytes,
    required this.contextTitle,
    super.key,
  });

  final File? imageFile;
  final Uint8List? imageBytes;
  final String contextTitle;

  static Future<String?> open(
    BuildContext context, {
    File? imageFile,
    Uint8List? imageBytes,
    required String contextTitle,
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => PhotoAnnotationScreen(
          imageFile: imageFile,
          imageBytes: imageBytes,
          contextTitle: contextTitle,
        ),
      ),
    );
  }

  @override
  State<PhotoAnnotationScreen> createState() => _PhotoAnnotationScreenState();
}

class _PhotoAnnotationScreenState extends State<PhotoAnnotationScreen> {
  ui.Image? _image;
  bool _loading = true;
  Size? _canvasSize;
  double _strokeWidth = 6;
  Color _strokeColor = Colors.redAccent;
  final List<_Stroke> _strokes = <_Stroke>[];
  _Stroke? _activeStroke;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.photoAnnotateTitle(widget.contextTitle)),
        actions: [
          IconButton(
            tooltip: context.l10n.clearAllTooltip,
            icon: const Icon(Icons.clear_all),
            onPressed: _strokes.isEmpty
                ? null
                : () {
                    setState(() {
                      _strokes.clear();
                    });
                  },
          ),
          IconButton(
            tooltip: context.l10n.undoTooltip,
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isEmpty
                ? null
                : () {
                    setState(() {
                      _strokes.removeLast();
                    });
                  },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _image == null
              ? Center(child: Text(context.l10n.unableToLoadImage))
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _image!.width / _image!.height,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(constraints.maxWidth, constraints.maxHeight);
                              _canvasSize = size;
                              return GestureDetector(
                                onPanStart: (details) => _startStroke(details.localPosition),
                                onPanUpdate: (details) => _appendStroke(details.localPosition),
                                onPanEnd: (_) => _finishStroke(),
                                child: CustomPaint(
                                  painter: _AnnotationPainter(
                                    image: _image!,
                                    strokes: _strokes,
                                  ),
                                  size: size,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _buildToolbar(context),
                  ],
                ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 10,
                children: [
                  _ColorDot(
                    color: Colors.redAccent,
                    selected: _strokeColor == Colors.redAccent,
                    onTap: () => setState(() => _strokeColor = Colors.redAccent),
                  ),
                  _ColorDot(
                    color: Colors.amber,
                    selected: _strokeColor == Colors.amber,
                    onTap: () => setState(() => _strokeColor = Colors.amber),
                  ),
                  _ColorDot(
                    color: Colors.lightGreen,
                    selected: _strokeColor == Colors.lightGreen,
                    onTap: () => setState(() => _strokeColor = Colors.lightGreen),
                  ),
                  _ColorDot(
                    color: Colors.cyanAccent,
                    selected: _strokeColor == Colors.cyanAccent,
                    onTap: () => setState(() => _strokeColor = Colors.cyanAccent),
                  ),
                  _ColorDot(
                    color: Colors.white,
                    outline: true,
                    selected: _strokeColor == Colors.white,
                    onTap: () => setState(() => _strokeColor = Colors.white),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.strokeWidthLabel(_strokeWidth.toInt()), style: theme.textTheme.bodySmall),
                  Slider(
                    value: _strokeWidth,
                    min: 2,
                    max: 18,
                    divisions: 8,
                    onChanged: (value) => setState(() => _strokeWidth = value),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_alt),
              label: Text(context.l10n.saveLabelShort),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasImageChanges => _strokes.isNotEmpty;

  Future<void> _loadImage() async {
    try {
      final bytes = widget.imageBytes ?? await widget.imageFile!.readAsBytes();
      if (!mounted) return;
      final image = await decodeImageFromList(bytes);
      if (!mounted) return;
      setState(() {
        _image = image;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _startStroke(Offset localPosition) {
    if (_image == null || _canvasSize == null) {
      return;
    }
    final stroke = _Stroke(
      color: _strokeColor,
      width: _strokeWidth,
      points: <Offset>[_mapToImage(localPosition)],
    );
    setState(() {
      _activeStroke = stroke;
      _strokes.add(stroke);
    });
  }

  void _appendStroke(Offset localPosition) {
    if (_activeStroke == null || _image == null || _canvasSize == null) {
      return;
    }
    setState(() {
      _activeStroke!.points.add(_mapToImage(localPosition));
    });
  }

  void _finishStroke() {
    _activeStroke = null;
  }

  Offset _mapToImage(Offset localPosition) {
    final image = _image;
    final canvasSize = _canvasSize;
    if (image == null || canvasSize == null || canvasSize.width == 0 || canvasSize.height == 0) {
      return localPosition;
    }
    final scaleX = image.width / canvasSize.width;
    final scaleY = image.height / canvasSize.height;
    return Offset(localPosition.dx * scaleX, localPosition.dy * scaleY);
  }

  Future<void> _save() async {
    final annotatedPath = await _exportAnnotatedImage();
    if (!mounted) {
      return;
    }
    if (annotatedPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.unableToSaveAnnotatedPhoto)),
      );
      return;
    }
    Navigator.of(context).pop(annotatedPath);
  }

  Future<String?> _exportAnnotatedImage() async {
    final image = _image;
    if (image == null) {
      return null;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(image.width.toDouble(), image.height.toDouble());
    canvas.drawImage(image, Offset.zero, Paint());

    for (final stroke in _strokes) {
      if (stroke.points.length < 2) {
        continue;
      }
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      for (var index = 0; index < stroke.points.length - 1; index++) {
        canvas.drawLine(stroke.points[index], stroke.points[index + 1], paint);
      }
    }

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(image.width, image.height);
    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return null;
    }
    final bytes = byteData.buffer.asUint8List();
    if (kIsWeb) {
      final encoded = base64Encode(bytes);
      return 'data:image/png;base64,$encoded';
    }
    final directory = await getApplicationDocumentsDirectory();
    final photoDirectory = Directory('${directory.path}/inspection_photos');
    if (!photoDirectory.existsSync()) {
      photoDirectory.createSync(recursive: true);
    }
    final filePath = '${photoDirectory.path}/${DateTime.now().millisecondsSinceEpoch}_annotated.png';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

class _Stroke {
  _Stroke({required this.color, required this.width, required this.points});

  final Color color;
  final double width;
  final List<Offset> points;
}

class _AnnotationPainter extends CustomPainter {
  const _AnnotationPainter({required this.image, required this.strokes});

  final ui.Image image;
  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final dest = Rect.fromLTWH(0, 0, size.width, size.height);
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawRect(dest, Paint()..color = Colors.black);
    canvas.drawImageRect(image, src, dest, Paint());

    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;
    final strokeScale = (scaleX + scaleY) / 2;

    for (final stroke in strokes) {
      if (stroke.points.length < 2) {
        continue;
      }
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width * strokeScale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      for (var index = 0; index < stroke.points.length - 1; index++) {
        final p1 = Offset(stroke.points[index].dx * scaleX, stroke.points[index].dy * scaleY);
        final p2 = Offset(stroke.points[index + 1].dx * scaleX, stroke.points[index + 1].dy * scaleY);
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.strokes != strokes;
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.onTap,
    this.selected = false,
    this.outline = false,
  });

  final Color color;
  final VoidCallback onTap;
  final bool selected;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: outline ? Colors.transparent : color,
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : (outline ? color : Colors.transparent),
              width: selected ? 3 : 2,
            ),
          ),
        ),
      ),
    );
  }
}
