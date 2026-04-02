import 'package:flutter_driver/driver_extension.dart';
import 'main.dart' as app;

void main() {
  // Habilita la extensión para que pueda sacar capturas de pantalla desde el PC
  enableFlutterDriverExtension();
  
  // Lanza la aplicación original
  app.main();
}
