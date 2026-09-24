import 'package:camera/camera.dart';

typedef Rgb = ({double r, double g, double b});

/// Averages the colour of the centre of a camera frame. Only a sparse grid of
/// pixels is read, which keeps this well under 1 ms per frame.
class FrameColorExtractor {
  FrameColorExtractor._();

  static const int _step = 6;

  static Rgb? averageRgb(CameraImage image) {
    switch (image.format.group) {
      case ImageFormatGroup.bgra8888:
        return _bgra(image);
      case ImageFormatGroup.yuv420:
        return image.planes.length >= 3 ? _yuv420(image) : _nv21(image);
      case ImageFormatGroup.nv21:
        return _nv21(image);
      default:
        return null;
    }
  }

  static (int, int, int, int) _centre(CameraImage img) {
    final x0 = img.width ~/ 4, y0 = img.height ~/ 4;
    return (x0, y0, img.width - x0, img.height - y0);
  }

  static Rgb _bgra(CameraImage img) {
    final plane = img.planes.first;
    final bytes = plane.bytes;
    final (x0, y0, x1, y1) = _centre(img);
    var r = 0.0, g = 0.0, b = 0.0;
    var n = 0;
    for (var y = y0; y < y1; y += _step) {
      final row = y * plane.bytesPerRow;
      for (var x = x0; x < x1; x += _step) {
        final i = row + x * 4;
        if (i + 2 >= bytes.length) continue;
        b += bytes[i];
        g += bytes[i + 1];
        r += bytes[i + 2];
        n++;
      }
    }
    return n == 0 ? (r: 0, g: 0, b: 0) : (r: r / n, g: g / n, b: b / n);
  }

  static Rgb _yuv420(CameraImage img) {
    final yPlane = img.planes[0], uPlane = img.planes[1], vPlane = img.planes[2];
    final uvPixel = uPlane.bytesPerPixel ?? 1;
    final (x0, y0, x1, y1) = _centre(img);
    var r = 0.0, g = 0.0, b = 0.0;
    var n = 0;
    for (var y = y0; y < y1; y += _step) {
      for (var x = x0; x < x1; x += _step) {
        final yi = y * yPlane.bytesPerRow + x;
        final uvi = (y >> 1) * uPlane.bytesPerRow + (x >> 1) * uvPixel;
        if (yi >= yPlane.bytes.length || uvi >= uPlane.bytes.length || uvi >= vPlane.bytes.length) continue;
        final rgb = _toRgb(yPlane.bytes[yi], uPlane.bytes[uvi], vPlane.bytes[uvi]);
        r += rgb.r;
        g += rgb.g;
        b += rgb.b;
        n++;
      }
    }
    return n == 0 ? (r: 0, g: 0, b: 0) : (r: r / n, g: g / n, b: b / n);
  }

  static Rgb _nv21(CameraImage img) {
    final bytes = img.planes.first.bytes;
    final w = img.width, h = img.height;
    final (x0, y0, x1, y1) = _centre(img);
    var r = 0.0, g = 0.0, b = 0.0;
    var n = 0;
    for (var y = y0; y < y1; y += _step) {
      for (var x = x0; x < x1; x += _step) {
        final yi = y * w + x;
        final vi = w * h + (y >> 1) * w + (x & ~1);
        if (vi + 1 >= bytes.length) continue;
        final rgb = _toRgb(bytes[yi], bytes[vi + 1], bytes[vi]);
        r += rgb.r;
        g += rgb.g;
        b += rgb.b;
        n++;
      }
    }
    return n == 0 ? (r: 0, g: 0, b: 0) : (r: r / n, g: g / n, b: b / n);
  }

  static Rgb _toRgb(int y, int u, int v) {
    final yy = y.toDouble(), uu = u - 128.0, vv = v - 128.0;
    return (
      r: (yy + 1.402 * vv).clamp(0.0, 255.0),
      g: (yy - 0.344 * uu - 0.714 * vv).clamp(0.0, 255.0),
      b: (yy + 1.772 * uu).clamp(0.0, 255.0),
    );
  }
}
