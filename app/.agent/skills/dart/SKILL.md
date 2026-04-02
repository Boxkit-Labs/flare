# Dart Development Skill

## Overview
Guidelines for writing clean, efficient, and professional Dart code, aligning with the latest Dart SDK (3.x) and best practices.

## Core Principles
1. **Sound Null Safety**: Always use null-safe code. Avoid the `!` operator unless absolutely certain. Use `?` and `??` for safe handling.
2. **Effective Async**: Prefer `async/await` over raw `Future` chains. Use `Future.wait` for parallel tasks.
3. **Strong Typing**: Avoid `dynamic`. Use specific types or generics (`T`) to ensure compile-time safety.
4. **Consistency**: Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).

## Key Patterns
- **Extension Methods**: Use extensions to add functionality to existing types (e.g., `String` validation, `DateTime` formatting).
- **Records & Patterns**: Utilize Dart 3 records for multiple return values and pattern matching for concise logic.
- **Mixins**: Use mixins for reusable behavior across classes without inheritance.

## Best Practices
- Use `final` for variables that don't change.
- Use `const` for compile-time constants (widgets, values).
- Follow the `lowerCamelCase` for variables and `UpperCamelCase` for classes.
- Use `_` for private members.
- Document public APIs with `///` doc comments.
