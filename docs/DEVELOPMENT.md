# Development Guide - GoalMoney Flutter App

Panduan pengembangan untuk developer yang ingin berkontribusi atau mengembangkan GoalMoney App.

---

## 📋 Daftar Isi

1. [Setup Development Environment](#1-setup-development-environment)
2. [Architecture Overview](#2-architecture-overview)
3. [Coding Standards](#3-coding-standards)
4. [Adding New Features](#4-adding-new-features)
5. [State Management](#5-state-management)
6. [API Integration](#6-api-integration)
7. [Testing](#7-testing)
8. [Building & Releasing](#8-building--releasing)

---

## 1. Setup Development Environment

### Prerequisites

```bash
# Cek Flutter version
flutter --version

# Harus Flutter 3.10.0+
```

### IDE Setup

#### VS Code (Recommended)

Extensions wajib:

- Flutter
- Dart
- Flutter Widget Snippets
- Error Lens

Settings (`settings.json`):

```json
{
  "editor.formatOnSave": true,
  "dart.lineLength": 80,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code"
  }
}
```

#### Android Studio

Plugins:

- Flutter
- Dart
- Flutter Enhancement Suite

### Clone & Run

```bash
# Clone
git clone <repository-url>
cd GoalMoney-app

# Install dependencies
flutter pub get

# Run
flutter run
```

---

## 2. Architecture Overview

### Project Structure

```
lib/
├── main.dart              # Entry point
├── core/                  # Core utilities
├── models/                # Data models
├── providers/             # State management
├── screens/               # UI screens
└── widgets/               # Reusable widgets
```

### Layer Diagram

```
┌─────────────────────────────────────┐
│           UI Layer                  │
│         (Screens, Widgets)          │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│        State Management             │
│          (Providers)                │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│         Data Layer                  │
│      (ApiClient, Models)            │
└─────────────────────────────────────┘
```

### Data Flow

1. User berinteraksi dengan UI
2. UI memanggil method di Provider
3. Provider memanggil API via ApiClient
4. Response di-parse ke Model
5. Provider update state
6. UI rebuild otomatis

---

## 3. Coding Standards

### Naming Conventions

| Type      | Convention      | Example                 |
| --------- | --------------- | ----------------------- |
| Files     | snake_case      | `goal_list_screen.dart` |
| Classes   | PascalCase      | `GoalListScreen`        |
| Variables | camelCase       | `goalProvider`          |
| Constants | SCREAMING_SNAKE | `API_BASE_URL`          |
| Private   | \_prefix        | `_isLoading`            |

### File Structure per Screen

```dart
// 1. Imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 2. Class declaration
class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

// 3. State class
class _ExampleScreenState extends State<ExampleScreen> {
  // 3.1 Variables
  bool _isLoading = false;

  // 3.2 Lifecycle methods
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 3.3 Private methods
  Future<void> _loadData() async {
    // ...
  }

  // 3.4 Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ...
    );
  }

  // 3.5 Widget builder methods
  Widget _buildContent() {
    // ...
  }
}
```

### Use const Everywhere

```dart
// ✅ Good
const SizedBox(height: 16),
const Text('Hello'),
const EdgeInsets.all(16),

// ❌ Bad
SizedBox(height: 16),
Text('Hello'),
EdgeInsets.all(16),
```

### Prefer final

```dart
// ✅ Good
final user = context.watch<AuthProvider>().user;

// ❌ Bad
var user = context.watch<AuthProvider>().user;
```

---

## 4. Adding New Features

### Step-by-Step Guide

#### Step 1: Create Model

```dart
// lib/models/example.dart
class Example {
  final int id;
  final String name;

  Example({
    required this.id,
    required this.name,
  });

  factory Example.fromJson(Map<String, dynamic> json) {
    return Example(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}
```

#### Step 2: Create Provider

```dart
// lib/providers/example_provider.dart
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/example.dart';

class ExampleProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<Example> _items = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Example> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Methods
  Future<void> fetchItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.dio.get('/examples');

      if (response.statusCode == 200 && response.data['success'] == true) {
        _items = (response.data['data'] as List)
            .map((e) => Example.fromJson(e))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

#### Step 3: Register Provider

```dart
// lib/main.dart
MultiProvider(
  providers: [
    // ... existing
    ChangeNotifierProvider(create: (_) => ExampleProvider()),
  ],
  child: const MyApp(),
)
```

#### Step 4: Create Screen

```dart
// lib/screens/example/example_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/example_provider.dart';

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ExampleProvider>().fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example')),
      body: Consumer<ExampleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          return ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return ListTile(
                title: Text(item.name),
              );
            },
          );
        },
      ),
    );
  }
}
```

#### Step 5: Add Navigation

```dart
// Di screen yang ingin navigate
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const ExampleScreen()),
);
```

---

## 5. State Management

### Provider Pattern

#### Accessing Provider

```dart
// Read (one-time access, untuk actions)
context.read<GoalProvider>().fetchGoals();

// Watch (rebuild on changes, untuk UI)
final goals = context.watch<GoalProvider>().goals;

// Select (rebuild on specific field changes)
final isLoading = context.select<GoalProvider, bool>((p) => p.isLoading);
```

#### Consumer vs context.watch

```dart
// Consumer - untuk optimized rebuilds
Consumer<GoalProvider>(
  builder: (context, provider, child) {
    return Text(provider.goals.length.toString());
  },
)

// context.watch - simpler syntax
Text(context.watch<GoalProvider>().goals.length.toString())
```

#### Notify Listeners

```dart
class MyProvider extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners(); // Trigger rebuild
  }
}
```

---

## 6. API Integration

### ApiClient Setup

```dart
// lib/core/api_client.dart
class ApiClient {
  static const String baseUrl = 'http://localhost:8000';

  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }
}
```

### Making Requests

```dart
// GET
final response = await _api.dio.get('/goals');

// POST dengan body
final response = await _api.dio.post('/goals/store', data: {
  'name': 'Goal Name',
  'target_amount': 1000000,
});

// PUT
await _api.dio.put('/goals/update?id=$id', data: {...});

// DELETE
await _api.dio.delete('/goals/delete?id=$id');
```

### Error Handling

```dart
try {
  final response = await _api.dio.get('/endpoint');
  // Handle success
} on DioException catch (e) {
  if (e.response != null) {
    // Server error with response
    final message = e.response?.data['message'] ?? 'Unknown error';
    _error = message;
  } else {
    // Network error
    _error = 'Network error: ${e.message}';
  }
} catch (e) {
  _error = 'Unexpected error: $e';
}
```

---

## 7. Testing

### Unit Tests

```dart
// test/providers/goal_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:goalmoney_fe/providers/goal_provider.dart';

void main() {
  group('GoalProvider', () {
    late GoalProvider provider;

    setUp(() {
      provider = GoalProvider();
    });

    test('initial state is empty', () {
      expect(provider.goals, isEmpty);
      expect(provider.isLoading, isFalse);
    });
  });
}
```

### Widget Tests

```dart
// test/screens/dashboard_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Dashboard shows summary card', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DashboardScreen(),
    ));

    expect(find.text('Total Tabungan'), findsOneWidget);
  });
}
```

### Run Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/providers/goal_provider_test.dart

# With coverage
flutter test --coverage
```

---

## 8. Building & Releasing

### Development Build

```bash
# Debug APK
flutter build apk --debug

# Debug IPA
flutter build ios --debug
```

### Release Build

```bash
# Release APK
flutter build apk --release

# AAB for Play Store
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Build Configuration

File `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        applicationId "com.yourcompany.goalmoney"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

### Signing

#### Android

1. Create keystore:

```bash
keytool -genkey -v -keystore goalmoney.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias goalmoney
```

2. Create `android/key.properties`:

```properties
storePassword=yourpassword
keyPassword=yourpassword
keyAlias=goalmoney
storeFile=../goalmoney.jks
```

3. Update `build.gradle` untuk signing

#### iOS

Setup di Xcode:

1. Buka `ios/Runner.xcworkspace`
2. Select Runner target
3. Signing & Capabilities
4. Pilih Team dan Bundle Identifier

---

## 🔧 Useful Commands

```bash
# Clean project
flutter clean

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Format code
dart format .

# Run with hot reload
flutter run

# Build APK
flutter build apk --release

# Generate launcher icons
flutter pub run flutter_launcher_icons
```

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [Dio HTTP Client](https://pub.dev/packages/dio)
- [Material Design 3](https://m3.material.io/)

---

**© 2024 GoalMoney Development Team**
