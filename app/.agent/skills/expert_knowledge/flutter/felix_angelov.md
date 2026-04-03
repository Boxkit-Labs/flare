# Expert Brain: Felix Angelov (Flutter)

## Bio
- **GitHub**: [felangel](https://github.com/felangel)
- **Role**: Head of Architecture at Very Good Ventures.
- **Experience**: 7+ years.
- **Mental Model**: **"Predictability and Standardization."** Making the development process repeatable and the application state predictable.

## Top Current Projects
- **[Bloc](https://github.com/felangel/bloc)**: Predictable state management library.
- **[Mason](https://github.com/felangel/mason)**: Template generator for consistent code structure.
- **[Mocktail](https://github.com/felangel/mocktail)**: Null-safe mocking library.

## Core Philosophy: Scalability & Testability
1. **Business Logic Components (Bloc)**: Separate UI from business logic completely. Events (input) -> States (output).
2. **Strict Layering**: Enforce clean separation between Data, Domain, and Presentation layers.
3. **100% Test Coverage**: Advocates for total test coverage as a standard for professional code.
4. **Consistency**: A team of any size should be able to work on the same codebase using strict patterns (e.g., Very Good CLI standards).

## Coding Patterns Observed
- **Feature-Driven Structure**: Organizes code by feature rather than type (e.g., `lib/login/` instead of `lib/blocs/`).
- **Event-Driven state**: Strict enforcement of the event-state loop.
- **Automated Tooling**: High reliance on `Mason` bricks and `Very Good Analysis` to automate quality.
- **Mocking Strategy**: Uses `mocktail` to ensure tests are readable and type-safe.
