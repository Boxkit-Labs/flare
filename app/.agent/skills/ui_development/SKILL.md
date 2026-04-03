# UI Development Skill

## Overview
Guidelines for building pixel-perfect, maintainable, and high-performance Flutter UIs that perfectly match Figma designs.

## Figma to UI: Pixel-Perfect Standards
- **Precise Layouts**: Use `flutter_screenutil` (e.g., `.w`, `.h`, `.sp`, `.r`) for all dimensions to ensure the UI scale is consistent with Figma layouts.
- **Typography**: Strictly follow Figma's font weight, size, and letter spacing. All text styles should be defined in `AppTheme.dart`.
- **Colors**: Never use hardcoded colors. Use `AppColors` derived from the Figma design system.
- **Spacing**: Use `SizedBox(width: 8.w)` or `SizedBox(height: 16.h)` for margins/padding between elements.

## Flutter Widget Documentation: The Gold Standard
To ensure the highest quality and architectural alignment, ALWAYS follow the [official Flutter Widget Documentation](https://api.flutter.dev/).

- **Canonical Usage**: Before using a new or complex widget (e.g., `CustomScrollView`, `SliverAppBar`, `InheritedWidget`), consult the API documentation to understand its "canonical" usage and avoid anti-patterns.
- **Widget of the Week / Recipes**: Refer to [Flutter Cookbook](https://docs.flutter.dev/cookbook) and "Widget of the Week" for the most efficient ways to solve common UI challenges.
- **Constraints & Layout**: Strictly follow the [Flutter Layout Principles](https://docs.flutter.dev/ui/layout/constraints) ("Constraints go down. Sizes go up. Parent sets position.").
- **Best-in-Class Implementation**: When the agent builds a UI, it MUST ensure that the implementation matches the architectural excellence suggested by the Flutter team.

## Component-Based Architecture
- **Divide and Conquer**: Break down complex pages into smaller, manageable components (widgets).
- **Readability**: If a widget exceeds 100-150 lines, extract its parts into smaller, private `_Widget` classes within the same file or a `widgets/` folder.
- **Internal Modularity**: Group sub-widgets that are specific to a page within a `widgets/` sub-folder of that feature.

## Reusable Widgets (DRY Principle)
- **Avoid Repetition**: If a UI pattern appears more than once, create a reusable widget in `lib/core/widgets/`.
- **Common Components**: Standardize buttons, inputs, loaders, and headers.
- **Parameters**: Use constructor parameters to support different variations of a reusable widget rather than duplicating code.

## Best UI Packages
Utilize high-quality, updated packages to speed up development and improve quality:
- **Styling**: `flutter_screenutil` for responsiveness.
- **SVGs**: `flutter_svg` for clean vector graphics.
- **Animations**: `flutter_animate` or `Lottie` for premium micro-interactions.
- **Icons**: `font_awesome_flutter` or custom icons from Figma.
- **Images**: `cached_network_image` for smooth image loading.
- **Forms**: `flutter_form_builder` for complex form management.

## Clean UI Principles
1. **Separation of Concerns**: Keep UI files focused on layout. Business logic must live in Blocs/ViewModels.
2. **Encapsulation**: Private sub-widgets (`_MyWidget`) should be used for components that aren't intended for global use.
3. **Consistency**: Use a consistent naming convention (e.g., `feature_name_page.dart` and `feature_name_widget.dart`).
