# Flutter Development Skill

## Overview
Guidelines for building high-performance, maintainable, and beautiful Flutter applications using modern best practices and expert philosophies.

## Core Architecture: Clean Architecture
- **Presentation Layer**: 
  - **UIs**: Follow the [UI Development Skill](../ui_development/SKILL.md) for Figma-perfect designs.
  - **State Management**: Use [Bloc for Verifier](../state_management/SKILL.md#bloc) and [Provider for Transporter](../state_management/SKILL.md#provider).
- **Domain Layer**: Contains entities, use cases, and repository interfaces. No external dependencies here.
- **Data Layer**: Repositories, data sources (Dio/Hive), and models (DTOs). Use [API Handling Best Practices](../api_handling/SKILL.md).

## Advanced Quality & Performance
- **Testing**: Follow the [Testing Strategy Skill](../testing/SKILL.md) for every new feature.
- **Performance**: Consult the [Performance & Speed Skill](../performance/SKILL.md) to ensure 60 FPS and fast startup.
- **Observability**: Ensure all critical flows and errors are tracked using the [Observability & Analytics Skill](../observability/SKILL.md).
- **Expert Mentorship**: For complex architectural decisions, refer to the [Expert Knowledge Brains](../expert_knowledge/SKILL.md).

## UI Standardization
- **Component-Based**: Divide every screen into small, readable widgets.
- **Reusable Core**: Always check `lib/core/widgets/` before building a new component.
- **Responsiveness**: Use `flutter_screenutil` exclusively for all sizing.
- **Clean UI**: Follow "Clean Dart and Flutter" principles.

## Navigation & Routing
- Use **GoRouter** for declarative routing.
- Prefer named routes and pass parameters through the router state object.

## Best Practices
- Use `const` constructors everywhere possible to reduce unnecessary builds.
- Minimize `setState` by using Blocs and Providers.
- Perform heavy computation in Isolates or using `compute`.
