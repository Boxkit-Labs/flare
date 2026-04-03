# Testing Strategy Skill

## Overview
Guidelines for maintaining high code quality through a robust testing strategy, including Unit, Widget, and Integration tests.

## Unit Testing (Business Logic)
- **What to Test**: All Repositories, Use Cases, Blocs, and ViewModels.
- **Mocking**: Use `mocktail` or `mockito` to mock external dependencies (e.g., `Dio`, `Hive`, `AuthService`).
- **Pattern**: Follow the **Arrange-Act-Assert** pattern.
- **Coverage**: Aim for 100% logic coverage in the Domain and Data layers.

## Widget Testing (UI)
- **What to Test**: Reusable components and critical UI flows (e.g., Login form validation).
- **Golden Tests**: Use for pixel-perfect UI verification if Figma matching is critical across updates.
- **Interactions**: Test button taps, text input, and scrolling behavior.

## Integration Testing (Full Flow)
- **What to Test**: End-to-end user journeys (e.g., Successful booking flow from splash to confirmation).
- **Environment**: Run on real devices or emulators using `flutter_test` or `integration_test` package.

## Clean Testing Principles
1. **Isolation**: Tests should not depend on each other. Ensure a clean state before every test.
2. **Readability**: Test names should be descriptive (e.g., `should return User when login is successful`).
3. **DRY Tests**: Use `setUp` and `tearDown` to manage common test resources.
4. **Maintenance**: If a test fails after a code change, update the test or fix the bug—never delete the test just to pass the build.

## Best Practices
- Run `flutter test` before every commit.
- Use `equatable` for state classes to make assertions easier.
- Modularize test files to match the `lib/` directory structure.
