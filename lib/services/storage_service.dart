import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  String get _userId => _auth.currentUser!.uid;

  // Upload de recibo
  Future<String?> uploadReceipt(XFile imageFile) async {
    try {
      final File file = File(imageFile.path);
      final String fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final Reference ref = _storage.ref().child('receipts/$_userId/$fileName');
      final UploadTask uploadTask = ref.putFile(file);
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Erro no upload: $e');
      return null;
    }
  }

  // Selecionar imagem da galeria
  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      return null;
    }
  }
}