# Expert Brain: Remi Rousselet (Flutter)

## Bio
- **GitHub**: [rrousselGit](https://github.com/rrousselGit)
- **Role**: Independent Open Source Developer, Flutter GDE.
- **Experience**: 8+ years.
- **Mental Model**: **"Compile-time safety and Immutability first."** Pushing logic into the compile-time phase via code generation to eliminate runtime errors.

## Top Current Projects
- **[Riverpod](https://github.com/rrousselGit/riverpod)**: A reactive caching and data-binding framework.
- **[Freezed](https://github.com/rrousselGit/freezed)**: Code generation for immutable classes and unions.
- **[Flutter Hooks](https://github.com/rrousselGit/flutter_hooks)**: React-style hooks for Flutter.

## Core Philosophy: Reactive & Immutable
1. **Immutability is King**: Use `Freezed` for every state, model, and event. Immutable values make state management predictable.
2. **Reactivity**: Prefer `Riverpod` for "pull-based" reactivity where widgets watch only exactly what they need.
3. **Minimize Build Context**: Logic should be testable independently of `BuildContext`.
4. **Declarative UI**: The UI is a pure function of the state. `UI = f(state)`.

## Coding Patterns Observed
- **Strict Static Analysis**: Enforces explicit types and safety using 200+ custom lint rules.
- **Functional Paradigms**: Heavy use of `computed` state and pattern matching via `Freezed`.
- **Internal Organization**: High usage of `part` and `part of` to keep public APIs clean while organizing large internal logic.
- **Documentation**: Extensive use of `///` documentation for every public member.
