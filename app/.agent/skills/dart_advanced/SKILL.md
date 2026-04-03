# Dart DSA & Documentation Skill

## Overview
Guidelines for implementing efficient Data Structures and Algorithms (DSA) and producing professional technical documentation using Dart's unique features.

## Dart DSA Principles
Writing efficient code is critical for mobile performance. Choose the right collection and algorithm for the task:

- **Collection Choice**:
  - **List**: Use for ordered elements requiring index access. Use `List.generate` or `List.filled` for pre-allocation.
  - **Set**: Use for unique collections and fast lookups ($O(1)$).
  - **Map**: Use for key-value pair lookups ($O(1)$).
  - **Queue**: Use `DoubleLinkedQueue` for efficient FIFO/LIFO operations.
- **Complexity Awareness**:
  - Avoid nested loops over large collections ($O(n^2)$). Use Maps or Sets to reduce complexity to $O(n)$ where possible.
  - Use `Iterable` methods (`map`, `where`, `every`, `any`) for clean and often lazy-evaluated filtering.
- **Memory Management**:
  - Use `Uint8List` for binary data.
  - Avoid creating new collections in `build()` methods for UI.

## Dart Documentation Principles
Professional documentation is essential for maintainability. Use Dart's doc-comment system:

- **Triple-Slash Docs**: Use `///` for documentation comments. Avoid `/** ... */`.
- **First-Line Summary**: The first sentence should be a concise summary of what the class or method does.
- **Link Reference**: Use square brackets `[class_name]` or `[method_name]` to create links within the documentation.
- **Parameters & Returns**:
  - Describe parameters using a clear, sentence-style format.
  - Explicitly mention what a method returns and if it can return `null`.
- **Code Examples**: Use markdown code blocks within doc comments for usage examples:
  ```dart
  /// Adds two numbers.
  /// 
  /// Returns the sum of [a] and [b].
  /// Example:
  /// ```dart
  /// final sum = add(2, 3); // 5
  /// ```
  int add(int a, int b) => a + b;
  ```
- **Templates**: Use `{@template name}` and `{@macro name}` for repetitive documentation blocks (e.g., across multiple constructors).

## Clean Dart Principles
- **Self-Documenting Code**: Choose descriptive names so that doc comments only need to explain "why," not "what."
- **Consistency**: All public classes, methods, and extensions MUST be documented.
