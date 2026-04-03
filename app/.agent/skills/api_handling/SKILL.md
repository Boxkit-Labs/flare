# API Handling Skill

## Overview
Guidelines for professional API integration using **Dio**, **Dartz**, and Clean Architecture repositories.

## Network Client: Dio
- **Interceptors**: Use interceptors for:
  - Adding Auth Tokens (JWT) to headers.
  - Logging requests and responses (using `Logger`).
  - Handling 401 Unauthorized globally (session expired).
- **Configuration**: Use `BaseOptions` for timeout and base URL based on the environment.

## Error Handling: Dartz (Either)
- Repositories should return `Either<Failure, SuccessType>`.
- **Failure**: A custom class containing an error message and code.
- **Implementation**:
  ```dart
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final response = await dio.post('/login', data: {...});
      return Right(User.fromJson(response.data));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
  ```

## Data Transformation (Serialization)
- Use `factory Model.fromJson(Map<String, dynamic> json)` for deserialization.
- Use `Map<String, dynamic> toJson()` for serialization.
- Consider using `json_serializable` for complex models.

## Best Practices
- **No Direct API calls in UI**: All requests must go through a Repository.
- **Secure Storage**: Sensitive data (tokens) must be stored in `FlutterSecureStorage` or `Hive` (encrypted).
- **Environment Aware**: Use `AppConfig` to switch between Staging and Production URLs.
- **Timeout**: Always set a reasonable connect/receive timeout (e.g., 30 seconds).
