import 'dart:io';

void main() async {
  print('Starting complete project restructuring...');

  // 1. Create Directories
  final dirs = [
    'lib/core/routing',
    'lib/features/auth',
    'lib/features/dashboard',
    'lib/features/expenses',
    'lib/features/reports',
    'lib/features/friends',
    'lib/features/settings',
    'lib/features/main',
    'lib/models',
    'lib/services',
    'lib/repositories',
  ];
  for (var dir in dirs) {
    Directory(dir).createSync(recursive: true);
  }

  // 2. File Movement Map (Old Path -> New Path)
  final moveMap = {
    'lib/src/routing/app_router.dart': 'lib/core/routing/app_router.dart',
    'lib/src/shared/constants.dart': 'lib/core/constants.dart',
    'lib/src/shared/currency_service.dart': 'lib/services/currency_service.dart',
    'lib/src/app/app.dart': 'lib/core/app.dart',
    'lib/src/app/providers.dart': 'lib/core/providers.dart',
    
    'lib/src/features/authentication/domain/user_model.dart': 'lib/models/user_model.dart',
    'lib/src/features/expenses/domain/account_model.dart': 'lib/models/account_model.dart',
    'lib/src/features/expenses/domain/category_model.dart': 'lib/models/category_model.dart',
    'lib/src/features/expenses/domain/expense_model.dart': 'lib/models/expense_model.dart',
    
    'lib/src/features/authentication/data/auth_repository.dart': 'lib/repositories/auth_repository.dart',
    'lib/src/features/expenses/data/account_repository.dart': 'lib/repositories/account_repository.dart',
    'lib/src/features/expenses/data/category_repository.dart': 'lib/repositories/category_repository.dart',
    'lib/src/features/expenses/data/expense_repository.dart': 'lib/repositories/expense_repository.dart',
    
    'lib/src/features/authentication/presentation/login_screen.dart': 'lib/features/auth/login_screen.dart',
    'lib/src/features/authentication/presentation/register_screen.dart': 'lib/features/auth/register_screen.dart',
    'lib/src/features/authentication/presentation/onboarding_screen.dart': 'lib/features/auth/onboarding_screen.dart',
    
    'lib/src/features/expenses/presentation/dashboard_screen.dart': 'lib/features/dashboard/dashboard_screen.dart',
    
    'lib/src/features/expenses/presentation/add_expense_screen.dart': 'lib/features/expenses/add_expense_screen.dart',
    'lib/src/features/expenses/presentation/category_management_screen.dart': 'lib/features/expenses/category_management_screen.dart',
    'lib/src/features/expenses/presentation/account_management_screen.dart': 'lib/features/expenses/account_management_screen.dart',
    
    'lib/src/features/analytics/analytics_screen.dart': 'lib/features/reports/analytics_screen.dart',
    'lib/src/features/settings/settings_screen.dart': 'lib/features/settings/settings_screen.dart',
    'lib/src/features/main/main_screen.dart': 'lib/features/main/main_screen.dart',
  };

  final fileNameToNewPackagePath = <String, String>{};
  for (var entry in moveMap.entries) {
    final oldPath = entry.key;
    final newPath = entry.value;
    final fileName = oldPath.split('/').last;
    final packagePath = newPath.replaceFirst('lib/', 'package:expense_tracker/');
    fileNameToNewPackagePath[fileName] = packagePath;
  }

  // Execute file moves
  for (var entry in moveMap.entries) {
    final oldFile = File(entry.key);
    if (oldFile.existsSync()) {
      print('Moving ${entry.key} -> ${entry.value}');
      // In windows, renameSync works across same drive, but nested directories must exist (they do).
      oldFile.renameSync(entry.value);
    } else {
      print('Skipping (not found): ${entry.key}');
    }
  }

  // Iterate all .dart files in lib/ and test/
  void processDir(Directory dir) {
    if (!dir.existsSync()) return;
    for (var entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = entity.readAsStringSync();
        
        final importRegex = RegExp(r"import\s+['""]([^'""]+)['""];");
        content = content.replaceAllMapped(importRegex, (match) {
          final importString = match.group(1)!;
          if (importString.startsWith('package:')) {
            // Already a package import, but check if we need to convert expense_tracker/src path
            if (importString.startsWith('package:expense_tracker/src/')) {
               final fileName = importString.split('/').last;
               if (fileNameToNewPackagePath.containsKey(fileName)) {
                 return "import '${fileNameToNewPackagePath[fileName]}';";
               }
            }
            return match.group(0)!; // keep as is
          }

          final parts = importString.split('/');
          final importedFileName = parts.last;
          if (fileNameToNewPackagePath.containsKey(importedFileName)) {
            return "import '${fileNameToNewPackagePath[importedFileName]}';";
          }
          
          if (importString == 'firebase_options.dart') return "import 'package:expense_tracker/firebase_options.dart';";

          return match.group(0)!;
        });

        entity.writeAsStringSync(content);
      }
    }
  }

  print('Fixing imports across lib/ and test/ ...');
  processDir(Directory('lib'));
  processDir(Directory('test'));
  
  // Clean up lib/src
  final srcDir = Directory('lib/src');
  if (srcDir.existsSync()) {
    try {
      srcDir.deleteSync(recursive: true);
      print('Deleted lib/src successfully.');
    } catch (_) {}
  }
  
  print('Refactoring Complete!');
}
