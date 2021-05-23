import 'dart:math';

import 'package:image/image.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

/// Abstract class for all algorithms
abstract class Algorithm {
  /// Tuple of [Pixel] lists for [src1] and [src2]
  @protected
  var _pixelListPair;

  /// Default constructor gets implicitly called on subclass instantiation
  Algorithm() {
    _pixelListPair = Tuple2<List, List>([], []);
  }

  /// Creates lists of [Pixel] for [src1] and [src2] for sub class compare operations
  double compare(Image src1, Image src2) {
    // RGB intensities
    var bytes1 = src1.getBytes(format: Format.rgb);
    var bytes2 = src2.getBytes(format: Format.rgb);

    for (var i = 0; i <= bytes1.length - 3; i += 3) {
      _pixelListPair.item1.add(Pixel(bytes1[i], bytes1[i + 1], bytes1[i + 2]));
    }

    for (var i = 0; i <= bytes2.length - 3; i += 3) {
      _pixelListPair.item2.add(Pixel(bytes2[i], bytes2[i + 1], bytes2[i + 2]));
    }

    return 0.0; // default return
  }
}

/// Organizational class for storing [src1] and [src2] data
class Pixel {
  final int _red;
  final int _blue;
  final int _green;

  Pixel(this._red, this._blue, this._green);
}

/// Algorithm class for comparing images pixel-by-pixel
abstract class DirectAlgorithm extends Algorithm {

  /// Resizes images if dimensions do not match.
  /// If different sizes, larger image will be 
  /// resized to the smaller image
  @override
  double compare(Image src1, Image src2) {
    if (src1.width != src2.width && 
        src1.height != src2.height) {
      var size1 = src1.width * src1.height;
      var size2 = src2.width * src2.height;

      if (size1 < size2) {
        src2 = copyResize(src2, height: src1.height, width: src1.width);
      } else {
        src1 = copyResize(src1, height: src2.height, width: src2.width);
      }
    }

    // Delegates pixel extraction to parent
    super.compare(src1, src2);

    return 1.0;
  }
}

/// Algorithm class for comparing images with euclidean color distance
class EuclideanColorDistanceAlgorithm extends DirectAlgorithm {

  /// Computes euclidean color distance between two images
  /// of the same size
  @override
  double compare(Image src1, Image src2) {
    // Delegates image resizing to parent
    super.compare(src1, src2);

    var sum = 0.0;

    var numPixels = src1.width * src1.height;
    for (var i = 0; i < numPixels; i++) {
      sum += sqrt(pow((_pixelListPair.item1[i]._red - _pixelListPair.item2[i]._red) / 255, 2) +
                  pow((_pixelListPair.item1[i]._blue - _pixelListPair.item2[i]._blue) / 255, 2) +
                  pow((_pixelListPair.item1[i]._green - _pixelListPair.item2[i]._green) / 255, 2));
    }

    return sum;
  }
}

class PixelMatchingAlgorithm extends DirectAlgorithm {

  /// Computes overlap between two images's color intensities.
  /// Return value is the fraction similarity e.g. 0.1 means 10%
  @override
  double compare(Image src1, Image src2) {
    // Delegates image resizing to parent
    super.compare(src1, src2);

    var count = 0;
    // percentage leniency for pixel comparison
    var delta = 0.05 * 256;

    var numPixels = src1.width * src1.height;

    for (var i = 0; i < numPixels; i++) {
      if (_withinRange(delta, _pixelListPair.item1[i]._red, _pixelListPair.item2[i]._red) &&
          _withinRange(delta, _pixelListPair.item1[i]._blue, _pixelListPair.item2[i]._blue) &&
          _withinRange(delta, _pixelListPair.item1[i]._green, _pixelListPair.item2[i]._green)) {
        
        count++;
      }
    }

    return count / numPixels; // fraction similarity
  }

  bool _withinRange(var delta, var value, var target) {
    return (target - delta < value && value < target + delta);
  }
}

class IMEDAlgorithm extends DirectAlgorithm {

  /// Computes distance between two images
  /// using image euclidean distance
  @override
  double compare(Image src1, Image src2) {
    // Delegates image resizing to parent
    super.compare(src1, src2);

    var sum = 0.0;

    for (var i = 0; i < _pixelListPair.item1.length; i++) {
      for (var j = 0; j < _pixelListPair.item1.length; j++) {
        var x = _pixelListPair.item1; // src1 pixel list
        var y = _pixelListPair.item2; // src2 pixel list
        
        sum += exp(-pow(_distance(i, j, src1.width), 2) / 2) * 
               (_grayValue(x[i]) - _grayValue(y[i])) / 255 *
               (_grayValue(x[j]) - _grayValue(y[j])) / 255;
      }
    }

    return sum * (1 / (2 * pi));
  }

  /// Helper function to return grayscale value of a pixel
  int _grayValue(Pixel p) {
    return getLuminanceRgb(p._red, p._green, p._blue);
  }

  /// Helper function to return distance between two pixels at 
  /// indices [i] and [j]
  double _distance(var i, var j, var width) {
    var distance = 0.0;
    var pointA = Tuple2((i % width), (i / width));
    var pointB = Tuple2((j % width), (j / width));

    distance = sqrt(pow(pointB.item1 - pointA.item1, 2) + 
                    pow(pointB.item2 - pointA.item2, 2));

    return distance;
  }
}

/// Algorithm class for comparing images with hashing
abstract class HashAlgorithm extends Algorithm {

  /// Resizes images to same dimension
  @override
  double compare(Image src1, Image src2) {
    src1 = copyResize(grayscale(src1), height: 8, width: 8);
    src2 = copyResize(grayscale(src2), height: 8, width: 8);

    // Delegates pixel extraction to parent
    super.compare(src1, src2);

    return 0.0; //default return
  }

  double hamming_distance(String str1, String str2) {
    var dist_counter = 0;
    for (var i = 0; i < str1.length; i++) {
      dist_counter += str1[i] != str2[i] ? 1 : 0;
    }
    return pow((dist_counter / str1.length), 2) * 100;
  }
}

/// Algorithm class for comparing images with average hash
class Average_Hash extends HashAlgorithm {

  /// Calculates average hash of [src1] and [src2], returns hamming distance
  @override
  double compare(Image src1, Image src2) {
    // Delegates image resizing to parent
    super.compare(src1, src2);
   
    var hash1 = average_hash_algo(_pixelListPair.item1);
    var hash2 = average_hash_algo(_pixelListPair.item2);

    // Delegates hamming distance computation to parent
    return super.hamming_distance(hash1, hash2);
  }

  /// Computes average hash string for an image
  String average_hash_algo(List pixel_list) {
    var src_array = pixel_list.map((e) => e._red).toList();

    var bit_string = '';

    var mean = (src_array.reduce((a, b) => a + b) / src_array.length);
    src_array.asMap().forEach((key, value) {
      src_array[key] = value > mean ? 1 : 0;
    });

    src_array.forEach((element) {
      bit_string += (1 * element).toString();
    });

    return BigInt.parse(bit_string, radix: 2).toRadixString(16);
  }
}

/// Abstract class for all histogram algorithms
abstract class HistogramAlgorithm extends Algorithm {
  /// Number of bins in each histogram
  @protected
  var _binSize;

  /// Histograms for [src1] and [src2] stored in a Tuple2
  @protected
  var _histograms;

  /// Default constructor gets implicitly called on subclass instantiation
  HistogramAlgorithm() {
    _binSize = 256;
    _histograms =
        Tuple2(List.filled(_binSize, 0.0), List.filled(_binSize, 0.0));
  }

  /// Fills color intensity histograms for child class compare operations
  @override
  double compare(Image src1, Image src2) {
    // Delegates pixel extraction to parent
    super.compare(src1, src2);

    for (Pixel pixel in _pixelListPair.item1) {
      _histograms.item1[pixel._red] += 1;
      _histograms.item1[pixel._blue] += 1;
      _histograms.item1[pixel._green] += 1;
    }

    for (Pixel pixel in _pixelListPair.item2) {
      _histograms.item2[pixel._red] += 1;
      _histograms.item2[pixel._blue] += 1;
      _histograms.item2[pixel._green] += 1;
    }

    return 0.0; // default return
  }
}

/// Algorithm class for comparing images with chi-square histogram intersections
/// 
/// Images are converted to histogram representations (x-axis intensity, y-axis frequency).
/// The chi-square distance formula is applied to compute the distance between each bin:
/// 
/// 0.5* sum((binCount1 - binCount2)^2 / (binCount1 + binCount2))
/// 
/// Number of histograms bins is 256. Frequencies for RGB intensities are counted in
/// one histogram representation.
class ChiSquareHistogramAlgorithm extends HistogramAlgorithm {
  /// Calculates histogram similarity using chi-squared distance
  @override
  double compare(Image src1, Image src2) {
    // Delegates histogram initialization to parent
    super.compare(src1, src2);

    var sum = 0.0;
    for (var i = 0; i < _binSize; i++) {
      var count1 = _histograms.item1[i] / (src1.width * src1.height);
      var count2 = _histograms.item2[i] / (src2.width * src2.height);

      sum += (count1 + count2 != 0)
          ? ((count1 - count2) * (count1 - count2)) / (count1 + count2)
          : 0;
    }
    sum *= 0.5;

    return sum;
  }
}

/// Algorithm class for comparing images with standard histogram intersection.
/// 
/// Images are converted to histogram representations (x-axis intensity, y-axis frequency).
/// Generated histograms are overlayed to examine percentage overlap, thereby indicating
/// percentage similarity in pixel intensity frequencies:
/// 
/// sum(min(binCount1, binCount2))
/// 
/// Number of histograms bins is 256. Frequencies for RGB intensities are counted in
/// one histogram representation.
class IntersectionHistogramAlgorithm extends HistogramAlgorithm {
  /// Calculates histogram similarity using standard intersection
  @override
  double compare(Image src1, Image src2) {
    // Delegates histogram initialization to parent
    super.compare(src1, src2);

    var sum = 0.0;
    for (var i = 0; i < _binSize; i++) {
      var count1 = _histograms.item1[i];
      var count2 = _histograms.item2[i];

      sum += min(count1, count2);
    }

    return sum /
        (src2.width * src2.height); // percentage of [src2] that matches [src1]
  }
}
