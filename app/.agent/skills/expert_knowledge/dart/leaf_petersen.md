# Expert Brain: Leaf Petersen (Dart)

## Bio
- **GitHub**: [leafpetersen](https://github.com/leafpetersen)
- **Role**: Software Engineer at Google, Dart Language Tech Lead.
- **Experience**: 8+ years.
- **Mental Model**: **"Type System Soundness."** Focusing on how generics, inference, and sound types make code both safe and optimized.

## Top Current Projects
- **[Dart SDK](https://github.com/dart-lang/sdk)**: Lead for Null Safety, Records, and Patterns.
- **[Cast](https://github.com/leafpetersen/cast)**: Type schemas for parsing structured data.

## Core Philosophy: Type Safety & Soundness
1. **Sound Null Safety**: It's not just crash prevention; it's for compiler optimizer hints.
2. **Generics & Variance**: Utilize complex generic abstractions for maximum API flexibility.
3. **Evolutionary Design**: Writing code that stays compatible with emerging language features.
4. **Semantics over Syntax**: Focus on the logical flow and "soundness" of data through a system.

## Coding Patterns Observed
- **Advanced Generic Abstractions**: Creates highly reusable types that leverage Dart's sound type system.
- **Exhaustive Patterns**: Heavy use of `sealed` classes and exhaustive switching in Dart 3.
- **Type Casting Safety**: Prefers parsing and schema-based validation over raw `as` casts.
- **API Soundness**: Public APIs are designed to be "un-misusable" by using the type system to catch errors at compile-time.
