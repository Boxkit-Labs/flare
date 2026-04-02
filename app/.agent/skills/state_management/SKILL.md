# State Management Skill

## Overview
Guidelines for managing state using **Bloc (Business Logic Component)** and **Provider**.

## Feature-Specific Guidelines
To maintain consistency across the project, follow these specific assignments:
- **Verifier Features**: Must use **Bloc**. This allows for a strict event-driven approach suitable for audit and verification flows.
- **Transporter Features**: Must use **Provider / ChangeNotifier**. This provides a simpler, more reactive flow for transporter-related updates.

## Bloc (Business Logic Component)
- **Files**: Each feature should have its own folder with `_bloc.dart`, `_event.dart`, and `_state.dart`.
- **States**: Use `Equatable` to ensure efficient UI rebuilds.
- **Pattern**:
  - `Initial`: The starting state.
  - `Loading`: When an async operation is in progress.
  - `Success`: When data is retrieved or action completed.
  - `Failure`: When an error occurs (include an error message).

## Provider / ChangeNotifier
- Use **Provider** for global app state (e.g., `AppViewModel`, `AuthenticationStatus`).
- Use `context.read<T>()` for actions (inside buttons/listeners).
- Use `context.watch<T>()` or `Consumer<T>` for UI rebuilds.

## Best Practices
- Never put UI code (BuildContext) inside Blocs or ViewModels.
- Dispose of controllers and subscriptions in the `close()` (Bloc) or `dispose()` (ChangeNotifier) methods.
- Use `BlocListener` for side effects (navigation, snackbars) and `BlocBuilder` for UI updates.
