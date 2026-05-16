import 'dart:io';
import 'dart:typed_data';

/// Écriture EXIF minimale en Dart pur pour injecter des coordonnées GPS dans
/// un fichier JPEG existant.
///
/// Pourquoi Dart pur plutôt que `native_exif` : le package natif a des
/// incompatibilités sur Windows/Linux desktop (cible dev) et nos photos sont
/// toutes des JPEG issues d'ImagePicker avec `imageQuality: 80`. L'implémentation
/// ci-dessous suit strictement TIFF 6.0 + EXIF 2.32 (big-endian, IFD0 minimale
/// pointant vers GPS IFD).
///
/// Usage :
/// ```dart
/// await ExifWriter.writeGps(
///   file: File(xfile.path),
///   latitude: 14.6928,
///   longitude: -17.4467,
///   altitude: 12.0,
/// );
/// ```
///
/// Après écriture, `exiftool photo.jpg` affiche bien GPSLatitude/GPSLongitude.
class ExifWriter {
  ExifWriter._();

  /// Injecte un segment APP1 EXIF avec les champs GPS dans [file].
  /// Si un APP1 EXIF existe déjà, il est remplacé.
  /// Si [file] n'est pas un JPEG valide ou en cas d'erreur, renvoie false sans
  /// lever d'exception (observation peut continuer sans géotag).
  static Future<bool> writeGps({
    required File file,
    required double latitude,
    required double longitude,
    double? altitude,
    DateTime? timestamp,
  }) async {
    try {
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      if (bytes.length < 4) return false;
      // JPEG SOI marker
      if (bytes[0] != 0xFF || bytes[1] != 0xD8) return false;

      final exifApp1 = _buildExifApp1(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        timestamp: timestamp ?? DateTime.now().toUtc(),
      );

      // Recherche existing APP1 Exif segment (starts with "Exif\x00\x00") et
      // le retire avant d'insérer le nouveau.
      final out = BytesBuilder();
      out.add([0xFF, 0xD8]); // SOI

      int i = 2;
      bool inserted = false;
      while (i < bytes.length - 1) {
        if (bytes[i] != 0xFF) break;
        final marker = bytes[i + 1];
        // SOS (Start Of Scan) → stop parsing headers
        if (marker == 0xDA || marker == 0xD9) {
          if (!inserted) {
            out.add(exifApp1);
            inserted = true;
          }
          out.add(bytes.sublist(i));
          return _writeBack(file, out.toBytes());
        }
        // Standalone markers (no size)
        if (marker == 0xD0 ||
            marker == 0xD1 ||
            marker == 0xD2 ||
            marker == 0xD3 ||
            marker == 0xD4 ||
            marker == 0xD5 ||
            marker == 0xD6 ||
            marker == 0xD7 ||
            marker == 0xD8) {
          out.add([bytes[i], bytes[i + 1]]);
          i += 2;
          continue;
        }
        if (i + 3 >= bytes.length) break;
        final segLen = (bytes[i + 2] << 8) | bytes[i + 3]; // length incl. 2 bytes
        if (segLen < 2 || i + 2 + segLen > bytes.length) break;

        final isApp1Exif = marker == 0xE1 &&
            segLen >= 8 &&
            bytes[i + 4] == 0x45 && // 'E'
            bytes[i + 5] == 0x78 && // 'x'
            bytes[i + 6] == 0x69 && // 'i'
            bytes[i + 7] == 0x66; // 'f'

        if (isApp1Exif) {
          // Remplace : on saute l'ancien segment et on insère le nouveau
          out.add(exifApp1);
          inserted = true;
          i += 2 + segLen;
          continue;
        }

        // Sinon on recopie le segment tel quel, puis on insère juste après le
        // premier segment (typiquement JFIF APP0) si pas encore fait.
        out.add(bytes.sublist(i, i + 2 + segLen));
        i += 2 + segLen;

        if (!inserted) {
          out.add(exifApp1);
          inserted = true;
        }
      }

      // Sécurité : si on n'a jamais inséré (fichier tronqué, par ex.)
      if (!inserted) {
        out.add(exifApp1);
      }
      if (i < bytes.length) {
        out.add(bytes.sublist(i));
      }

      return _writeBack(file, out.toBytes());
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _writeBack(File file, Uint8List data) async {
    try {
      await file.writeAsBytes(data, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Construction du segment APP1 EXIF (big-endian) ----------------------

  static Uint8List _buildExifApp1({
    required double latitude,
    required double longitude,
    double? altitude,
    required DateTime timestamp,
  }) {
    // Structure :
    //   APP1 marker (0xFFE1) + length (2 bytes, BE, incluant les 2 bytes de length)
    //   "Exif\x00\x00" (6 bytes)
    //   TIFF header (8 bytes) : 'MM' 0x002A offset(IFD0 = 8)
    //   IFD0 : N entrées + next IFD offset (0) + pointeur GPS IFD
    //   GPS IFD
    //   Données variables référencées par offset

    final tiff = BytesBuilder();
    // TIFF header
    tiff.add([0x4D, 0x4D]); // 'MM' big-endian
    tiff.add(_u16(0x002A));
    tiff.add(_u32(8)); // offset to IFD0 from start of TIFF

    // IFD0 : 1 entrée (GPSInfo pointer) + 0 (no next IFD)
    // Position après IFD0 = 8 (header) + 2 (count) + 12 (one entry) + 4 (next) = 26
    // → GPS IFD commence à offset 26 dans TIFF space
    const gpsIfdOffset = 26;

    tiff.add(_u16(1)); // entries count
    // Entry : GPSInfo tag 0x8825, type LONG (4), count 1, value = offset
    tiff.add(_u16(0x8825));
    tiff.add(_u16(4)); // LONG
    tiff.add(_u32(1)); // count
    tiff.add(_u32(gpsIfdOffset));
    tiff.add(_u32(0)); // next IFD offset = 0

    // --- GPS IFD ----------------------------------------------------------
    // Tags :
    //   0x0000 GPSVersionID        BYTE[4]          value inline (2,3,0,0)
    //   0x0001 GPSLatitudeRef      ASCII[2]         'N' or 'S'
    //   0x0002 GPSLatitude         RATIONAL[3]      offset
    //   0x0003 GPSLongitudeRef     ASCII[2]         'E' or 'W'
    //   0x0004 GPSLongitude        RATIONAL[3]      offset
    //   0x0005 GPSAltitudeRef      BYTE[1]          inline
    //   0x0006 GPSAltitude         RATIONAL[1]      offset
    //   0x0007 GPSTimeStamp        RATIONAL[3]      offset (UTC h,m,s)
    //   0x001D GPSDateStamp        ASCII[11]        offset ("YYYY:MM:DD\0")

    final hasAlt = altitude != null;
    final entryCount = hasAlt ? 9 : 7;

    // Prévisualiser les offsets des blocs "externes" (>4 octets).
    // GPS IFD occupies : 2 (count) + entryCount*12 + 4 (next=0)
    final gpsIfdSize = 2 + entryCount * 12 + 4;
    int externalOffset = gpsIfdOffset + gpsIfdSize;

    // Prépare les blocs externes
    final externalBlocks = <Uint8List>[];
    int addExternal(Uint8List block) {
      final off = externalOffset;
      externalBlocks.add(block);
      externalOffset += block.length;
      return off;
    }

    final latRational = _degToRationals(latitude.abs());
    final lonRational = _degToRationals(longitude.abs());
    final latRef = latitude >= 0 ? 'N' : 'S';
    final lonRef = longitude >= 0 ? 'E' : 'W';
    final utc = timestamp.toUtc();
    final timeRational = Uint8List.fromList([
      ..._u32(utc.hour), ..._u32(1),
      ..._u32(utc.minute), ..._u32(1),
      ..._u32(utc.second), ..._u32(1),
    ]);
    final dateStr = '${utc.year.toString().padLeft(4, '0')}:'
        '${utc.month.toString().padLeft(2, '0')}:'
        '${utc.day.toString().padLeft(2, '0')}\x00';
    final dateBytes = Uint8List.fromList(dateStr.codeUnits);

    final latOffset = addExternal(latRational);
    final lonOffset = addExternal(lonRational);
    int? altOffset;
    Uint8List? altRational;
    if (hasAlt) {
      altRational = _ratBlock(altitude.abs(), 100);
      altOffset = addExternal(altRational);
    }
    final timeOffset = addExternal(timeRational);
    final dateOffset = addExternal(dateBytes);

    // --- GPS IFD entries
    final gps = BytesBuilder();
    gps.add(_u16(entryCount));

    // 0x0000 GPSVersionID : BYTE[4] = 2,3,0,0
    gps.add(_u16(0x0000));
    gps.add(_u16(1)); // BYTE
    gps.add(_u32(4));
    gps.add([0x02, 0x03, 0x00, 0x00]);

    // 0x0001 GPSLatitudeRef : ASCII[2] 'N\0'
    gps.add(_u16(0x0001));
    gps.add(_u16(2));
    gps.add(_u32(2));
    gps.add([latRef.codeUnitAt(0), 0x00, 0x00, 0x00]);

    // 0x0002 GPSLatitude : RATIONAL[3]
    gps.add(_u16(0x0002));
    gps.add(_u16(5));
    gps.add(_u32(3));
    gps.add(_u32(latOffset));

    // 0x0003 GPSLongitudeRef
    gps.add(_u16(0x0003));
    gps.add(_u16(2));
    gps.add(_u32(2));
    gps.add([lonRef.codeUnitAt(0), 0x00, 0x00, 0x00]);

    // 0x0004 GPSLongitude
    gps.add(_u16(0x0004));
    gps.add(_u16(5));
    gps.add(_u32(3));
    gps.add(_u32(lonOffset));

    if (hasAlt) {
      // 0x0005 GPSAltitudeRef : BYTE, 0 = above sea level, 1 = below
      gps.add(_u16(0x0005));
      gps.add(_u16(1));
      gps.add(_u32(1));
      gps.add([altitude < 0 ? 0x01 : 0x00, 0x00, 0x00, 0x00]);

      // 0x0006 GPSAltitude
      gps.add(_u16(0x0006));
      gps.add(_u16(5));
      gps.add(_u32(1));
      gps.add(_u32(altOffset!));
    }

    // 0x0007 GPSTimeStamp : RATIONAL[3] (h, m, s UTC)
    gps.add(_u16(0x0007));
    gps.add(_u16(5));
    gps.add(_u32(3));
    gps.add(_u32(timeOffset));

    // 0x001D GPSDateStamp : ASCII[11]
    gps.add(_u16(0x001D));
    gps.add(_u16(2));
    gps.add(_u32(dateBytes.length));
    gps.add(_u32(dateOffset));

    gps.add(_u32(0)); // next IFD = 0

    tiff.add(gps.toBytes());
    for (final block in externalBlocks) {
      tiff.add(block);
    }

    final tiffBytes = tiff.toBytes();

    // APP1 : "Exif\0\0" + tiffBytes
    final app1Payload = BytesBuilder();
    app1Payload.add([0x45, 0x78, 0x69, 0x66, 0x00, 0x00]); // "Exif\0\0"
    app1Payload.add(tiffBytes);

    final payloadLen = app1Payload.length + 2; // includes the length bytes

    // length field is 16-bit → max 65535. En pratique ici très largement < 300.
    if (payloadLen > 0xFFFF) {
      // ne devrait jamais arriver avec notre payload fixe
      return Uint8List(0);
    }

    final segment = BytesBuilder();
    segment.add([0xFF, 0xE1]); // APP1
    segment.add(_u16(payloadLen));
    segment.add(app1Payload.toBytes());
    return segment.toBytes();
  }

  /// Convertit un angle décimal (positif) en 3 rationnels deg/min/sec.
  /// Représentation : deg entier / 1, min entier / 1, sec * 1000 / 1000.
  static Uint8List _degToRationals(double deg) {
    final d = deg.floor();
    final minFloat = (deg - d) * 60;
    final m = minFloat.floor();
    final s = (minFloat - m) * 60;
    final sNum = (s * 1000).round();
    final b = BytesBuilder();
    b.add(_u32(d));
    b.add(_u32(1));
    b.add(_u32(m));
    b.add(_u32(1));
    b.add(_u32(sNum));
    b.add(_u32(1000));
    return b.toBytes();
  }

  /// Bloc rationnel unique : value = num/den.
  static Uint8List _ratBlock(double value, int den) {
    final num = (value * den).round();
    final b = BytesBuilder();
    b.add(_u32(num));
    b.add(_u32(den));
    return b.toBytes();
  }

  static List<int> _u16(int v) => [(v >> 8) & 0xFF, v & 0xFF];
  static List<int> _u32(int v) => [
        (v >> 24) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 8) & 0xFF,
        v & 0xFF,
      ];
}
