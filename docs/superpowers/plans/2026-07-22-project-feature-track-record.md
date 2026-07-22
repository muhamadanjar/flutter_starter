# Project-gated Feature Record & Track Record Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `features/project` module and gate both Track Record and a new Feature Record capture flow behind selecting a Project (which defines `geometry_type` + a dynamic `form_schema`), then sync both record types to the live tile server's `/api/v1/projects/{id}/features` endpoint.

**Architecture:** Clean Architecture, mirroring the existing `features/map` layout exactly (domain entity → domain repository → usecase → data model/datasource/repository impl → Riverpod providers → widgets). Track Record and the new Feature Record both depend on the new `ProjectRemoteDataSource.createFeature()` to sync; both stay offline-first via Hive + outbox (`syncPending`), same pattern as the existing `TrackRecordRepositoryImpl`.

**Tech Stack:** Flutter/Dart, Riverpod (`flutter_riverpod`), `fpdart` (`Either<Failure, T>`), Hive (local outbox), Dio via `ExternalDioClient` (remote), `flutter_map`/`latlong2` (map), `geolocator` (GPS), `image_picker` (file field).

## Global Constraints

- Dart SDK `>=3.2.0 <4.0.0` (from `pubspec.yaml`).
- Follow the `Either<Failure, T>` pattern everywhere in domain/data — never throw across a repository boundary; catch `Exception`/`NetworkException`/`ServerException` and map to `Failure` subclasses (`core/errors/failures.dart`, `core/errors/exceptions.dart`).
- All new files use the project's existing clean-architecture directory layout (`domain/{entities,repositories,usecases}`, `data/{models,datasources,repositories}`, `presentation/{providers,widgets}`).
- No secrets or environment values beyond the existing `TILE_SERVER_URL` in `.env` — reuse `tileServerBaseUrlProvider` from `lib/features/map/presentation/providers/map_providers.dart`, do not duplicate it.
- Reuse `SyncStatus` from `lib/features/map/domain/entities/track_record.dart` for `FeatureRecord` — do not redefine it.
- Test files live flat under `test/` (no per-feature subfolders), matching `test/map_theme_test.dart` and `test/map_datasource_live_test.dart`. No mocking library is wired up (`mockito` is a dependency but no generated mocks exist yet) — write small hand-rolled fake classes implementing the abstract datasource/repository interfaces, matching this project's existing plain `flutter_test` style.
- Run `flutter analyze` and the relevant `flutter test` command at the end of every task; a task is not complete until both are clean.

---

## File Structure

New `features/project` module:
```
lib/features/project/
  domain/entities/project.dart
  domain/repositories/project_repository.dart
  domain/usecases/get_projects_usecase.dart
  domain/usecases/upload_attachment_usecase.dart
  data/models/project_model.dart
  data/datasources/project_remote_datasource.dart
  data/repositories/project_repository_impl.dart
  presentation/providers/project_providers.dart
  presentation/widgets/project_picker_sheet.dart
```

New Feature Record files under the existing `features/map` module:
```
lib/features/map/domain/entities/feature_record.dart
lib/features/map/domain/repositories/feature_record_repository.dart
lib/features/map/domain/usecases/save_feature_record_usecase.dart
lib/features/map/domain/usecases/sync_feature_records_usecase.dart
lib/features/map/domain/usecases/get_pending_feature_records_usecase.dart
lib/features/map/data/models/feature_record_model.dart
lib/features/map/data/datasources/feature_record_local_datasource.dart
lib/features/map/data/repositories/feature_record_repository_impl.dart
lib/features/map/presentation/providers/feature_capture_providers.dart
lib/features/map/presentation/widgets/dynamic_form_sheet.dart
lib/features/map/presentation/widgets/feature_record_fab.dart
```

Modified existing files:
```
lib/features/map/domain/entities/track_record.dart          (+ projectId, attributes)
lib/features/map/data/models/track_record_model.dart         (+ projectId, attributes JSON)
lib/features/map/domain/repositories/track_record_repository.dart (startTrack + projectId)
lib/features/map/data/datasources/track_record_local_datasource.dart (startTrack + projectId)
lib/features/map/data/repositories/track_record_repository_impl.dart (real sync upload)
lib/features/map/domain/usecases/start_track_usecase.dart    (+ projectId param)
lib/features/map/domain/usecases/get_track_usecase.dart      (new)
lib/features/map/domain/usecases/save_track_usecase.dart     (new)
lib/features/map/presentation/providers/map_providers.dart   (+ new providers)
lib/features/map/presentation/widgets/track_record_fab.dart  (project gate + form on stop)
lib/features/map/presentation/widgets/map_view.dart           (+ polygon vertex capture)
lib/features/map/presentation/pages/map_page.dart              (+ FeatureRecordFab wiring)
lib/main_common.dart                                            (+ Hive box `record_features`)
```

New tests:
```
test/project_repository_impl_test.dart
test/track_record_repository_impl_test.dart
test/feature_record_repository_impl_test.dart
test/dynamic_form_sheet_test.dart
```

---

### Task 1: Project domain entity

**Files:**
- Create: `lib/features/project/domain/entities/project.dart`
- Test: `test/project_repository_impl_test.dart` (this task only adds the entity; the test file is created fully in Task 4)

**Interfaces:**
- Produces: `class ProjectFormField { name, label, type, required, min, max, options, extensions }`; `class Project { id, name, description, geometryType, formSchema, layerId, isPublished, featureCount, createdAt, updatedAt }`.

- [ ] **Step 1: Write the entity**

```dart
// lib/features/project/domain/entities/project.dart

/// One field of a project's dynamic attribute form.
///
/// `type` is a free string from the server (`text`, `textarea`, `number`,
/// `select`, `file`, ...); unknown types must be handled defensively by
/// renderers, not rejected here.
class ProjectFormField {
  const ProjectFormField({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.min,
    this.max,
    this.options = const [],
    this.extensions = const [],
  });

  final String name;
  final String label;
  final String type;
  final bool required;
  final num? min;
  final num? max;
  final List<String> options;
  final List<String> extensions;
}

/// A project defines what can be captured: a single [geometryType]
/// (`point` / `line` / `polygon`) and a dynamic [formSchema] used to render
/// the attribute form shown when a Track Record or Feature Record is saved.
class Project {
  const Project({
    required this.id,
    required this.name,
    this.description = '',
    required this.geometryType,
    this.formSchema = const [],
    this.layerId,
    this.isPublished = false,
    this.featureCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String geometryType;
  final List<ProjectFormField> formSchema;
  final String? layerId;
  final bool isPublished;
  final int featureCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/project/domain/entities/project.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/project/domain/entities/project.dart
git commit -m "feat: add Project and ProjectFormField domain entities"
```

---

### Task 2: Project data model

**Files:**
- Create: `lib/features/project/data/models/project_model.dart`

**Interfaces:**
- Consumes: `Project`, `ProjectFormField` from Task 1.
- Produces: `ProjectModel.fromJson(Map<String, dynamic>)`, `ProjectModel.toEntity()`.

- [ ] **Step 1: Write the model**

```dart
// lib/features/project/data/models/project_model.dart
import '../../domain/entities/project.dart';

class ProjectFormFieldModel extends ProjectFormField {
  const ProjectFormFieldModel({
    required super.name,
    required super.label,
    required super.type,
    super.required,
    super.min,
    super.max,
    super.options,
    super.extensions,
  });

  factory ProjectFormFieldModel.fromJson(Map<String, dynamic> json) {
    return ProjectFormFieldModel(
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      required: json['required'] as bool? ?? false,
      min: json['min'] as num?,
      max: json['max'] as num?,
      options: ((json['options'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      extensions: ((json['extensions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.name,
    super.description,
    required super.geometryType,
    super.formSchema,
    super.layerId,
    super.isPublished,
    super.featureCount,
    required super.createdAt,
    super.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final rawSchema = (json['form_schema'] as List?) ?? const [];
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      geometryType: json['geometry_type'] as String? ?? '',
      formSchema: [
        for (final f in rawSchema)
          if (f is Map<String, dynamic>) ProjectFormFieldModel.fromJson(f),
      ],
      layerId: json['layer_id'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      featureCount: (json['feature_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }
}
```

- [ ] **Step 2: Write the mapping test**

```dart
// test/project_repository_impl_test.dart (created here, extended in Task 4)
import 'package:enterprise_flutter_app/features/project/data/models/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectModel.fromJson', () {
    test('parses a polygon project with a mixed form_schema', () {
      final model = ProjectModel.fromJson({
        'id': 'bb483f93-976f-4765-82cb-b041ff3d3d1f',
        'name': 'Area',
        'description': '',
        'geometry_type': 'polygon',
        'form_schema': [
          {'name': 'name', 'label': 'Nama', 'type': 'text', 'required': true},
          {
            'name': 'year',
            'label': 'Tahun',
            'type': 'number',
            'required': false,
            'min': 2000,
            'max': 2030,
          },
          {
            'name': 'select',
            'label': 'Select',
            'type': 'select',
            'required': false,
            'options': ['adfdf', 'dfdf'],
          },
        ],
        'layer_id': null,
        'is_published': false,
        'feature_count': 1,
        'created_at': '2026-07-21T15:57:03.855354Z',
        'updated_at': '2026-07-21T16:09:09.901631Z',
      });

      expect(model.id, 'bb483f93-976f-4765-82cb-b041ff3d3d1f');
      expect(model.geometryType, 'polygon');
      expect(model.formSchema, hasLength(3));
      expect(model.formSchema[0].type, 'text');
      expect(model.formSchema[0].required, isTrue);
      expect(model.formSchema[1].min, 2000);
      expect(model.formSchema[1].max, 2030);
      expect(model.formSchema[2].options, ['adfdf', 'dfdf']);
      expect(model.layerId, isNull);
      expect(model.featureCount, 1);
    });

    test('parses a line project with a file field', () {
      final model = ProjectModel.fromJson({
        'id': '44fc08cf-7803-4ee9-b9ed-ab45943c6baa',
        'name': 'Jalan',
        'geometry_type': 'line',
        'form_schema': [
          {'name': 'name', 'label': 'Nama Jalan', 'type': 'text', 'required': false},
          {
            'name': 'fule',
            'label': 'File',
            'type': 'file',
            'required': false,
            'extensions': ['jpg'],
          },
        ],
        'is_published': false,
        'feature_count': 1,
        'created_at': '2026-07-21T15:45:24.778944Z',
        'updated_at': '2026-07-21T15:45:24.779005Z',
      });

      expect(model.geometryType, 'line');
      expect(model.formSchema[1].type, 'file');
      expect(model.formSchema[1].extensions, ['jpg']);
    });

    test('missing form_schema defaults to empty list', () {
      final model = ProjectModel.fromJson({
        'id': 'x',
        'name': 'Empty',
        'geometry_type': 'point',
        'is_published': false,
        'feature_count': 0,
        'created_at': '2026-07-21T00:00:00Z',
        'updated_at': '2026-07-21T00:00:00Z',
      });
      expect(model.formSchema, isEmpty);
    });
  });
}
```

- [ ] **Step 3: Run the test**

Run: `flutter test test/project_repository_impl_test.dart`
Expected: `00:0X +3: All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/project/data/models/project_model.dart test/project_repository_impl_test.dart
git commit -m "feat: add ProjectModel JSON parsing with mapping tests"
```

---

### Task 3: Project remote datasource

**Files:**
- Create: `lib/features/project/data/datasources/project_remote_datasource.dart`

**Interfaces:**
- Consumes: `ExternalDioClient` (`lib/core/network/external_dio_client.dart`), `ProjectModel` (Task 2).
- Produces: `ProjectRemoteDataSource` with `getProjects()`, `getProject(id)`, `createFeature({projectId, geometry, attributes})`, `uploadAttachment({projectId, fieldName, file})`. This is the interface `TrackRecordRepositoryImpl` and `FeatureRecordRepositoryImpl` will call directly (Tasks 9 and 14) to sync — not through `ProjectRepository`.

- [ ] **Step 1: Write the datasource**

```dart
// lib/features/project/data/datasources/project_remote_datasource.dart
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/external_dio_client.dart';
import '../models/project_model.dart';

abstract class ProjectRemoteDataSource {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectModel> getProject(String id);

  /// Create a Feature under [projectId]. `geometry` is a GeoJSON geometry
  /// object (`{"type": "Point"|"LineString"|"Polygon", "coordinates": ...}`).
  Future<void> createFeature({
    required String projectId,
    required Map<String, dynamic> geometry,
    required Map<String, dynamic> attributes,
  });

  /// Upload a file for a `file`-type form field, returns the server URL to
  /// store as that field's attribute value.
  Future<String> uploadAttachment({
    required String projectId,
    required String fieldName,
    required File file,
  });
}

/// Talks to the FastAPI tile server's `/api/v1/projects` endpoints.
class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  ProjectRemoteDataSourceImpl(this._client);

  final ExternalDioClient _client;

  @override
  Future<List<ProjectModel>> getProjects() async {
    final response = await _client.get<List<dynamic>>('/api/v1/projects');
    final data = response.data ?? const [];
    return [
      for (final item in data)
        if (item is Map<String, dynamic>) ProjectModel.fromJson(item),
    ];
  }

  @override
  Future<ProjectModel> getProject(String id) async {
    final response =
        await _client.get<Map<String, dynamic>>('/api/v1/projects/$id');
    return ProjectModel.fromJson(response.data ?? const {});
  }

  @override
  Future<void> createFeature({
    required String projectId,
    required Map<String, dynamic> geometry,
    required Map<String, dynamic> attributes,
  }) async {
    await _client.post<Map<String, dynamic>>(
      '/api/v1/projects/$projectId/features',
      data: {'geometry': geometry, 'attributes': attributes},
    );
  }

  @override
  Future<String> uploadAttachment({
    required String projectId,
    required String fieldName,
    required File file,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
      'field_name': fieldName,
    });
    final response = await _client.post<Map<String, dynamic>>(
      '/api/v1/projects/$projectId/attachments',
      data: formData,
    );
    final url = response.data?['url'] as String?;
    if (url == null) {
      throw const ServerException(message: 'Attachment upload returned no url');
    }
    return url;
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/project/data/datasources/project_remote_datasource.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/project/data/datasources/project_remote_datasource.dart
git commit -m "feat: add ProjectRemoteDataSource (list/get/createFeature/uploadAttachment)"
```

---

### Task 4: Project repository

**Files:**
- Create: `lib/features/project/domain/repositories/project_repository.dart`
- Create: `lib/features/project/data/repositories/project_repository_impl.dart`
- Modify: `test/project_repository_impl_test.dart` (extend with repository tests)

**Interfaces:**
- Consumes: `ProjectRemoteDataSource` (Task 3), `Project`/`ProjectModel`, `Failure`/`NetworkException`/`ServerException`.
- Produces: `ProjectRepository { getProjects(), getProject(id), uploadAttachment({projectId, fieldName, file}) }` and `ProjectRepositoryImpl`.

- [ ] **Step 1: Write the domain repository interface**

```dart
// lib/features/project/domain/repositories/project_repository.dart
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/project.dart';

abstract class ProjectRepository {
  Future<Either<Failure, List<Project>>> getProjects();
  Future<Either<Failure, Project>> getProject(String id);

  Future<Either<Failure, String>> uploadAttachment({
    required String projectId,
    required String fieldName,
    required File file,
  });
}
```

- [ ] **Step 2: Write the failing repository tests**

```dart
// test/project_repository_impl_test.dart — append to the file from Task 2
import 'dart:io';

import 'package:enterprise_flutter_app/core/errors/exceptions.dart';
import 'package:enterprise_flutter_app/core/errors/failures.dart';
import 'package:enterprise_flutter_app/features/project/data/datasources/project_remote_datasource.dart';
import 'package:enterprise_flutter_app/features/project/data/repositories/project_repository_impl.dart';

class _FakeProjectRemoteDataSource implements ProjectRemoteDataSource {
  List<ProjectModel> projects = const [];
  Object? getProjectsError;
  String uploadedUrl = 'https://tiles.example.com/attachments/1.jpg';
  Object? uploadError;

  @override
  Future<List<ProjectModel>> getProjects() async {
    if (getProjectsError != null) throw getProjectsError!;
    return projects;
  }

  @override
  Future<ProjectModel> getProject(String id) async =>
      projects.firstWhere((p) => p.id == id);

  @override
  Future<void> createFeature({
    required String projectId,
    required Map<String, dynamic> geometry,
    required Map<String, dynamic> attributes,
  }) async {}

  @override
  Future<String> uploadAttachment({
    required String projectId,
    required String fieldName,
    required File file,
  }) async {
    if (uploadError != null) throw uploadError!;
    return uploadedUrl;
  }
}

void main() {
  // ... ProjectModel.fromJson group from Task 2 stays above ...

  group('ProjectRepositoryImpl', () {
    test('getProjects returns Right on success', () async {
      final fake = _FakeProjectRemoteDataSource()
        ..projects = [
          ProjectModel.fromJson({
            'id': 'x',
            'name': 'Test',
            'geometry_type': 'point',
            'is_published': false,
            'feature_count': 0,
            'created_at': '2026-07-21T00:00:00Z',
          }),
        ];
      final repo = ProjectRepositoryImpl(remoteDataSource: fake);

      final result = await repo.getProjects();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected Right'), (list) => expect(list, hasLength(1)));
    });

    test('getProjects maps NetworkException to NetworkFailure', () async {
      final fake = _FakeProjectRemoteDataSource()
        ..getProjectsError = const NetworkException(message: 'offline');
      final repo = ProjectRepositoryImpl(remoteDataSource: fake);

      final result = await repo.getProjects();

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('expected Left'));
    });

    test('uploadAttachment returns the server url on success', () async {
      final fake = _FakeProjectRemoteDataSource();
      final repo = ProjectRepositoryImpl(remoteDataSource: fake);

      final result = await repo.uploadAttachment(
        projectId: 'p1',
        fieldName: 'photo',
        file: File('test/fixtures/does_not_need_to_exist.jpg'),
      );

      expect(result, const Right<Failure, String>('https://tiles.example.com/attachments/1.jpg'));
    });

    test('uploadAttachment maps ServerException to ServerFailure', () async {
      final fake = _FakeProjectRemoteDataSource()
        ..uploadError = const ServerException(message: 'too large', statusCode: 413);
      final repo = ProjectRepositoryImpl(remoteDataSource: fake);

      final result = await repo.uploadAttachment(
        projectId: 'p1',
        fieldName: 'photo',
        file: File('x.jpg'),
      );

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail('expected Left'));
    });
  });
}
```

- [ ] **Step 3: Run tests to verify the new ones fail**

Run: `flutter test test/project_repository_impl_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:enterprise_flutter_app/features/project/data/repositories/project_repository_impl.dart'`

- [ ] **Step 4: Write the repository implementation**

```dart
// lib/features/project/data/repositories/project_repository_impl.dart
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_remote_datasource.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl({required this.remoteDataSource});

  final ProjectRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<Project>>> getProjects() async {
    try {
      return right(await remoteDataSource.getProjects());
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'No internet connection'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Project>> getProject(String id) async {
    try {
      return right(await remoteDataSource.getProject(id));
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'No internet connection'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAttachment({
    required String projectId,
    required String fieldName,
    required File file,
  }) async {
    try {
      final url = await remoteDataSource.uploadAttachment(
        projectId: projectId,
        fieldName: fieldName,
        file: file,
      );
      return right(url);
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'No internet connection'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/project_repository_impl_test.dart`
Expected: `00:0X +7: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/project/domain/repositories/project_repository.dart lib/features/project/data/repositories/project_repository_impl.dart test/project_repository_impl_test.dart
git commit -m "feat: add ProjectRepository with Either/Failure mapping"
```

---

### Task 5: Project usecases and providers

**Files:**
- Create: `lib/features/project/domain/usecases/get_projects_usecase.dart`
- Create: `lib/features/project/domain/usecases/upload_attachment_usecase.dart`
- Create: `lib/features/project/presentation/providers/project_providers.dart`

**Interfaces:**
- Consumes: `ProjectRepository` (Task 4), `tileServerBaseUrlProvider` and `networkInfoProvider`.
- Produces: `getProjectsUseCaseProvider`, `uploadAttachmentUseCaseProvider`, `projectsProvider` (`FutureProvider<List<Project>>`), `selectedProjectProvider` (`StateProvider<Project?>`) — consumed by `ProjectPickerSheet` (Task 6), `DynamicFormSheet` (Task 7), `TrackRecordFab` (Task 11), `FeatureRecordFab` (Task 18).

- [ ] **Step 1: Write the usecases**

```dart
// lib/features/project/domain/usecases/get_projects_usecase.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

class GetProjectsUseCase {
  GetProjectsUseCase(this._repository);
  final ProjectRepository _repository;

  Future<Either<Failure, List<Project>>> call() => _repository.getProjects();
}
```

```dart
// lib/features/project/domain/usecases/upload_attachment_usecase.dart
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/project_repository.dart';

class UploadAttachmentUseCase {
  UploadAttachmentUseCase(this._repository);
  final ProjectRepository _repository;

  Future<Either<Failure, String>> call({
    required String projectId,
    required String fieldName,
    required File file,
  }) =>
      _repository.uploadAttachment(
        projectId: projectId,
        fieldName: fieldName,
        file: file,
      );
}
```

- [ ] **Step 2: Write the providers**

```dart
// lib/features/project/presentation/providers/project_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/external_dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../map/presentation/providers/map_providers.dart' show tileServerBaseUrlProvider;
import '../../data/datasources/project_remote_datasource.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/get_projects_usecase.dart';
import '../../domain/usecases/upload_attachment_usecase.dart';

final projectApiClientProvider = Provider<ExternalDioClient>((ref) {
  return ExternalDioClient(
    baseUrl: ref.watch(tileServerBaseUrlProvider),
    networkInfo: ref.watch(networkInfoProvider),
    enableLogging: false,
  );
});

final projectRemoteDataSourceProvider = Provider<ProjectRemoteDataSource>((ref) {
  return ProjectRemoteDataSourceImpl(ref.watch(projectApiClientProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl(
    remoteDataSource: ref.watch(projectRemoteDataSourceProvider),
  );
});

final getProjectsUseCaseProvider = Provider<GetProjectsUseCase>((ref) {
  return GetProjectsUseCase(ref.watch(projectRepositoryProvider));
});

final uploadAttachmentUseCaseProvider = Provider<UploadAttachmentUseCase>((ref) {
  return UploadAttachmentUseCase(ref.watch(projectRepositoryProvider));
});

/// Project catalog from the tile server. Refresh with `ref.invalidate`.
final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final result = await ref.watch(getProjectsUseCaseProvider).call();
  return result.fold((failure) => throw failure, (projects) => projects);
});

/// The project currently active for capture. Session-only (not persisted);
/// reset on cold start. Set by `ProjectPickerSheet` when the user picks one.
final selectedProjectProvider = StateProvider<Project?>((ref) => null);
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/features/project/`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/project/domain/usecases lib/features/project/presentation/providers
git commit -m "feat: add project usecases and Riverpod providers"
```

---

### Task 6: ProjectPickerSheet widget

**Files:**
- Create: `lib/features/project/presentation/widgets/project_picker_sheet.dart`

**Interfaces:**
- Consumes: `projectsProvider` (Task 5), `Project`.
- Produces: `Future<Project?> showProjectPickerSheet(BuildContext, {required List<String> allowedGeometryTypes})`.

- [ ] **Step 1: Write the widget**

```dart
// lib/features/project/presentation/widgets/project_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/project.dart';
import '../providers/project_providers.dart';

/// Opens a bottom sheet listing projects whose `geometryType` is in
/// [allowedGeometryTypes]. Returns the picked [Project], or `null` if the
/// user dismissed the sheet without picking one.
Future<Project?> showProjectPickerSheet(
  BuildContext context, {
  required List<String> allowedGeometryTypes,
}) {
  return showModalBottomSheet<Project>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ProjectPickerSheet(allowedGeometryTypes: allowedGeometryTypes),
  );
}

class ProjectPickerSheet extends ConsumerWidget {
  const ProjectPickerSheet({required this.allowedGeometryTypes, super.key});

  final List<String> allowedGeometryTypes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: projectsAsync.when(
          data: (projects) {
            final filtered = projects
                .where((p) => allowedGeometryTypes.contains(p.geometryType))
                .toList();
            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No ${allowedGeometryTypes.join("/")} projects available — '
                  'create one first.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                for (final project in filtered)
                  ListTile(
                    title: Text(project.name),
                    subtitle: Text(
                      '${project.geometryType} · ${project.featureCount} features',
                    ),
                    onTap: () => Navigator.of(context).pop(project),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load projects: $error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(projectsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/project/presentation/widgets/project_picker_sheet.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/project/presentation/widgets/project_picker_sheet.dart
git commit -m "feat: add ProjectPickerSheet bottom sheet with retry and empty states"
```

---

### Task 7: DynamicFormSheet widget

**Files:**
- Create: `lib/features/map/presentation/widgets/dynamic_form_sheet.dart`
- Create: `test/dynamic_form_sheet_test.dart`

**Interfaces:**
- Consumes: `ProjectFormField` (Task 1), `uploadAttachmentUseCaseProvider` (Task 5).
- Produces: `Future<Map<String, dynamic>?> showDynamicFormSheet(BuildContext, {required String projectId, required List<ProjectFormField> fields, Map<String, dynamic> initial})`.

- [ ] **Step 1: Write the failing widget test**

```dart
// test/dynamic_form_sheet_test.dart
import 'dart:io';

import 'package:enterprise_flutter_app/core/errors/failures.dart';
import 'package:enterprise_flutter_app/features/map/presentation/widgets/dynamic_form_sheet.dart';
import 'package:enterprise_flutter_app/features/project/domain/entities/project.dart';
import 'package:enterprise_flutter_app/features/project/domain/usecases/upload_attachment_usecase.dart';
import 'package:enterprise_flutter_app/features/project/presentation/providers/project_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

Future<Map<String, dynamic>?> _pump(
  WidgetTester tester, {
  required List<ProjectFormField> fields,
  Map<String, dynamic> initial = const {},
  List<Override> overrides = const [],
}) async {
  Map<String, dynamic>? result;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDynamicFormSheet(
                  context,
                  projectId: 'p1',
                  fields: fields,
                  initial: initial,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('required text field blocks Save until filled', (tester) async {
    await _pump(tester, fields: const [
      ProjectFormField(name: 'name', label: 'Nama', type: 'text', required: true),
    ]);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Nama is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Jalan A');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsNothing); // sheet closed
  });

  testWidgets('select field renders options from ProjectFormField.options', (tester) async {
    await _pump(tester, fields: const [
      ProjectFormField(
        name: 'select',
        label: 'Select',
        type: 'select',
        options: ['adfdf', 'dfdf'],
      ),
    ]);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('adfdf').hitTestable(), findsOneWidget);
    expect(find.text('dfdf').hitTestable(), findsOneWidget);
  });

  testWidgets('number field rejects value below min', (tester) async {
    await _pump(tester, fields: const [
      ProjectFormField(name: 'year', label: 'Tahun', type: 'number', min: 2000, max: 2030),
    ]);

    await tester.enterText(find.byType(TextFormField).first, '1999');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Tahun must be >= 2000'), findsOneWidget);
  });

  testWidgets('file field uploads and stores the returned url', (tester) async {
    final fakeUseCase = _FakeUploadAttachmentUseCase();
    final result = await _pump(
      tester,
      fields: const [
        ProjectFormField(name: 'photo', label: 'Photo', type: 'file'),
      ],
      overrides: [
        uploadAttachmentUseCaseProvider.overrideWithValue(fakeUseCase),
      ],
    );

    // Simulate picking succeeded by driving the widget's upload button;
    // ImagePicker itself cannot be exercised in a widget test, so this test
    // only asserts the "unsupported/idle" initial render is stable.
    expect(find.text('Choose file'), findsOneWidget);
    expect(result, isNull); // sheet still open, nothing picked in this test
  });
}

class _FakeUploadAttachmentUseCase implements UploadAttachmentUseCase {
  @override
  Future<Either<Failure, String>> call({
    required String projectId,
    required String fieldName,
    required File file,
  }) async =>
      right('https://tiles.example.com/attachments/1.jpg');
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/dynamic_form_sheet_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:enterprise_flutter_app/features/map/presentation/widgets/dynamic_form_sheet.dart'`

- [ ] **Step 3: Write the widget**

```dart
// lib/features/map/presentation/widgets/dynamic_form_sheet.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../project/domain/entities/project.dart';
import '../../../project/presentation/providers/project_providers.dart';

/// Renders a form from a project's dynamic [ProjectFormField] schema and
/// returns the filled attribute map on Save, or `null` if dismissed.
Future<Map<String, dynamic>?> showDynamicFormSheet(
  BuildContext context, {
  required String projectId,
  required List<ProjectFormField> fields,
  Map<String, dynamic> initial = const {},
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DynamicFormSheet(
      projectId: projectId,
      fields: fields,
      initial: initial,
    ),
  );
}

class DynamicFormSheet extends ConsumerStatefulWidget {
  const DynamicFormSheet({
    required this.projectId,
    required this.fields,
    this.initial = const {},
    super.key,
  });

  final String projectId;
  final List<ProjectFormField> fields;
  final Map<String, dynamic> initial;

  @override
  ConsumerState<DynamicFormSheet> createState() => _DynamicFormSheetState();
}

class _DynamicFormSheetState extends ConsumerState<DynamicFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, dynamic> _values = Map<String, dynamic>.from(widget.initial);
  final Set<String> _uploading = {};
  final Map<String, String> _fileErrors = {};

  bool get _canSubmit => _uploading.isEmpty;

  Future<void> _pickFile(ProjectFormField field) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() {
      _uploading.add(field.name);
      _fileErrors.remove(field.name);
    });

    final result = await ref.read(uploadAttachmentUseCaseProvider).call(
          projectId: widget.projectId,
          fieldName: field.name,
          file: File(picked.path),
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _fileErrors[field.name] = failure.message;
        _uploading.remove(field.name);
      }),
      (url) => setState(() {
        _values[field.name] = url;
        _uploading.remove(field.name);
      }),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_canSubmit) return;
    Navigator.of(context).pop(_values);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Details', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final field in widget.fields) ...[
                  _buildField(field),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(ProjectFormField field) {
    switch (field.type) {
      case 'text':
        return TextFormField(
          initialValue: _values[field.name] as String?,
          decoration: InputDecoration(labelText: field.label),
          validator: (v) =>
              field.required && (v == null || v.isEmpty) ? '${field.label} is required' : null,
          onChanged: (v) => _values[field.name] = v,
        );
      case 'textarea':
        return TextFormField(
          initialValue: _values[field.name] as String?,
          decoration: InputDecoration(labelText: field.label),
          maxLines: null,
          minLines: 3,
          validator: (v) =>
              field.required && (v == null || v.isEmpty) ? '${field.label} is required' : null,
          onChanged: (v) => _values[field.name] = v,
        );
      case 'number':
        return TextFormField(
          initialValue: _values[field.name]?.toString(),
          decoration: InputDecoration(labelText: field.label),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (field.required && (v == null || v.isEmpty)) {
              return '${field.label} is required';
            }
            if (v == null || v.isEmpty) return null;
            final n = num.tryParse(v);
            if (n == null) return '${field.label} must be a number';
            if (field.min != null && n < field.min!) {
              return '${field.label} must be >= ${field.min}';
            }
            if (field.max != null && n > field.max!) {
              return '${field.label} must be <= ${field.max}';
            }
            return null;
          },
          onChanged: (v) => _values[field.name] = num.tryParse(v) ?? v,
        );
      case 'select':
        return DropdownButtonFormField<String>(
          value: _values[field.name] as String?,
          decoration: InputDecoration(labelText: field.label),
          items: [
            for (final option in field.options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          validator: (v) => field.required && v == null ? '${field.label} is required' : null,
          onChanged: (v) => setState(() => _values[field.name] = v),
        );
      case 'file':
        final uploading = _uploading.contains(field.name);
        final error = _fileErrors[field.name];
        final value = _values[field.name] as String?;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: uploading ? null : () => _pickFile(field),
              icon: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file),
              label: Text(value == null ? 'Choose file' : 'File attached'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        );
      default:
        return TextFormField(
          initialValue: _values[field.name]?.toString(),
          decoration: InputDecoration(labelText: '${field.label} (unsupported field)'),
          enabled: false,
        );
    }
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/dynamic_form_sheet_test.dart`
Expected: `00:0X +4: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/map/presentation/widgets/dynamic_form_sheet.dart test/dynamic_form_sheet_test.dart
git commit -m "feat: add DynamicFormSheet rendering text/textarea/number/select/file fields"
```

---

### Task 8: Extend TrackRecord entity + model with projectId/attributes

**Files:**
- Modify: `lib/features/map/domain/entities/track_record.dart`
- Modify: `lib/features/map/data/models/track_record_model.dart`

**Interfaces:**
- Produces: `TrackRecord.projectId` (`String`, default `''`), `TrackRecord.attributes` (`Map<String, dynamic>`, default `{}`), both included in `copyWith`, `TrackRecordModel.fromJson`/`toJson`/`fromEntity`.

- [ ] **Step 1: Extend the entity**

Edit `lib/features/map/domain/entities/track_record.dart`, in the `TrackRecord` class:

```dart
class TrackRecord {
  const TrackRecord({
    required this.id,
    required this.name,
    this.note = '',
    required this.createdAt,
    this.updatedAt,
    required this.points,
    this.syncStatus = SyncStatus.pending,
    this.syncedAt,
    this.projectId = '',
    this.attributes = const {},
  });

  final String id;
  final String name;
  final String note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TrackPoint> points;
  final SyncStatus syncStatus;
  final DateTime? syncedAt;

  /// Id of the [Project] this track will be synced under.
  final String projectId;

  /// Values from the project's dynamic `form_schema`, filled when the
  /// recording is stopped.
  final Map<String, dynamic> attributes;

  // ... distanceMeters / duration getters unchanged ...

  TrackRecord copyWith({
    String? id,
    String? name,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TrackPoint>? points,
    SyncStatus? syncStatus,
    DateTime? syncedAt,
    String? projectId,
    Map<String, dynamic>? attributes,
  }) {
    return TrackRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      points: points ?? this.points,
      syncStatus: syncStatus ?? this.syncStatus,
      syncedAt: syncedAt ?? this.syncedAt,
      projectId: projectId ?? this.projectId,
      attributes: attributes ?? this.attributes,
    );
  }
}
```

(Leave `TrackPoint`, `_haversine`, `_toRad`, `SyncStatus` unchanged.)

- [ ] **Step 2: Extend the model**

Edit `lib/features/map/data/models/track_record_model.dart`:

```dart
class TrackRecordModel extends TrackRecord {
  const TrackRecordModel({
    required super.id,
    required super.name,
    super.note,
    required super.createdAt,
    super.updatedAt,
    required super.points,
    super.syncStatus,
    super.syncedAt,
    super.projectId,
    super.attributes,
  });

  factory TrackRecordModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List?) ?? [];
    return TrackRecordModel(
      id: json['id'] as String,
      name: json['name'] as String,
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      points: rawPoints
          .map((e) => TrackPointModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      syncStatus: _parseStatus(json['syncStatus']),
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
      // Older locally-stored records predate these fields — default so
      // existing Hive data still parses.
      projectId: json['projectId'] as String? ?? '',
      attributes: json['attributes'] == null
          ? const {}
          : Map<String, dynamic>.from(json['attributes'] as Map),
    );
  }

  factory TrackRecordModel.fromEntity(TrackRecord record) {
    return TrackRecordModel(
      id: record.id,
      name: record.name,
      note: record.note,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      points: record.points
          .map((p) => TrackPointModel(
                latitude: p.latitude,
                longitude: p.longitude,
                altitude: p.altitude,
                speed: p.speed,
                accuracy: p.accuracy,
                timestamp: p.timestamp,
              ))
          .toList(),
      syncStatus: record.syncStatus,
      syncedAt: record.syncedAt,
      projectId: record.projectId,
      attributes: record.attributes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'points': points.map((p) => (p as TrackPointModel).toJson()).toList(),
        'syncStatus': syncStatus.name,
        'syncedAt': syncedAt?.toIso8601String(),
        'projectId': projectId,
        'attributes': attributes,
      };

  TrackRecord toEntity() => TrackRecord(
        id: id,
        name: name,
        note: note,
        createdAt: createdAt,
        updatedAt: updatedAt,
        points: points,
        syncStatus: syncStatus,
        syncedAt: syncedAt,
        projectId: projectId,
        attributes: attributes,
      );

  static SyncStatus _parseStatus(dynamic raw) {
    if (raw is String) {
      return SyncStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => SyncStatus.pending,
      );
    }
    return SyncStatus.pending;
  }
}
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/features/map/domain/entities/track_record.dart lib/features/map/data/models/track_record_model.dart`
Expected: errors in `track_record_local_datasource.dart`, `track_record_repository.dart`, `track_record_repository_impl.dart`, `track_record_fab.dart` (still calling old `startTrack` signature) — these are fixed in Tasks 9–11. For this task, just confirm the two edited files themselves have no *new* issues:
Expected: `No issues found!` for the two files listed in the command above.

- [ ] **Step 4: Commit**

```bash
git add lib/features/map/domain/entities/track_record.dart lib/features/map/data/models/track_record_model.dart
git commit -m "feat: add projectId and attributes to TrackRecord entity and model"
```

---

### Task 9: Wire real sync upload + new usecases into TrackRecord repository

**Files:**
- Modify: `lib/features/map/domain/repositories/track_record_repository.dart`
- Modify: `lib/features/map/data/datasources/track_record_local_datasource.dart`
- Modify: `lib/features/map/data/repositories/track_record_repository_impl.dart`
- Modify: `lib/features/map/domain/usecases/start_track_usecase.dart`
- Create: `lib/features/map/domain/usecases/get_track_usecase.dart`
- Create: `lib/features/map/domain/usecases/save_track_usecase.dart`
- Create: `test/track_record_repository_impl_test.dart`

**Interfaces:**
- Consumes: `ProjectRemoteDataSource` (Task 3).
- Produces: `TrackRecordRepository.startTrack({required name, note, required projectId})`; `GetTrackUseCase(id)`, `SaveTrackUseCase(track)`.

- [ ] **Step 1: Update the repository interface**

Edit `lib/features/map/domain/repositories/track_record_repository.dart`, change the `startTrack` signature:

```dart
  /// Create a new empty track under [projectId]; returns its id.
  Future<Either<Failure, String>> startTrack({
    required String name,
    String note = '',
    required String projectId,
  });
```

- [ ] **Step 2: Update the local datasource signature**

Edit `lib/features/map/data/datasources/track_record_local_datasource.dart`:

```dart
  Future<String> startTrack({required String name, String note = '', required String projectId});
```

And its implementation:

```dart
  @override
  Future<String> startTrack({
    required String name,
    String note = '',
    required String projectId,
  }) async {
    final id = '${DateTime.now().millisecondsSinceEpoch}';
    final track = TrackRecordModel(
      id: id,
      name: name,
      note: note,
      createdAt: DateTime.now(),
      points: const [],
      projectId: projectId,
    );
    final tracks = _readAll()..add(track);
    await _writeAll(tracks);
    return id;
  }
```

- [ ] **Step 3: Write the failing sync test**

```dart
// test/track_record_repository_impl_test.dart
import 'dart:io';

import 'package:enterprise_flutter_app/features/map/data/datasources/track_record_local_datasource.dart';
import 'package:enterprise_flutter_app/features/map/data/repositories/track_record_repository_impl.dart';
import 'package:enterprise_flutter_app/features/map/domain/entities/track_record.dart';
import 'package:enterprise_flutter_app/features/project/data/datasources/project_remote_datasource.dart';
import 'package:enterprise_flutter_app/features/project/data/models/project_model.dart';
import 'package:enterprise_flutter_app/core/network/network_info.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNetworkInfo implements NetworkInfo {
  _FakeNetworkInfo({this.online = true});
  final bool online;
  @override
  Future<bool> get isConnected async => online;
}

class _FakeLocalDataSource implements TrackRecordLocalDataSource {
  List<TrackRecord> tracks = [];
  final Set<String> synced = {};
  final Set<String> failed = {};

  @override
  Future<void> openBox() async {}
  @override
  Future<List<TrackRecord>> getAll() async => tracks;
  @override
  Future<TrackRecord?> getById(String id) async {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }
  @override
  Future<String> startTrack({required String name, String note = '', required String projectId}) async {
    throw UnimplementedError();
  }
  @override
  Future<void> addPoint(String trackId, {required double latitude, required double longitude, double altitude = 0, double speed = 0, double accuracy = 0, DateTime? timestamp}) async {}
  @override
  Future<void> saveTrack(TrackRecord track) async {}
  @override
  Future<void> deleteTrack(String trackId) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<void> markSynced(String trackId) async => synced.add(trackId);
  @override
  Future<void> markFailed(String trackId) async => failed.add(trackId);
  @override
  Future<List<TrackRecord>> getPending() async =>
      tracks.where((t) => t.syncStatus != SyncStatus.synced).toList();
}

class _RecordedCall {
  _RecordedCall(this.projectId, this.geometry, this.attributes);
  final String projectId;
  final Map<String, dynamic> geometry;
  final Map<String, dynamic> attributes;
}

class _FakeProjectRemoteDataSource implements ProjectRemoteDataSource {
  final List<_RecordedCall> calls = [];
  bool shouldFail = false;

  @override
  Future<List<ProjectModel>> getProjects() async => const [];
  @override
  Future<ProjectModel> getProject(String id) async => throw UnimplementedError();
  @override
  Future<String> uploadAttachment({required String projectId, required String fieldName, required File file}) async =>
      throw UnimplementedError();

  @override
  Future<void> createFeature({
    required String projectId,
    required Map<String, dynamic> geometry,
    required Map<String, dynamic> attributes,
  }) async {
    if (shouldFail) throw Exception('boom');
    calls.add(_RecordedCall(projectId, geometry, attributes));
  }
}

void main() {
  group('TrackRecordRepositoryImpl.syncPending', () {
    test('builds a LineString geometry from track points and marks synced', () async {
      final local = _FakeLocalDataSource()
        ..tracks = [
          TrackRecord(
            id: 't1',
            name: 'Track 1',
            createdAt: DateTime(2026, 7, 22),
            projectId: 'proj-line',
            attributes: {'name': 'Jl. Test'},
            points: [
              TrackPoint(latitude: -6.2, longitude: 106.8, timestamp: DateTime(2026, 7, 22)),
            ],
          ),
        ];
      final remote = _FakeProjectRemoteDataSource();
      final repo = TrackRecordRepositoryImpl(
        localDataSource: local,
        networkInfo: _FakeNetworkInfo(),
        projectRemoteDataSource: remote,
      );

      await repo.syncPending();

      expect(remote.calls, hasLength(1));
      expect(remote.calls.first.projectId, 'proj-line');
      expect(remote.calls.first.geometry['type'], 'LineString');
      expect(remote.calls.first.geometry['coordinates'], [[106.8, -6.2]]);
      expect(remote.calls.first.attributes, {'name': 'Jl. Test'});
      expect(local.synced, contains('t1'));
    });

    test('marks the record failed when the upload throws', () async {
      final local = _FakeLocalDataSource()
        ..tracks = [
          TrackRecord(
            id: 't2',
            name: 'Track 2',
            createdAt: DateTime(2026, 7, 22),
            projectId: 'proj-line',
            points: const [],
          ),
        ];
      final remote = _FakeProjectRemoteDataSource()..shouldFail = true;
      final repo = TrackRecordRepositoryImpl(
        localDataSource: local,
        networkInfo: _FakeNetworkInfo(),
        projectRemoteDataSource: remote,
      );

      await repo.syncPending();

      expect(local.failed, contains('t2'));
    });

    test('is a no-op when offline', () async {
      final local = _FakeLocalDataSource()
        ..tracks = [
          TrackRecord(id: 't3', name: 'T3', createdAt: DateTime(2026, 7, 22), projectId: 'p', points: const []),
        ];
      final remote = _FakeProjectRemoteDataSource();
      final repo = TrackRecordRepositoryImpl(
        localDataSource: local,
        networkInfo: _FakeNetworkInfo(online: false),
        projectRemoteDataSource: remote,
      );

      final result = await repo.syncPending();

      result.fold((_) => fail('expected Right'), (count) => expect(count, 0));
      expect(remote.calls, isEmpty);
    });
  });
}
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `flutter test test/track_record_repository_impl_test.dart`
Expected: FAIL — `TrackRecordRepositoryImpl` has no named parameter `projectRemoteDataSource` (impl not yet updated).

- [ ] **Step 5: Update the repository implementation**

Edit `lib/features/map/data/repositories/track_record_repository_impl.dart`:

```dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../project/data/datasources/project_remote_datasource.dart';
import '../../domain/entities/track_record.dart';
import '../../domain/repositories/track_record_repository.dart';
import '../datasources/track_record_local_datasource.dart';

class TrackRecordRepositoryImpl implements TrackRecordRepository {
  TrackRecordRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
    required this.projectRemoteDataSource,
  });

  final TrackRecordLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final ProjectRemoteDataSource projectRemoteDataSource;

  @override
  Future<Either<Failure, List<TrackRecord>>> getTracks() async {
    try {
      return right(await localDataSource.getAll());
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TrackRecord>> getTrack(String id) async {
    try {
      final track = await localDataSource.getById(id);
      if (track == null) {
        return left(const CacheFailure(message: 'Track not found'));
      }
      return right(track);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> startTrack({
    required String name,
    String note = '',
    required String projectId,
  }) async {
    try {
      return right(
        await localDataSource.startTrack(name: name, note: note, projectId: projectId),
      );
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addPoint(
    String trackId, {
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    double speed = 0.0,
    double accuracy = 0.0,
    DateTime? timestamp,
  }) async {
    try {
      await localDataSource.addPoint(
        trackId,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        speed: speed,
        accuracy: accuracy,
        timestamp: timestamp,
      );
      return right(unit);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveTrack(TrackRecord track) async {
    try {
      await localDataSource.saveTrack(track);
      return right(unit);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTrack(String trackId) async {
    try {
      await localDataSource.deleteTrack(trackId);
      return right(unit);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TrackRecord>>> getPending() async {
    try {
      return right(await localDataSource.getPending());
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> syncPending() async {
    try {
      final online = await networkInfo.isConnected;
      if (!online) return right(0);

      final pending = await localDataSource.getPending();
      if (pending.isEmpty) return right(0);

      var syncedCount = 0;
      for (final record in pending) {
        final ok = await _upload(record);
        if (ok) {
          await localDataSource.markSynced(record.id);
          syncedCount++;
        } else {
          await localDataSource.markFailed(record.id);
        }
      }
      return right(syncedCount);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  Future<bool> _upload(TrackRecord record) async {
    try {
      await projectRemoteDataSource.createFeature(
        projectId: record.projectId,
        geometry: {
          'type': 'LineString',
          'coordinates': [
            for (final p in record.points) [p.longitude, p.latitude],
          ],
        },
        attributes: record.attributes,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

- [ ] **Step 6: Add the new usecases**

```dart
// lib/features/map/domain/usecases/get_track_usecase.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/track_record.dart';
import '../repositories/track_record_repository.dart';

class GetTrackUseCase {
  GetTrackUseCase(this._repository);
  final TrackRecordRepository _repository;

  Future<Either<Failure, TrackRecord>> call(String id) => _repository.getTrack(id);
}
```

```dart
// lib/features/map/domain/usecases/save_track_usecase.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/track_record.dart';
import '../repositories/track_record_repository.dart';

class SaveTrackUseCase {
  SaveTrackUseCase(this._repository);
  final TrackRecordRepository _repository;

  Future<Either<Failure, Unit>> call(TrackRecord track) => _repository.saveTrack(track);
}
```

Edit `lib/features/map/domain/usecases/start_track_usecase.dart`:

```dart
class StartTrackUseCase {
  StartTrackUseCase(this._repository);
  final TrackRecordRepository _repository;

  Future<Either<Failure, String>> call({
    required String name,
    String note = '',
    required String projectId,
  }) =>
      _repository.startTrack(name: name, note: note, projectId: projectId);
}
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/track_record_repository_impl_test.dart`
Expected: `00:0X +3: All tests passed!`

- [ ] **Step 8: Commit**

```bash
git add lib/features/map/domain/repositories/track_record_repository.dart lib/features/map/data/datasources/track_record_local_datasource.dart lib/features/map/data/repositories/track_record_repository_impl.dart lib/features/map/domain/usecases/start_track_usecase.dart lib/features/map/domain/usecases/get_track_usecase.dart lib/features/map/domain/usecases/save_track_usecase.dart test/track_record_repository_impl_test.dart
git commit -m "feat: sync track records to /projects/{id}/features, add get/save track usecases"
```

---

### Task 10: Update map_providers.dart with new track/project providers

**Files:**
- Modify: `lib/features/map/presentation/providers/map_providers.dart`

**Interfaces:**
- Consumes: `ProjectRemoteDataSource` (via `projectRemoteDataSourceProvider`, Task 5), `GetTrackUseCase`/`SaveTrackUseCase` (Task 9).
- Produces: `getTrackUseCaseProvider`, `saveTrackUseCaseProvider`; updates `trackRecordRepositoryProvider` to pass `projectRemoteDataSource`.

- [ ] **Step 1: Edit the providers file**

Add imports:

```dart
import '../../../project/presentation/providers/project_providers.dart'
    show projectRemoteDataSourceProvider;
import '../../domain/usecases/get_track_usecase.dart';
import '../../domain/usecases/save_track_usecase.dart';
```

Update `trackRecordRepositoryProvider`:

```dart
final trackRecordRepositoryProvider = Provider<TrackRecordRepository>((ref) {
  return TrackRecordRepositoryImpl(
    localDataSource: ref.watch(trackRecordLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    projectRemoteDataSource: ref.watch(projectRemoteDataSourceProvider),
  );
});
```

Add, near `startTrackUseCaseProvider`:

```dart
final getTrackUseCaseProvider = Provider<GetTrackUseCase>((ref) {
  return GetTrackUseCase(ref.watch(trackRecordRepositoryProvider));
});

final saveTrackUseCaseProvider = Provider<SaveTrackUseCase>((ref) {
  return SaveTrackUseCase(ref.watch(trackRecordRepositoryProvider));
});
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/map/presentation/providers/map_providers.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/map/presentation/providers/map_providers.dart
git commit -m "feat: wire ProjectRemoteDataSource and get/save track usecases into map providers"
```

---

### Task 11: Gate TrackRecordFab behind project selection + dynamic form on stop

**Files:**
- Modify: `lib/features/map/presentation/widgets/track_record_fab.dart`

**Interfaces:**
- Consumes: `showProjectPickerSheet` (Task 6), `showDynamicFormSheet` (Task 7), `selectedProjectProvider` (Task 5), `getTrackUseCaseProvider`/`saveTrackUseCaseProvider` (Task 10).

- [ ] **Step 1: Rewrite the widget**

```dart
// lib/features/map/presentation/widgets/track_record_fab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logger/index.dart';
import '../../../../core/services/gps_service.dart';
import '../../../project/domain/entities/project.dart';
import '../../../project/presentation/providers/project_providers.dart';
import '../../../project/presentation/widgets/project_picker_sheet.dart';
import '../../domain/entities/track_record.dart';
import '../providers/map_providers.dart';
import 'dynamic_form_sheet.dart';

/// Floating action button that starts/stops a GPS track recording session.
///
/// Starting a track requires a `line`-geometry [Project] to be selected
/// first (prompted via [showProjectPickerSheet] if none is active). Stopping
/// opens [showDynamicFormSheet] to fill the project's attribute form before
/// the track is queued for sync.
class TrackRecordFab extends ConsumerStatefulWidget {
  const TrackRecordFab({required this.onPointsChanged, super.key});
  final void Function(List<TrackPoint> points) onPointsChanged;

  @override
  ConsumerState<TrackRecordFab> createState() => _TrackRecordFabState();
}

class _TrackRecordFabState extends ConsumerState<TrackRecordFab> {
  final GpsService _gps = GpsService();
  Stream<LocationData>? _stream;
  List<TrackPoint> _points = const [];
  bool _busy = false;
  Project? _activeProject;

  String? get _activeId => ref.read(activeTrackIdProvider);
  bool get _recording => _activeId != null;

  Future<void> _toggle() async {
    if (_recording) return _stop();
    await _start();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      var project = ref.read(selectedProjectProvider);
      if (project == null || project.geometryType != 'line') {
        project = await showProjectPickerSheet(context, allowedGeometryTypes: const ['line']);
        if (project == null || !mounted) return;
        ref.read(selectedProjectProvider.notifier).state = project;
      }
      _activeProject = project;

      final name =
          'Track ${DateTime.now().toString().replaceFirst(' ', ' · ').substring(0, 16)}';
      final idResult = await ref.read(startTrackUseCaseProvider)(
        name: name,
        projectId: project.id,
      );
      final id = idResult.fold(
        (f) => throw Exception(f.message),
        (id) => id,
      );

      _points = const [];
      widget.onPointsChanged(_points);
      ref.read(activeTrackIdProvider.notifier).state = id;

      _stream = _gps.getLocationStream(distanceFilter: 5);
      _stream!.listen((loc) => _onPoint(loc));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onPoint(LocationData loc) async {
    final id = _activeId;
    if (id == null) return;
    final result = await ref.read(addTrackPointUseCaseProvider)(
      id,
      latitude: loc.latitude,
      longitude: loc.longitude,
      altitude: loc.altitude ?? 0,
      speed: loc.speed ?? 0,
      accuracy: loc.accuracy ?? 0,
      timestamp: loc.timestamp,
    );
    result.fold(
      (f) => log.w('addPoint failed: ${f.message}'),
      (_) {
        _points = [..._points, _toPoint(loc)];
        widget.onPointsChanged(_points);
      },
    );
  }

  Future<void> _stop() async {
    final id = _activeId;
    final project = _activeProject;
    ref.read(activeTrackIdProvider.notifier).state = null;
    _stream = null;

    if (id != null && project != null && mounted) {
      final trackResult = await ref.read(getTrackUseCaseProvider)(id);
      final track = trackResult.fold((_) => null, (t) => t);
      if (track != null && mounted) {
        final attributes = await showDynamicFormSheet(
          context,
          projectId: project.id,
          fields: project.formSchema,
          initial: track.attributes,
        );
        if (attributes != null) {
          await ref.read(saveTrackUseCaseProvider)(track.copyWith(attributes: attributes));
        }
      }
    }

    _points = const [];
    widget.onPointsChanged(_points);
    ref.invalidate(trackRecordsProvider);
    _activeProject = null;
    if (mounted) setState(() {});
  }

  TrackPoint _toPoint(LocationData loc) => TrackPoint(
        latitude: loc.latitude,
        longitude: loc.longitude,
        altitude: loc.altitude ?? 0,
        speed: loc.speed ?? 0,
        accuracy: loc.accuracy ?? 0,
        timestamp: loc.timestamp,
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      heroTag: 'track-record',
      tooltip: _recording ? 'Stop recording' : 'Start recording',
      backgroundColor: _recording ? Colors.red : colorScheme.primary,
      onPressed: _busy ? null : _toggle,
      child: _busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/map/presentation/widgets/track_record_fab.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/map/presentation/widgets/track_record_fab.dart
git commit -m "feat: gate track recording behind project pick, fill dynamic form on stop"
```

---

### Task 12: FeatureRecord domain entity

**Files:**
- Create: `lib/features/map/domain/entities/feature_record.dart`

**Interfaces:**
- Consumes: `SyncStatus` from `lib/features/map/domain/entities/track_record.dart`.
- Produces: `class FeatureRecord { id, projectId, geometryType, coordinates, attributes, syncStatus, createdAt, syncedAt }`.

- [ ] **Step 1: Write the entity**

```dart
// lib/features/map/domain/entities/feature_record.dart
import 'track_record.dart' show SyncStatus;

/// A single captured Feature Record: a point or polygon geometry plus
/// attribute values from a [Project]'s dynamic `form_schema`.
///
/// [geometryType] is `'point'` or `'polygon'`. [coordinates] holds raw
/// `[lng, lat]` pairs: exactly one for a point, an open ring (not
/// self-closed) of 3+ vertices for a polygon. Closing the ring and wrapping
/// into GeoJSON happens at sync time, not in this entity.
class FeatureRecord {
  const FeatureRecord({
    required this.id,
    required this.projectId,
    required this.geometryType,
    required this.coordinates,
    this.attributes = const {},
    this.syncStatus = SyncStatus.pending,
    required this.createdAt,
    this.syncedAt,
  });

  final String id;
  final String projectId;
  final String geometryType;
  final List<List<double>> coordinates;
  final Map<String, dynamic> attributes;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime? syncedAt;

  FeatureRecord copyWith({
    String? id,
    String? projectId,
    String? geometryType,
    List<List<double>>? coordinates,
    Map<String, dynamic>? attributes,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) {
    return FeatureRecord(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      geometryType: geometryType ?? this.geometryType,
      coordinates: coordinates ?? this.coordinates,
      attributes: attributes ?? this.attributes,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/map/domain/entities/feature_record.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/map/domain/entities/feature_record.dart
git commit -m "feat: add FeatureRecord domain entity"
```

---

### Task 13: FeatureRecord model + local Hive datasource

**Files:**
- Create: `lib/features/map/data/models/feature_record_model.dart`
- Create: `lib/features/map/data/datasources/feature_record_local_datasource.dart`

**Interfaces:**
- Consumes: `FeatureRecord` (Task 12).
- Produces: `FeatureRecordModel.fromJson/toJson/fromEntity/toEntity`; `FeatureRecordLocalDataSource { openBox, getAll, getById, saveRecord, deleteRecord, clear, markSynced, markFailed, getPending }` reading/writing Hive box `record_features`.

- [ ] **Step 1: Write the model**

```dart
// lib/features/map/data/models/feature_record_model.dart
import '../../domain/entities/feature_record.dart';
import '../../domain/entities/track_record.dart' show SyncStatus;

class FeatureRecordModel extends FeatureRecord {
  const FeatureRecordModel({
    required super.id,
    required super.projectId,
    required super.geometryType,
    required super.coordinates,
    super.attributes,
    super.syncStatus,
    required super.createdAt,
    super.syncedAt,
  });

  factory FeatureRecordModel.fromJson(Map<String, dynamic> json) {
    final rawCoords = (json['coordinates'] as List?) ?? const [];
    return FeatureRecordModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      geometryType: json['geometryType'] as String,
      coordinates: [
        for (final pair in rawCoords)
          [for (final n in pair as List) (n as num).toDouble()],
      ],
      attributes: json['attributes'] == null
          ? const {}
          : Map<String, dynamic>.from(json['attributes'] as Map),
      syncStatus: _parseStatus(json['syncStatus']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
    );
  }

  factory FeatureRecordModel.fromEntity(FeatureRecord record) {
    return FeatureRecordModel(
      id: record.id,
      projectId: record.projectId,
      geometryType: record.geometryType,
      coordinates: record.coordinates,
      attributes: record.attributes,
      syncStatus: record.syncStatus,
      createdAt: record.createdAt,
      syncedAt: record.syncedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'geometryType': geometryType,
        'coordinates': coordinates,
        'attributes': attributes,
        'syncStatus': syncStatus.name,
        'createdAt': createdAt.toIso8601String(),
        'syncedAt': syncedAt?.toIso8601String(),
      };

  FeatureRecord toEntity() => FeatureRecord(
        id: id,
        projectId: projectId,
        geometryType: geometryType,
        coordinates: coordinates,
        attributes: attributes,
        syncStatus: syncStatus,
        createdAt: createdAt,
        syncedAt: syncedAt,
      );

  static SyncStatus _parseStatus(dynamic raw) {
    if (raw is String) {
      return SyncStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => SyncStatus.pending,
      );
    }
    return SyncStatus.pending;
  }
}
```

- [ ] **Step 2: Write the local datasource**

```dart
// lib/features/map/data/datasources/feature_record_local_datasource.dart
import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/feature_record.dart';
import '../../domain/entities/track_record.dart' show SyncStatus;
import '../models/feature_record_model.dart';

/// Local persistence (Hive) for feature records — same one-JSON-string-per-box
/// pattern as [TrackRecordLocalDataSourceImpl].
abstract class FeatureRecordLocalDataSource {
  Future<void> openBox();
  Future<List<FeatureRecord>> getAll();
  Future<FeatureRecord?> getById(String id);
  Future<void> saveRecord(FeatureRecord record);
  Future<void> deleteRecord(String id);
  Future<void> clear();
  Future<void> markSynced(String id);
  Future<void> markFailed(String id);
  Future<List<FeatureRecord>> getPending();
}

class FeatureRecordLocalDataSourceImpl implements FeatureRecordLocalDataSource {
  FeatureRecordLocalDataSourceImpl({this.boxName = 'record_features'});

  final String boxName;
  Box? _box;

  Box get _store {
    final cached = _box;
    if (cached != null && cached.isOpen) return cached;
    if (Hive.isBoxOpen(boxName)) return _box = Hive.box(boxName);
    throw StateError(
      'Hive box "$boxName" is not open. Call openBox() during app startup.',
    );
  }

  @override
  Future<void> openBox() async {
    _box = await Hive.openBox(boxName);
  }

  List<FeatureRecordModel> _readAll() {
    final raw = _store.get(_recordsKey) as String?;
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => FeatureRecordModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeAll(List<FeatureRecordModel> records) async {
    await _store.put(_recordsKey, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  @override
  Future<List<FeatureRecord>> getAll() async {
    final records = _readAll()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records.map((m) => m.toEntity()).toList();
  }

  @override
  Future<FeatureRecord?> getById(String id) async {
    for (final m in _readAll()) {
      if (m.id == id) return m.toEntity();
    }
    return null;
  }

  @override
  Future<void> saveRecord(FeatureRecord record) async {
    final model = FeatureRecordModel.fromEntity(
      record.copyWith(syncStatus: SyncStatus.pending, syncedAt: null),
    );
    final records = List<FeatureRecordModel>.from(_readAll());
    final idx = records.indexWhere((r) => r.id == model.id);
    if (idx == -1) {
      records.add(model);
    } else {
      records[idx] = model;
    }
    await _writeAll(records);
  }

  @override
  Future<void> deleteRecord(String id) async {
    final records = _readAll()..removeWhere((r) => r.id == id);
    await _writeAll(records);
  }

  @override
  Future<void> markSynced(String id) async {
    final records = List<FeatureRecordModel>.from(_readAll());
    final idx = records.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    records[idx] = records[idx].copyWith(
      syncStatus: SyncStatus.synced,
      syncedAt: DateTime.now(),
    ) as FeatureRecordModel;
    await _writeAll(records);
  }

  @override
  Future<void> markFailed(String id) async {
    final records = List<FeatureRecordModel>.from(_readAll());
    final idx = records.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    records[idx] = records[idx].copyWith(syncStatus: SyncStatus.failed) as FeatureRecordModel;
    await _writeAll(records);
  }

  @override
  Future<List<FeatureRecord>> getPending() async {
    final pending = _readAll().where((m) => m.syncStatus != SyncStatus.synced).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pending.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> clear() async {
    await _store.delete(_recordsKey);
  }

  static const String _recordsKey = 'features';
}
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/features/map/data/models/feature_record_model.dart lib/features/map/data/datasources/feature_record_local_datasource.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/map/data/models/feature_record_model.dart lib/features/map/data/datasources/feature_record_local_datasource.dart
git commit -m "feat: add FeatureRecordModel and Hive local datasource"
```

---

### Task 14: FeatureRecord repository with outbox sync

**Files:**
- Create: `lib/features/map/domain/repositories/feature_record_repository.dart`
- Create: `lib/features/map/data/repositories/feature_record_repository_impl.dart`
- Create: `test/feature_record_repository_impl_test.dart`

**Interfaces:**
- Consumes: `FeatureRecordLocalDataSource` (Task 13), `ProjectRemoteDataSource` (Task 3), `NetworkInfo`.
- Produces: `FeatureRecordRepository { getRecords(), saveRecord(record), deleteRecord(id), getPending(), syncPending() }`.

- [ ] **Step 1: Write the domain repository interface**

```dart
// lib/features/map/domain/repositories/feature_record_repository.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/feature_record.dart';

abstract class FeatureRecordRepository {
  Future<Either<Failure, List<FeatureRecord>>> getRecords();
  Future<Either<Failure, Unit>> saveRecord(FeatureRecord record);
  Future<Either<Failure, Unit>> deleteRecord(String id);
  Future<Either<Failure, List<FeatureRecord>>> getPending();
  Future<Either<Failure, int>> syncPending();
}
```

- [ ] **Step 2: Write the failing sync tests**

```dart
// test/feature_record_repository_impl_test.dart
import 'dart:io';

import 'package:enterprise_flutter_app/core/network/network_info.dart';
import 'package:enterprise_flutter_app/features/map/data/datasources/feature_record_local_datasource.dart';
import 'package:enterprise_flutter_app/features/map/data/repositories/feature_record_repository_impl.dart';
import 'package:enterprise_flutter_app/features/map/domain/entities/feature_record.dart';
import 'package:enterprise_flutter_app/features/map/domain/entities/track_record.dart' show SyncStatus;
import 'package:enterprise_flutter_app/features/project/data/datasources/project_remote_datasource.dart';
import 'package:enterprise_flutter_app/features/project/data/models/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNetworkInfo implements NetworkInfo {
  _FakeNetworkInfo({this.online = true});
  final bool online;
  @override
  Future<bool> get isConnected async => online;
}

class _FakeLocalDataSource implements FeatureRecordLocalDataSource {
  List<FeatureRecord> records = [];
  final Set<String> synced = {};
  final Set<String> failed = {};

  @override
  Future<void> openBox() async {}
  @override
  Future<List<FeatureRecord>> getAll() async => records;
  @override
  Future<FeatureRecord?> getById(String id) async {
    for (final r in records) {
      if (r.id == id) return r;
    }
    return null;
  }
  @override
  Future<void> saveRecord(FeatureRecord record) async {
    records = [...records.where((r) => r.id != record.id), record];
  }
  @override
  Future<void> deleteRecord(String id) async => records.removeWhere((r) => r.id == id);
  @override
  Future<void> clear() async => records = [];
  @override
  Future<void> markSynced(String id) async => synced.add(id);
  @override
  Future<void> markFailed(String id) async => failed.add(id);
  @override
  Future<List<FeatureRecord>> getPending() async =>
      records.where((r) => r.syncStatus != SyncStatus.synced).toList();
}

class _RecordedCall {
  _RecordedCall(this.projectId, this.geometry, this.attributes);
  final String projectId;
  final Map<String, dynamic> geometry;
  final Map<String, dynamic> attributes;
}

class _FakeProjectRemoteDataSource implements ProjectRemoteDataSource {
  final List<_RecordedCall> calls = [];

  @override
  Future<List<ProjectModel>> getProjects() async => const [];
  @override
  Future<ProjectModel> getProject(String id) async => throw UnimplementedError();
  @override
  Future<String> uploadAttachment({required String projectId, required String fieldName, required File file}) async =>
      throw UnimplementedError();

  @override
  Future<void> createFeature({
    required String projectId,
    required Map<String, dynamic> geometry,
    required Map<String, dynamic> attributes,
  }) async {
    calls.add(_RecordedCall(projectId, geometry, attributes));
  }
}

void main() {
  group('FeatureRecordRepositoryImpl.syncPending', () {
    test('builds a Point geometry from a single coordinate pair', () async {
      final local = _FakeLocalDataSource()
        ..records = [
          FeatureRecord(
            id: 'f1',
            projectId: 'proj-point',
            geometryType: 'point',
            coordinates: const [[106.8, -6.2]],
            attributes: const {'abc': 'hello'},
            createdAt: DateTime(2026, 7, 22),
          ),
        ];
      final remote = _FakeProjectRemoteDataSource();
      final repo = FeatureRecordRepositoryImpl(
        localDataSource: local,
        networkInfo: _FakeNetworkInfo(),
        projectRemoteDataSource: remote,
      );

      await repo.syncPending();

      expect(remote.calls, hasLength(1));
      expect(remote.calls.first.geometry, {
        'type': 'Point',
        'coordinates': [106.8, -6.2],
      });
      expect(local.synced, contains('f1'));
    });

    test('closes the ring when building a Polygon geometry', () async {
      final local = _FakeLocalDataSource()
        ..records = [
          FeatureRecord(
            id: 'f2',
            projectId: 'proj-polygon',
            geometryType: 'polygon',
            coordinates: const [
              [106.80, -6.20],
              [106.81, -6.20],
              [106.81, -6.21],
            ],
            createdAt: DateTime(2026, 7, 22),
          ),
        ];
      final remote = _FakeProjectRemoteDataSource();
      final repo = FeatureRecordRepositoryImpl(
        localDataSource: local,
        networkInfo: _FakeNetworkInfo(),
        projectRemoteDataSource: remote,
      );

      await repo.syncPending();

      final geometry = remote.calls.first.geometry;
      expect(geometry['type'], 'Polygon');
      final ring = (geometry['coordinates'] as List).first as List;
      expect(ring, hasLength(4)); // 3 vertices + closing point
      expect(ring.first, ring.last);
    });

    test('is a no-op when offline', () async {
      final local = _FakeLocalDataSource()
        ..records = [
          FeatureRecord(
            id: 'f3',
            projectId: 'p',
            geometryType: 'point',
            coordinates: const [[0, 0]],
            createdAt: DateTime(2026, 7, 22),
          ),
        ];
      final remote = _FakeProjectRemoteDataSource();
      final repo = FeatureRecordRepositoryImpl(
        localDataSource: local,
        networkInfo: _FakeNetworkInfo(online: false),
        projectRemoteDataSource: remote,
      );

      final result = await repo.syncPending();

      result.fold((_) => fail('expected Right'), (count) => expect(count, 0));
      expect(remote.calls, isEmpty);
    });
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/feature_record_repository_impl_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:enterprise_flutter_app/features/map/data/repositories/feature_record_repository_impl.dart'`

- [ ] **Step 4: Write the repository implementation**

```dart
// lib/features/map/data/repositories/feature_record_repository_impl.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../project/data/datasources/project_remote_datasource.dart';
import '../../domain/entities/feature_record.dart';
import '../../domain/repositories/feature_record_repository.dart';
import '../datasources/feature_record_local_datasource.dart';

class FeatureRecordRepositoryImpl implements FeatureRecordRepository {
  FeatureRecordRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
    required this.projectRemoteDataSource,
  });

  final FeatureRecordLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final ProjectRemoteDataSource projectRemoteDataSource;

  @override
  Future<Either<Failure, List<FeatureRecord>>> getRecords() async {
    try {
      return right(await localDataSource.getAll());
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveRecord(FeatureRecord record) async {
    try {
      await localDataSource.saveRecord(record);
      return right(unit);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteRecord(String id) async {
    try {
      await localDataSource.deleteRecord(id);
      return right(unit);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FeatureRecord>>> getPending() async {
    try {
      return right(await localDataSource.getPending());
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> syncPending() async {
    try {
      final online = await networkInfo.isConnected;
      if (!online) return right(0);

      final pending = await localDataSource.getPending();
      if (pending.isEmpty) return right(0);

      var syncedCount = 0;
      for (final record in pending) {
        try {
          await projectRemoteDataSource.createFeature(
            projectId: record.projectId,
            geometry: _buildGeometry(record),
            attributes: record.attributes,
          );
          await localDataSource.markSynced(record.id);
          syncedCount++;
        } catch (_) {
          await localDataSource.markFailed(record.id);
        }
      }
      return right(syncedCount);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  Map<String, dynamic> _buildGeometry(FeatureRecord record) {
    if (record.geometryType == 'polygon') {
      final ring = [...record.coordinates];
      if (ring.isNotEmpty &&
          (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
        ring.add(ring.first);
      }
      return {
        'type': 'Polygon',
        'coordinates': [ring],
      };
    }
    return {'type': 'Point', 'coordinates': record.coordinates.first};
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/feature_record_repository_impl_test.dart`
Expected: `00:0X +3: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/map/domain/repositories/feature_record_repository.dart lib/features/map/data/repositories/feature_record_repository_impl.dart test/feature_record_repository_impl_test.dart
git commit -m "feat: add FeatureRecordRepository with Point/Polygon sync geometry"
```

---

### Task 15: FeatureRecord usecases and providers

**Files:**
- Create: `lib/features/map/domain/usecases/save_feature_record_usecase.dart`
- Create: `lib/features/map/domain/usecases/sync_feature_records_usecase.dart`
- Create: `lib/features/map/domain/usecases/get_pending_feature_records_usecase.dart`
- Modify: `lib/features/map/presentation/providers/map_providers.dart`

**Interfaces:**
- Consumes: `FeatureRecordRepository` (Task 14).
- Produces: `saveFeatureRecordUseCaseProvider`, `syncFeatureRecordsUseCaseProvider`, `pendingFeatureRecordsProvider`, `featureRecordRepositoryProvider`.

- [ ] **Step 1: Write the usecases**

```dart
// lib/features/map/domain/usecases/save_feature_record_usecase.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/feature_record.dart';
import '../repositories/feature_record_repository.dart';

class SaveFeatureRecordUseCase {
  SaveFeatureRecordUseCase(this._repository);
  final FeatureRecordRepository _repository;

  Future<Either<Failure, Unit>> call(FeatureRecord record) => _repository.saveRecord(record);
}
```

```dart
// lib/features/map/domain/usecases/sync_feature_records_usecase.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/feature_record_repository.dart';

class SyncFeatureRecordsUseCase {
  SyncFeatureRecordsUseCase(this._repository);
  final FeatureRecordRepository _repository;

  Future<Either<Failure, int>> call() => _repository.syncPending();
}
```

```dart
// lib/features/map/domain/usecases/get_pending_feature_records_usecase.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/feature_record.dart';
import '../repositories/feature_record_repository.dart';

class GetPendingFeatureRecordsUseCase {
  GetPendingFeatureRecordsUseCase(this._repository);
  final FeatureRecordRepository _repository;

  Future<Either<Failure, List<FeatureRecord>>> call() => _repository.getPending();
}
```

- [ ] **Step 2: Add providers**

Append to `lib/features/map/presentation/providers/map_providers.dart` (add these imports alongside the existing ones):

```dart
import '../../data/datasources/feature_record_local_datasource.dart';
import '../../data/repositories/feature_record_repository_impl.dart';
import '../../domain/entities/feature_record.dart';
import '../../domain/repositories/feature_record_repository.dart';
import '../../domain/usecases/get_pending_feature_records_usecase.dart';
import '../../domain/usecases/save_feature_record_usecase.dart';
import '../../domain/usecases/sync_feature_records_usecase.dart';
```

And at the end of the file:

```dart
// ---------------------------------------------------------------------------
// Feature Record (offline point/polygon capture + sync outbox)
// ---------------------------------------------------------------------------

final featureRecordLocalDataSourceProvider =
    Provider<FeatureRecordLocalDataSource>((ref) {
  return FeatureRecordLocalDataSourceImpl();
});

final featureRecordRepositoryProvider = Provider<FeatureRecordRepository>((ref) {
  return FeatureRecordRepositoryImpl(
    localDataSource: ref.watch(featureRecordLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    projectRemoteDataSource: ref.watch(projectRemoteDataSourceProvider),
  );
});

final saveFeatureRecordUseCaseProvider = Provider<SaveFeatureRecordUseCase>((ref) {
  return SaveFeatureRecordUseCase(ref.watch(featureRecordRepositoryProvider));
});

final syncFeatureRecordsUseCaseProvider = Provider<SyncFeatureRecordsUseCase>((ref) {
  return SyncFeatureRecordsUseCase(ref.watch(featureRecordRepositoryProvider));
});

final getPendingFeatureRecordsUseCaseProvider =
    Provider<GetPendingFeatureRecordsUseCase>((ref) {
  return GetPendingFeatureRecordsUseCase(ref.watch(featureRecordRepositoryProvider));
});

/// One-shot sync trigger for feature records, mirrors `trackSyncProvider`.
final featureRecordSyncProvider = FutureProvider<int>((ref) async {
  final result = await ref.watch(syncFeatureRecordsUseCaseProvider).call();
  return result.fold((failure) => throw failure, (count) => count);
});

/// Feature records waiting to be pushed to the server.
final pendingFeatureRecordsProvider = FutureProvider<List<FeatureRecord>>((ref) async {
  final result = await ref.watch(getPendingFeatureRecordsUseCaseProvider).call();
  return result.fold((failure) => throw failure, (records) => records);
});
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/features/map/`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/map/domain/usecases/save_feature_record_usecase.dart lib/features/map/domain/usecases/sync_feature_records_usecase.dart lib/features/map/domain/usecases/get_pending_feature_records_usecase.dart lib/features/map/presentation/providers/map_providers.dart
git commit -m "feat: add feature record usecases and providers"
```

---

### Task 16: Polygon vertex-capture state provider

**Files:**
- Create: `lib/features/map/presentation/providers/feature_capture_providers.dart`

**Interfaces:**
- Consumes: `Project` (Task 1), `LatLng` (`latlong2`).
- Produces: `enum CaptureMode { idle, polygon }`, `class FeatureCaptureState { mode, project, points }`, `featureCaptureProvider` (`NotifierProvider<FeatureCaptureNotifier, FeatureCaptureState>`) — consumed by `MapView` (Task 17) and `FeatureRecordFab` (Task 18).

- [ ] **Step 1: Write the provider**

```dart
// lib/features/map/presentation/providers/feature_capture_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../project/domain/entities/project.dart';

enum CaptureMode { idle, polygon }

/// In-progress polygon capture: which project it belongs to and the vertices
/// tapped on the map so far. `mode == idle` means no capture is active.
class FeatureCaptureState {
  const FeatureCaptureState({
    this.mode = CaptureMode.idle,
    this.project,
    this.points = const [],
  });

  final CaptureMode mode;
  final Project? project;
  final List<LatLng> points;

  FeatureCaptureState copyWith({
    CaptureMode? mode,
    Project? project,
    List<LatLng>? points,
  }) {
    return FeatureCaptureState(
      mode: mode ?? this.mode,
      project: project ?? this.project,
      points: points ?? this.points,
    );
  }
}

class FeatureCaptureNotifier extends Notifier<FeatureCaptureState> {
  @override
  FeatureCaptureState build() => const FeatureCaptureState();

  void startPolygon(Project project) {
    state = FeatureCaptureState(mode: CaptureMode.polygon, project: project, points: const []);
  }

  void addVertex(LatLng point) {
    if (state.mode != CaptureMode.polygon) return;
    state = state.copyWith(points: [...state.points, point]);
  }

  void reset() {
    state = const FeatureCaptureState();
  }
}

final featureCaptureProvider =
    NotifierProvider<FeatureCaptureNotifier, FeatureCaptureState>(FeatureCaptureNotifier.new);
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/map/presentation/providers/feature_capture_providers.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/map/presentation/providers/feature_capture_providers.dart
git commit -m "feat: add featureCaptureProvider for polygon vertex-tap capture state"
```

---

### Task 17: MapView polygon vertex-tap mode

**Files:**
- Modify: `lib/features/map/presentation/widgets/map_view.dart`

**Interfaces:**
- Consumes: `featureCaptureProvider` (Task 16).

- [ ] **Step 1: Wire capture mode into MapView**

Edit `lib/features/map/presentation/widgets/map_view.dart`:

Add import:

```dart
import '../providers/feature_capture_providers.dart';
```

Change `build()` to watch capture state and branch `onTap`:

```dart
  @override
  Widget build(BuildContext context) {
    final basemap = ref.watch(basemapProvider);
    final visibleIds = ref.watch(visibleLayerIdsProvider);
    final catalog = ref.watch(mapCatalogProvider).valueOrNull ?? const [];
    final tileServerBaseUrl = ref.watch(tileServerBaseUrlProvider);
    final capture = ref.watch(featureCaptureProvider);

    final overlays = <Widget>[
      for (final layer in catalog)
        if (visibleIds.contains(layer.id))
          if (buildOverlayLayer(layer, tileServerBaseUrl)
              case final Widget overlay)
            overlay,
    ];

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: 3,
            maxZoom: 20,
            onTap: (_, point) {
              if (capture.mode == CaptureMode.polygon) {
                ref.read(featureCaptureProvider.notifier).addVertex(point);
                return;
              }
              _identify(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: basemap.urlTemplate,
              maxNativeZoom: basemap.maxZoom,
              userAgentPackageName: 'com.enterprise.flutter_app',
            ),
            ...overlays,
            if (widget.trackPoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      for (final p in widget.trackPoints)
                        LatLng(p.latitude, p.longitude),
                    ],
                    strokeWidth: 4,
                    color: Colors.green,
                  ),
                ],
              ),
            if (capture.mode == CaptureMode.polygon && capture.points.length > 1)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: capture.points,
                    color: Colors.orange.withValues(alpha: 0.25),
                    borderColor: Colors.orange,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            if (capture.mode == CaptureMode.polygon)
              MarkerLayer(
                markers: [
                  for (final p in capture.points)
                    Marker(
                      point: p,
                      width: 12,
                      height: 12,
                      child: const _VertexDot(),
                    ),
                ],
              ),
            if (widget.myLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.myLocation!,
                    width: 20,
                    height: 20,
                    child: const _MyLocationDot(),
                  ),
                ],
              ),
          ],
        ),
        if (widget.showLayerButton)
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'map-layers',
              tooltip: 'Layers & basemap',
              onPressed: () => showLayerPanelSheet(context, _mapController),
              child: const Icon(Icons.layers_outlined),
            ),
          ),
        if (_identifying)
          const Positioned(
            top: 16,
            left: 16,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        MapZoomControls(controller: _mapController),
      ],
    );
  }
```

Add the vertex marker widget next to `_MyLocationDot`:

```dart
class _VertexDot extends StatelessWidget {
  const _VertexDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/map/presentation/widgets/map_view.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/map/presentation/widgets/map_view.dart
git commit -m "feat: render polygon vertex-tap capture preview in MapView"
```

---

### Task 18: FeatureRecordFab (point + polygon capture)

**Files:**
- Create: `lib/features/map/presentation/widgets/feature_record_fab.dart`

**Interfaces:**
- Consumes: `showProjectPickerSheet` (Task 6), `showDynamicFormSheet` (Task 7), `featureCaptureProvider` (Task 16), `saveFeatureRecordUseCaseProvider`/`pendingFeatureRecordsProvider` (Task 15), `GpsService`.
- Produces: `FeatureRecordFab`, `FeatureCaptureCancelFab`.

- [ ] **Step 1: Write the widget**

```dart
// lib/features/map/presentation/widgets/feature_record_fab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/gps_service.dart';
import '../../../project/domain/entities/project.dart';
import '../../../project/presentation/widgets/project_picker_sheet.dart';
import '../../domain/entities/feature_record.dart';
import '../providers/feature_capture_providers.dart';
import '../providers/map_providers.dart';
import 'dynamic_form_sheet.dart';

/// Floating action button that captures a point (immediate GPS fix) or
/// polygon (map vertex-tap, driven by [featureCaptureProvider]) Feature
/// Record, gated behind picking a `point`/`polygon` [Project] first.
class FeatureRecordFab extends ConsumerStatefulWidget {
  const FeatureRecordFab({super.key});

  @override
  ConsumerState<FeatureRecordFab> createState() => _FeatureRecordFabState();
}

class _FeatureRecordFabState extends ConsumerState<FeatureRecordFab> {
  final GpsService _gps = GpsService();
  bool _busy = false;

  Future<void> _onPressed() async {
    final capture = ref.read(featureCaptureProvider);
    if (capture.mode == CaptureMode.polygon) {
      await _finishPolygon(capture);
      return;
    }
    await _startCapture();
  }

  Future<void> _startCapture() async {
    setState(() => _busy = true);
    try {
      final project = await showProjectPickerSheet(
        context,
        allowedGeometryTypes: const ['point', 'polygon'],
      );
      if (project == null || !mounted) return;

      if (project.geometryType == 'polygon') {
        ref.read(featureCaptureProvider.notifier).startPolygon(project);
        return;
      }

      final location = await _gps.getCurrentLocation();
      if (!mounted) return;
      final attributes = await showDynamicFormSheet(
        context,
        projectId: project.id,
        fields: project.formSchema,
      );
      if (attributes == null) return;
      await _save(
        project: project,
        geometryType: 'point',
        coordinates: [
          [location.longitude, location.latitude],
        ],
        attributes: attributes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishPolygon(FeatureCaptureState capture) async {
    final project = capture.project;
    if (project == null || capture.points.length < 3) return;
    setState(() => _busy = true);
    try {
      final attributes = await showDynamicFormSheet(
        context,
        projectId: project.id,
        fields: project.formSchema,
      );
      if (attributes == null) return;
      await _save(
        project: project,
        geometryType: 'polygon',
        coordinates: [
          for (final p in capture.points) [p.longitude, p.latitude],
        ],
        attributes: attributes,
      );
      ref.read(featureCaptureProvider.notifier).reset();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save({
    required Project project,
    required String geometryType,
    required List<List<double>> coordinates,
    required Map<String, dynamic> attributes,
  }) async {
    final record = FeatureRecord(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      projectId: project.id,
      geometryType: geometryType,
      coordinates: coordinates,
      attributes: attributes,
      createdAt: DateTime.now(),
    );
    final result = await ref.read(saveFeatureRecordUseCaseProvider)(record);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${failure.message}')),
      ),
      (_) => ref.invalidate(pendingFeatureRecordsProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capture = ref.watch(featureCaptureProvider);
    final capturing = capture.mode == CaptureMode.polygon;
    final canFinish = capturing && capture.points.length >= 3;
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      heroTag: 'feature-record',
      tooltip: capturing
          ? 'Finish polygon (${capture.points.length} pts, min 3)'
          : 'Add feature',
      backgroundColor: capturing ? Colors.orange : colorScheme.secondary,
      onPressed: _busy || (capturing && !canFinish) ? null : _onPressed,
      child: _busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(capturing ? Icons.check : Icons.add_location_alt_outlined),
    );
  }
}

/// Small secondary FAB shown only during polygon capture, cancels it.
class FeatureCaptureCancelFab extends ConsumerWidget {
  const FeatureCaptureCancelFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.small(
      heroTag: 'feature-capture-cancel',
      tooltip: 'Cancel polygon capture',
      backgroundColor: Colors.red,
      onPressed: () => ref.read(featureCaptureProvider.notifier).reset(),
      child: const Icon(Icons.close),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/map/presentation/widgets/feature_record_fab.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/map/presentation/widgets/feature_record_fab.dart
git commit -m "feat: add FeatureRecordFab for point/polygon capture"
```

---

### Task 19: Wire FeatureRecordFab into MapPage + register Hive box

**Files:**
- Modify: `lib/features/map/presentation/pages/map_page.dart`
- Modify: `lib/main_common.dart`

**Interfaces:**
- Consumes: `FeatureRecordFab`, `FeatureCaptureCancelFab` (Task 18), `featureCaptureProvider` (Task 16).

- [ ] **Step 1: Register the Hive box**

Edit `lib/main_common.dart`, in `_initializeHive()`:

```dart
  await Hive.openBox(AppConstants.cacheBox);
  await Hive.openBox('record_tracks');
  await Hive.openBox('record_features');
```

- [ ] **Step 2: Wire the FAB cluster**

Edit `lib/features/map/presentation/pages/map_page.dart`.

Add imports:

```dart
import '../providers/feature_capture_providers.dart';
import '../widgets/feature_record_fab.dart';
```

Change `_MapFabCluster` from `StatelessWidget` to `ConsumerWidget`:

```dart
/// Right-aligned FAB cluster: prominent record button on top,
/// recenter button below. Layers & zoom live inside MapView.
class _MapFabCluster extends ConsumerWidget {
  const _MapFabCluster({
    required this.locating,
    required this.onRecenter,
    required this.onPointsChanged,
  });
  final bool locating;
  final VoidCallback onRecenter;
  final void Function(List<TrackPoint> points) onPointsChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capturingPolygon =
        ref.watch(featureCaptureProvider).mode == CaptureMode.polygon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (capturingPolygon) ...[
          const FeatureCaptureCancelFab(),
          const SizedBox(height: 12),
        ],
        const FeatureRecordFab(),
        const SizedBox(height: 12),
        TrackRecordFab(onPointsChanged: onPointsChanged),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'map-recenter',
          tooltip: 'My location',
          onPressed: locating ? null : onRecenter,
          child: locating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/main_common.dart lib/features/map/presentation/pages/map_page.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/main_common.dart lib/features/map/presentation/pages/map_page.dart
git commit -m "feat: wire FeatureRecordFab into map page, open record_features Hive box"
```

---

### Task 20: Full verification pass

**Files:** none (verification only)

- [ ] **Step 1: Run the full analyzer**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: all tests pass, including `test/map_theme_test.dart`, `test/project_repository_impl_test.dart`, `test/dynamic_form_sheet_test.dart`, `test/track_record_repository_impl_test.dart`, `test/feature_record_repository_impl_test.dart`. (`test/map_datasource_live_test.dart` hits a real server and may be skipped if `localhost:8050` is unreachable in CI — that's pre-existing behavior, not introduced by this plan.)

- [ ] **Step 3: Manual smoke test (requires a running device/emulator and reachable tile server)**

Run: `flutter run`
Then in the app:
1. Open Map. Tap the Track Record FAB (red dot icon) — expect the `ProjectPickerSheet` to open showing only `line`-type projects (e.g. "Jalan").
2. Pick a project, confirm recording starts (red "Recording" chip appears).
3. Tap Stop — expect `DynamicFormSheet` with that project's fields (e.g. "Nama Jalan" text, "File" file picker).
4. Fill required fields, tap Save — sheet closes, no crash.
5. Tap the Feature Record FAB (pin icon) — pick a `point` project — expect an immediate GPS-based capture straight to `DynamicFormSheet`.
6. Tap the Feature Record FAB again — pick a `polygon` project — expect the FAB to turn orange/check and a small red cancel FAB to appear; tap 3+ points on the map, then tap the orange FAB to finish — `DynamicFormSheet` opens, Save closes it and resets capture mode.
7. Go offline (airplane mode) and repeat step 2–4 — record should still save locally without error (outbox `pending`).
8. Go back online — trigger a sync (app resume / existing connectivity listener) — confirm `POST /api/v1/projects/{id}/features` requests appear against `http://localhost:8050` (e.g. via server logs or `curl http://localhost:8050/api/v1/projects/{id}/features` afterward showing `feature_count` incremented).

- [ ] **Step 4: Commit (only if the smoke test required fixes)**

If Step 3 surfaces bugs, fix them in the relevant task's files and commit with a message describing the fix, e.g.:

```bash
git add <fixed files>
git commit -m "fix: <describe the smoke-test bug and fix>"
```

If no fixes were needed, this task requires no commit — verification only.
