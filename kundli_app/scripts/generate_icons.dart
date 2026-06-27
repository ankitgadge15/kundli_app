import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final imagePath = 'assets/app_icon.jpg';
  print('Loading generated icon from $imagePath');
  
  final file = File(imagePath);
  if (!file.existsSync()) {
    print('Error: Could not find $imagePath. Please ensure the file is copied to assets/ folder.');
    return;
  }
  
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);

  if (image == null) {
    print('Error: Could not decode image.');
    return;
  }

  final sizes = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  for (final entry in sizes.entries) {
    final file = File(entry.key);
    file.parent.createSync(recursive: true);

    // Resize image
    final resized = img.copyResize(image, width: entry.value, height: entry.value);
    
    file.writeAsBytesSync(img.encodePng(resized));
    print('Generated icon: ${entry.key} (${entry.value}x${entry.value})');
  }
  print('Launcher icons generated successfully!');
}
