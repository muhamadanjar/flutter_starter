# Clean Architecture Guide

Enterprise Flutter App uses **Clean Architecture** with three distinct layers: Domain, Data, and Presentation. This ensures separation of concerns, testability, and independence from frameworks.

## Architecture Layers

```
┌─────────────────────────────────────────┐
│        PRESENTATION LAYER               │
│  (Pages, Widgets, UI Logic, Riverpod)   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│        APPLICATION/DOMAIN LAYER         │
│  (Entities, Repositories, UseCases)     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         DATA LAYER                      │
│  (Models, DataSources, Repository Impl) │
└─────────────────────────────────────────┘
```

### 1. Domain Layer (`domain/`)

**Core business logic. Framework-independent.**

```
domain/
├── entities/          # Pure data classes (models for business logic)
├── repositories/      # Abstract interfaces (contracts)
└── usecases/         # Business rules (application logic)
```

**Responsibilities:**
- Define `Entity` classes (immutable, represent core business objects)
- Define `Repository` abstract classes (contracts for data access)
- Implement `UseCase` classes (orchestrate domain logic)
- Handle `Failure` types (domain-level errors)

**Example: User Entity**

```dart
// lib/features/dashboard/domain/entities/user_entity.dart

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String email,
    required DateTime createdAt,
  }) = _UserEntity;
}
```

**Example: Repository Interface**

```dart
// lib/features/dashboard/domain/repositories/dashboard_repository.dart

abstract class DashboardRepository {
  Future<Either<Failure, DashboardEntity>> getDashboard();
  Future<Either<Failure, void>> updateUserSettings(UserEntity user);
}
```

**Example: UseCase**

```dart
// lib/features/dashboard/domain/usecases/get_dashboard_usecase.dart

class GetDashboardUseCase {
  final DashboardRepository repository;

  GetDashboardUseCase(this.repository);

  Future<Either<Failure, DashboardEntity>> call() async {
    return repository.getDashboard();
  }
}
```

**Key Points:**
- ❌ No imports from `data/`, `presentation/`, or Flutter
- ✅ Pure Dart, testable without framework
- ✅ Uses `Either<Failure, T>` for error handling
- ✅ Entities are immutable (`@freezed`)

---

### 2. Data Layer (`data/`)

**Fetches and transforms data. Framework-aware.**

```
data/
├── datasources/      # Local (Hive) & remote (Dio) data sources
├── models/          # JSON-serializable copies of entities
└── repositories/    # Concrete repository implementations
```

**Responsibilities:**
- Define `Model` classes (extend Entity, add JSON serialization)
- Implement `DataSource` classes (abstract interfaces for data access)
- Implement concrete `Repository` classes (use datasources, error handling)

**Example: Model (adds JSON serialization)**

```dart
// lib/features/dashboard/data/models/user_model.dart

@freezed
class UserModel extends UserEntity with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    required DateTime createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

**Example: DataSource (abstract)**

```dart
// lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart

abstract class DashboardRemoteDataSource {
  Future<UserModel> getUser(String id);
  Future<void> updateUser(UserModel user);
}

// Implementation
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSourceImpl(this.dio);

  @override
  Future<UserModel> getUser(String id) async {
    try {
      final response = await dio.get('/users/$id');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Unknown error');
    }
  }
}
```

**Example: Local DataSource (Hive)**

```dart
// lib/features/dashboard/data/datasources/dashboard_local_datasource.dart

abstract class DashboardLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  @override
  Future<UserModel?> getCachedUser() async {
    final box = Hive.box(AppConstants.userBox);
    final json = box.get('user');
    return json != null ? UserModel.fromJson(json) : null;
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    final box = Hive.box(AppConstants.userBox);
    await box.put('user', user.toJson());
  }
}
```

**Example: Concrete Repository (combines datasources)**

```dart
// lib/features/dashboard/data/repositories/dashboard_repository_impl.dart

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserModel>> getUser(String id) async {
    if (!await networkInfo.isConnected) {
      try {
        final cached = await localDataSource.getCachedUser();
        return cached != null ? Right(cached) : Left(CacheFailure());
      } catch (e) {
        return Left(CacheFailure());
      }
    }

    try {
      final user = await remoteDataSource.getUser(id);
      await localDataSource.cacheUser(user);  // Cache for offline
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

**Key Points:**
- ✅ Imports from `domain/`, uses `Either`, handles errors
- ✅ Models extend entities (inherit properties)
- ✅ DataSources abstract (swappable implementations)
- ✅ Repository orchestrates datasources (logic)
- ✅ Catches framework exceptions, converts to domain `Failure`

---

### 3. Presentation Layer (`presentation/`)

**UI and navigation. Flutter/Riverpod-aware.**

```
presentation/
├── pages/      # Full screens
├── widgets/    # Reusable UI components
└── providers/  # Riverpod state management
```

**Responsibilities:**
- Display data via `AsyncValue.when()`
- Handle user interactions → trigger use cases
- Manage local UI state (if needed)
- Navigate between screens

**Example: Provider (combines UseCase + Riverpod)**

```dart
// lib/features/dashboard/presentation/providers/user_provider.dart

@riverpod
Future<UserEntity> userProvider(UserProviderRef ref, String userId) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getUser(userId);

  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (user) => user,
  );
}

// Dependency injection
@riverpod
DashboardRepository dashboardRepositoryProvider(DashboardRepositoryProviderRef ref) {
  final remoteDataSource = ref.watch(dashboardRemoteDataSourceProvider);
  final localDataSource = ref.watch(dashboardLocalDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);

  return DashboardRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
  );
}
```

**Example: Page Widget**

```dart
// lib/features/dashboard/presentation/pages/dashboard_page.dart

class DashboardPage extends ConsumerWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider('123'));

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: userAsync.when(
        data: (user) => _buildContent(user),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(UserEntity user) {
    return ListView(
      children: [
        UserCard(user: user),
        // More widgets
      ],
    );
  }
}
```

**Example: Reusable Widget**

```dart
// lib/features/dashboard/presentation/widgets/user_card.dart

class UserCard extends StatelessWidget {
  final UserEntity user;

  const UserCard({required this.user, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(user.name, style: Theme.of(context).textTheme.titleLarge),
            Text(user.email),
          ],
        ),
      ),
    );
  }
}
```

**Key Points:**
- ✅ Uses Riverpod providers (dependency injection)
- ✅ Handles `AsyncValue` (data, loading, error)
- ✅ Minimal business logic (keep in domain)
- ✅ UI-specific state only (local widget state)

---

## Data Flow

```
User Interaction (Page)
        ↓
Riverpod Provider watches Repository
        ↓
UseCase executes (domain logic)
        ↓
Repository.getUser() called
        ↓
Check NetworkInfo → Remote or Local DataSource
        ↓
RemoteDataSource calls Dio API / LocalDataSource calls Hive
        ↓
Model deserialized from JSON / Hive box
        ↓
Map Model → Entity (domain layer)
        ↓
Return Either<Failure, Entity>
        ↓
UseCase unwraps result
        ↓
Provider notifies listeners (UI)
        ↓
Widget rebuilds with data via AsyncValue.when()
```

---

## Error Handling

### Domain Layer (Failures)

```dart
// lib/core/errors/failures.dart

abstract class Failure {}

class ServerFailure extends Failure {
  final String message;
  ServerFailure(this.message);
}

class CacheFailure extends Failure {}

class NetworkFailure extends Failure {}
```

### Data Layer (Exceptions)

```dart
// lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {}

// Catch framework exceptions, convert to domain Failure
try {
  final response = await dio.get('/users/$id');
  return UserModel.fromJson(response.data);
} on DioException catch (e) {
  throw ServerException(e.message ?? 'Unknown error');
}
```

### Presentation Layer (AsyncValue)

```dart
// Automatic error handling in Riverpod
userAsync.when(
  data: (user) => Text(user.name),
  loading: () => Loader(),
  error: (err, st) => ErrorWidget(error: err),
)
```

---

## Testing

Clean Architecture makes testing simple:

### Unit Test Domain (UseCase)

```dart
void main() {
  group('GetUserUseCase', () {
    late GetUserUseCase useCase;
    late MockDashboardRepository mockRepository;

    setUp(() {
      mockRepository = MockDashboardRepository();
      useCase = GetUserUseCase(mockRepository);
    });

    test('should return UserEntity when repository call succeeds', () async {
      // Arrange
      final user = UserEntity(id: '1', name: 'John', email: 'john@test.com', createdAt: DateTime.now());
      when(mockRepository.getUser('1')).thenAnswer((_) async => Right(user));

      // Act
      final result = await useCase('1');

      // Assert
      expect(result, Right(user));
      verify(mockRepository.getUser('1')).called(1);
    });
  });
}
```

### Unit Test Data (Repository)

```dart
void main() {
  group('DashboardRepositoryImpl', () {
    late DashboardRepositoryImpl repository;
    late MockRemoteDataSource mockRemote;
    late MockLocalDataSource mockLocal;
    late MockNetworkInfo mockNetworkInfo;

    setUp(() {
      mockRemote = MockRemoteDataSource();
      mockLocal = MockLocalDataSource();
      mockNetworkInfo = MockNetworkInfo();
      repository = DashboardRepositoryImpl(
        remoteDataSource: mockRemote,
        localDataSource: mockLocal,
        networkInfo: mockNetworkInfo,
      );
    });

    test('should return UserModel from remote when online', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      final userModel = UserModel(...);
      when(mockRemote.getUser('1')).thenAnswer((_) async => userModel);

      // Act
      final result = await repository.getUser('1');

      // Assert
      expect(result, Right(userModel));
      verify(mockLocal.cacheUser(userModel)).called(1);
    });
  });
}
```

### Widget Test (Presentation)

```dart
void main() {
  testWidgets('DashboardPage shows user data', (WidgetTester tester) async {
    final mockUser = UserEntity(id: '1', name: 'John', email: 'john@test.com', createdAt: DateTime.now());
    
    await tester.pumpWidget(
      ProviderContainer(
        overrides: [
          userProvider.overrideWithValue(AsyncValue.data(mockUser)),
        ],
        child: MaterialApp(home: DashboardPage()),
      ),
    );

    expect(find.text('John'), findsOneWidget);
    expect(find.text('john@test.com'), findsOneWidget);
  });
}
```

---

## Key Principles

| Principle | Rule |
|-----------|------|
| **Dependency Rule** | Inner layers (domain) never depend on outer layers (data, presentation) |
| **Single Responsibility** | Each class has one reason to change |
| **Open/Closed** | Open for extension, closed for modification |
| **Liskov Substitution** | Subtypes must be substitutable for base types |
| **Interface Segregation** | Clients depend on specific, small interfaces |
| **Dependency Inversion** | Depend on abstractions, not concretions |

---

## Checklist: Adding New Feature

- [ ] **Domain Layer**
  - [ ] Create `domain/entities/[feature]_entity.dart` (pure business model)
  - [ ] Create `domain/repositories/[feature]_repository.dart` (abstract interface)
  - [ ] Create `domain/usecases/[usecase]_usecase.dart` (business logic)

- [ ] **Data Layer**
  - [ ] Create `data/models/[feature]_model.dart` (extends entity, JSON serializable)
  - [ ] Create `data/datasources/[feature]_remote_datasource.dart` (API calls via Dio)
  - [ ] Create `data/datasources/[feature]_local_datasource.dart` (cache via Hive)
  - [ ] Create `data/repositories/[feature]_repository_impl.dart` (combines datasources)

- [ ] **Presentation Layer**
  - [ ] Create `presentation/providers/[feature]_provider.dart` (Riverpod + UseCase)
  - [ ] Create `presentation/pages/[feature]_page.dart` (main screen)
  - [ ] Create `presentation/widgets/[widget]_widget.dart` (reusable components)
  - [ ] Add route in `app/router/app_router.dart`

- [ ] **Testing**
  - [ ] Unit test domain layer (usecase logic)
  - [ ] Unit test data layer (repository, datasources)
  - [ ] Widget test presentation layer (UI renders correctly)

---

## References

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Riverpod Documentation](https://riverpod.dev/)
- [Go Router Documentation](https://pub.dev/packages/go_router)
- [Hive Documentation](https://docs.hivedb.dev/)
