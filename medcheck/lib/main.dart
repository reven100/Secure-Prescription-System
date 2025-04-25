// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

void main() {
  runApp(const MedCheckApp());
}

class MedCheckApp extends StatelessWidget {
  const MedCheckApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedCheck',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedCheck'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital,
              size: 150,
              color: Colors.blue,
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DoctorLoginScreen()),
                );
              },
              child: const Text('Doctor Login'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DoctorListScreen()),
                );
              },
              child: const Text('Pharmacy Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple key pair class for demonstration
class KeyPair {
  final String publicKey;
  final String privateKey;

  KeyPair({required this.publicKey, required this.privateKey});
}

// Cryptography Service - Simplified for demonstration
class CryptoService {
  static KeyPair generateRSAKeyPair() {
    // In a real app, you'd use a proper crypto library
    // This is just a mock implementation
    final math.Random random = math.Random.secure();
    final String publicKey = "pub_${random.nextInt(10000)}";
    final String privateKey = "priv_${random.nextInt(10000)}";

    return KeyPair(publicKey: publicKey, privateKey: privateKey);
  }

  static String encryptWithPrivateKey(String data, String privateKey) {
    // In a real app, you'd use proper RSA encryption
    // This is simplified for demonstration
    return base64Encode(utf8.encode("$privateKey:$data"));
  }

  static String decryptWithPublicKey(String encryptedData, String publicKey) {
    try {
      // Clean up any potential whitespace or newlines
      encryptedData = encryptedData.trim();

      // In a real app, you'd use proper RSA decryption
      // This is simplified for demonstration
      final decoded = utf8.decode(base64Decode(encryptedData));

      // In a real app, we'd verify the key matches before returning data
      final parts = decoded.split(':');
      if (parts.length < 2) {
        throw FormatException('Invalid encrypted data format');
      }

      // Return everything after the first colon
      // This handles cases where the data itself might contain colons
      return parts.sublist(1).join(':');
    } catch (e) {
      print('Error in decryption: $e for data: $encryptedData');
      rethrow;
    }
  }
}

// Storage Service
class StorageService {
  static Future<void> saveDoctorKeys(
      String doctorName, String publicKey, String privateKey) async {
    final prefs = await SharedPreferences.getInstance();

    // Save doctor name in the list of doctors
    List<String> doctors = prefs.getStringList('doctors') ?? [];
    if (!doctors.contains(doctorName)) {
      doctors.add(doctorName);
      await prefs.setStringList('doctors', doctors);
    }

    // Save doctor's keys
    await prefs.setString('public_key_$doctorName', publicKey);
    await prefs.setString('private_key_$doctorName', privateKey);
  }

  static Future<List<String>> getDoctorsList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('doctors') ?? [];
  }

  static Future<String?> getDoctorPublicKey(String doctorName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('public_key_$doctorName');
  }

  static Future<String?> getDoctorPrivateKey(String doctorName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('private_key_$doctorName');
  }

  static Future<bool> doctorExists(String doctorName) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> doctors = prefs.getStringList('doctors') ?? [];
    return doctors.contains(doctorName);
  }
}

// Doctor Login Screen
class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({Key? key}) : super(key: key);

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login / Register'),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String doctorName = _nameController.text.trim();
    final bool exists = await StorageService.doctorExists(doctorName);

    if (exists) {
      // Existing doctor, load keys
      final publicKey = await StorageService.getDoctorPublicKey(doctorName);
      final privateKey = await StorageService.getDoctorPrivateKey(doctorName);

      if (publicKey == null || privateKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading keys')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Navigate to prescription screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PrescriptionScreen(
            doctorName: doctorName,
            publicKey: publicKey,
            privateKey: privateKey,
          ),
        ),
      );
    } else {
      // New doctor, generate keys
      final keyPair = CryptoService.generateRSAKeyPair();
      await StorageService.saveDoctorKeys(
        doctorName,
        keyPair.publicKey,
        keyPair.privateKey,
      );

      // Navigate to prescription screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PrescriptionScreen(
            doctorName: doctorName,
            publicKey: keyPair.publicKey,
            privateKey: keyPair.privateKey,
          ),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
}

// Prescription Screen
class PrescriptionScreen extends StatefulWidget {
  final String doctorName;
  final String publicKey;
  final String privateKey;

  const PrescriptionScreen({
    Key? key,
    required this.doctorName,
    required this.publicKey,
    required this.privateKey,
  }) : super(key: key);

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  String? _encryptedData;
  bool _showQR = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${widget.doctorName} - Prescription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_showQR) ...[
              TextField(
                controller: _patientNameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _medicationController,
                decoration: const InputDecoration(
                  labelText: 'Medication',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage & Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _generatePrescription,
                child: const Text('Generate QR Code'),
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Text(
                      'Prescription for ${_patientNameController.text}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_encryptedData != null)
                      QrImageView(
                        data: _encryptedData!,
                        version: QrVersions.auto,
                        size: 280,
                        backgroundColor: Colors.white,
                      ),
                    const SizedBox(height: 20),
                    if (_encryptedData != null) ...[
                      const Text(
                        'QR Code Text (for manual entry):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            SelectableText(
                              _encryptedData!,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy to Clipboard'),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _encryptedData!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Copied to clipboard')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showQR = false;
                        });
                      },
                      child: const Text('Create New Prescription'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _generatePrescription() {
    if (_patientNameController.text.isEmpty ||
        _medicationController.text.isEmpty ||
        _dosageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Create prescription data
    final prescriptionData = jsonEncode({
      'doctor': widget.doctorName,
      'patient': _patientNameController.text,
      'medication': _medicationController.text,
      'dosage': _dosageController.text,
      'date': DateTime.now().toIso8601String(),
    });

    // Encrypt the data
    final encrypted = CryptoService.encryptWithPrivateKey(
      prescriptionData,
      widget.privateKey,
    );

    setState(() {
      _encryptedData = encrypted;
      _showQR = true;
    });
  }
}

// Doctor List Screen
class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({Key? key}) : super(key: key);

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  List<String> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final doctors = await StorageService.getDoctorsList();
    setState(() {
      _doctors = doctors;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Doctor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
              ? const Center(
                  child: Text(
                    'No doctors registered yet',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text('Dr. ${_doctors[index]}'),
                      onTap: () => _selectDoctor(_doctors[index]),
                    );
                  },
                ),
    );
  }

  Future<void> _selectDoctor(String doctorName) async {
    final publicKey = await StorageService.getDoctorPublicKey(doctorName);
    if (publicKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading doctor\'s key')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          doctorName: doctorName,
          publicKey: publicKey,
        ),
      ),
    );
  }
}

// QR Scanner Screen
class QRScannerScreen extends StatefulWidget {
  final String doctorName;
  final String publicKey;

  const QRScannerScreen({
    Key? key,
    required this.doctorName,
    required this.publicKey,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _scanComplete = false;
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Dr. ${widget.doctorName}\'s Prescription'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && !_scanComplete) {
                  final String code = barcodes.first.rawValue ?? '';
                  _processQRCode(code);
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                const Text(
                  'Or enter code manually:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _manualCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Paste QR code text here',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_manualCodeController.text.isNotEmpty) {
                      _processQRCode(_manualCodeController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a code')),
                      );
                    }
                  },
                  child: const Text('Process Manual Code'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processQRCode(String encryptedData) {
    setState(() {
      _scanComplete = true;
    });

    try {
      // Debug: Trim whitespace in case that's causing issues
      String cleanEncryptedData = encryptedData.trim();

      // Add debug message to see what's being processed
      print('Processing QR Code text: $cleanEncryptedData');

      // Decrypt the data
      final decryptedData = CryptoService.decryptWithPublicKey(
        cleanEncryptedData,
        widget.publicKey,
      );

      // Debug: See what's coming back from decryption before attempting to parse it
      print('Decrypted data: $decryptedData');

      try {
        // Parse the JSON
        final Map<String, dynamic> prescription = jsonDecode(decryptedData);

        // Show the prescription
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PrescriptionViewScreen(prescription: prescription),
          ),
        );
      } catch (jsonError) {
        // More specific error handling for JSON parsing
        print('JSON parsing error: $jsonError in string: $decryptedData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('JSON parsing error: ${jsonError.toString()}')),
        );
        setState(() {
          _scanComplete = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('Decryption error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decode: ${e.toString()}')),
      );
      setState(() {
        _scanComplete = false;
      });
    }
  }
}

// Prescription View Screen
class PrescriptionViewScreen extends StatelessWidget {
  final Map<String, dynamic> prescription;

  const PrescriptionViewScreen({
    Key? key,
    required this.prescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doctor: ${prescription['doctor']}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Text(
                  'Patient: ${prescription['patient']}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Medication: ${prescription['medication']}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dosage: ${prescription['dosage']}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${DateTime.parse(prescription['date']).toLocal().toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const MainScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
