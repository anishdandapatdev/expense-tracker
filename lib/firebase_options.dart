import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyDzYcZZujKEsH4N8xbE6MZ1ihXBe79D_Vk',
      appId: '1:301427047333:android:c6704a079de149e58cc64c',
      messagingSenderId: '301427047333',
      projectId: 'expensetracker-c9938',
      authDomain: 'expensetracker-c9938.firebaseapp.com',
      storageBucket: 'expensetracker-c9938.firebasestorage.app',
    );
  }
}
