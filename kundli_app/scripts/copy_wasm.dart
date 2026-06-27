import 'dart:io';
import 'dart:isolate';

void main() async {
  try {
    print('Resolving swisseph package path...');
    final packageUri = Uri.parse('package:swisseph/swisseph.dart');
    final resolvedUri = await Isolate.resolvePackageUri(packageUri);
    
    if (resolvedUri == null) {
      print('Error: Could not resolve package:swisseph. Please run "flutter pub get" first.');
      exit(1);
    }
    
    // resolvedUri is: file:///path/to/swisseph/lib/swisseph.dart
    // We navigate to package root and find its assets folder
    final packageLibDir = Directory.fromUri(resolvedUri).parent;
    final packageRootDir = packageLibDir.parent;
    final assetsDir = Directory('${packageRootDir.path}/assets');
    
    final jsFile = File('${assetsDir.path}/swisseph.js');
    final wasmFile = File('${assetsDir.path}/swisseph.wasm');
    
    if (!jsFile.existsSync() || !wasmFile.existsSync()) {
      print('Error: Could not find swisseph.js or swisseph.wasm in package assets.');
      exit(1);
    }
    
    // Ensure assets/ directory exists in project root
    final projectAssetsDir = Directory('assets');
    if (!projectAssetsDir.existsSync()) {
      projectAssetsDir.createSync();
    }
    
    // Copy files
    jsFile.copySync('assets/swisseph.js');
    wasmFile.copySync('assets/swisseph.wasm');
    
    print('Success: Copied swisseph.js and swisseph.wasm to project assets/ directory!');
  } catch (e) {
    print('An error occurred: $e');
    exit(1);
  }
}
