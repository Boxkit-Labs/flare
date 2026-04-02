# Observability & Analytics Skill

## Overview
Guidelines for professional application monitoring, error reporting, and user analytics using **Sentry** and **Mixpanel**.

## Error Reporting: Sentry
- **Error Boundaries**: Every `main()` or `runApp()` should be wrapped in `SentryFlutter.init()`.
- **Manual Capture**: Use `Sentry.captureException(e, stackTrace: stackTrace)` for caught errors that shouldn't crash the app but need attention.
- **Breadcrumbs**: Add breadcrumbs for significant lifecycle events or user actions to make debugging easier (e.g., `Sentry.addBreadcrumb(message: 'User started checkout')`).
- **Context**: Always attach user IDs (anonymized if necessary) and relevant tags (e.g., `feature_area: 'payments'`) to reports.

## User Analytics: Mixpanel
- **Event Naming**: Use `Title Case` for event names (e.g., `User Login`, `Checkout Completed`).
- **Properties**: Include relevant metadata in every event (e.g., `price`, `item_count`, `source_screen`).
- **User Identity**: Call `mixpanel.identify(userId)` and `mixpanel.getPeople().set(...)` after a successful login to track user properties over time.
- **Initialization**: Ensure Mixpanel is initialized early and only once.

## Best Practices
- **Privacy**: Never track sensitive user data like passwords, credit card numbers, or PII (Personally Identifiable Information) without encryption/anonymization.
- **Consistency**: Use the `MixpanelService` and `SentryService` wrappers to ensure events are logged correctly across all features.
- **Release Tracking**: Ensure the app version and build number are correctly attached to all observability data.
