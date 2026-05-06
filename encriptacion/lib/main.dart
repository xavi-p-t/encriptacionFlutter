import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/asymmetric/api.dart' as rsa;

void main() {
  runApp(const RSAEncryptorApp());
}

class RSAEncryptorApp extends StatelessWidget {
  const RSAEncryptorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RSA File Encryptor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const EncryptorHomePage(),
    );
  }
}

class EncryptorHomePage extends StatefulWidget {
  const EncryptorHomePage({super.key});

  @override
  State<EncryptorHomePage> createState() => _EncryptorHomePageState();
}

class _EncryptorHomePageState extends State<EncryptorHomePage> {
  String? publicKeyPath;
  String? targetFilePath;

  String? privateKeyPath = '~/.ssh/id_rsa';
  String? encryptedFilePath;
  String? decryptedDestinationPath;

  Future<void> _seleccionarArchivo(Function(String) onSeleccionado) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        onSeleccionado(result.files.single.path!);
      });
    }
  }

  Future<void> _seleccionarDestinoGuardado() async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: '¿Dónde quieres guardar el archivo descifrado?',
      fileName: 'archivo_descifrado.txt',
    );
    if (outputFile != null) {
      setState(() {
        decryptedDestinationPath = outputFile;
      });
    }
  }

  void _encriptar() {
    if (publicKeyPath == null || targetFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona la clave pública y el archivo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final clauString = File(publicKeyPath!).readAsStringSync();
      final parser = enc.RSAKeyParser();
      final clauPublica = parser.parse(clauString) as rsa.RSAPublicKey;

      final encriptador = enc.Encrypter(enc.RSA(publicKey: clauPublica));

      final textOriginal = File(targetFilePath!).readAsStringSync();
      final textEncriptat = encriptador.encrypt(textOriginal);
      
      final rutaGuardado = '$targetFilePath.enc';
      File(rutaGuardado).writeAsBytesSync(textEncriptat.bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Archivo encriptado correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al encriptar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _desencriptar() {
    if (privateKeyPath == null || encryptedFilePath == null || decryptedDestinationPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, rellena todos los campos para desencriptar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final claveString = File(privateKeyPath!).readAsStringSync();
      final parser = enc.RSAKeyParser();
      final clavePrivada = parser.parse(claveString) as rsa.RSAPrivateKey;

      final encriptador = enc.Encrypter(enc.RSA(privateKey: clavePrivada));

      final bytesCifrados = File(encryptedFilePath!).readAsBytesSync();
      final textDescifrado = encriptador.decrypt(enc.Encrypted(bytesCifrados));

      File(decryptedDestinationPath!).writeAsStringSync(textDescifrado);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Archivo desencriptado correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al desencriptar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Herramienta de Encriptación RSA'),
        backgroundColor: Colors.red.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Encriptar',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Encriptar archivo',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSelectionBar(
                    label: 'Clave pública (RSA):',
                    selectedFile: publicKeyPath,
                    onPressed: () => _seleccionarArchivo((ruta) => publicKeyPath = ruta),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSelectionBar(
                    label: 'Archivo a encriptar:',
                    selectedFile: targetFilePath,
                    onPressed: () => _seleccionarArchivo((ruta) => targetFilePath = ruta),
                  ),
                  
                  const Spacer(),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: _encriptar,
                      child: const Text(
                        'Encriptar archivo',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: VerticalDivider(thickness: 1, color: Colors.grey),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Desencriptar',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Desencriptar archivo',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSelectionBar(
                    label: 'Clave privada (RSA):',
                    selectedFile: privateKeyPath,
                    onPressed: () => _seleccionarArchivo((ruta) => privateKeyPath = ruta),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSelectionBar(
                    label: 'Archivo cifrado:',
                    selectedFile: encryptedFilePath,
                    onPressed: () => _seleccionarArchivo((ruta) => encryptedFilePath = ruta),
                  ),

                  const SizedBox(height: 24),
                  
                  _buildSelectionBar(
                    label: 'Guardar archivo descifrado en:',
                    selectedFile: decryptedDestinationPath,
                    onPressed: _seleccionarDestinoGuardado, 
                  ),
                  
                  const Spacer(),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: _desencriptar,
                      child: const Text(
                        'Desencriptar archivo',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar({
    required String label,
    required String? selectedFile,
    required VoidCallback onPressed,
  }) {
    String displayString = 'Ningún archivo seleccionado';
    if (selectedFile != null) {
      displayString = selectedFile.split(Platform.pathSeparator).last;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Text(
                  displayString,
                  style: TextStyle(
                    color: selectedFile != null ? Colors.black87 : Colors.grey,
                    fontStyle: selectedFile != null ? FontStyle.normal : FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: const Text('Buscar'),
            ),
          ],
        ),
      ],
    );
  }
}