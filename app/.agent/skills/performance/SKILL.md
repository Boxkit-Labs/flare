# Performance & Speed Skill

## Overview
Guidelines for building specialized, high-performance Flutter applications with smooth animations and lightning-fast execution.

## 1. Animation Performance (The 60 FPS Rule)
- **Repaint Boundaries**: Use `RepaintBoundary` around complex animations or widgets that update frequently to isolate their paint cycles.
- **AnimationController Optimization**: Only use `AnimationController` with `AnimatedBuilder` or `Listener` if the whole subtree needs to rebuild. Use specialized widgets like `SlideTransition` or `FadeTransition` for better performance.
- **Avoid Opacity/Clip in Loops**: Never use `Opacity` or `Clip` inside lists or heavy animations. Use `AnimatedOpacity` or draw with semi-transparent colors instead.
- **TickerProvider**: Always use `SingleTickerProviderStateMixin` for local animations and ensure they are disposed of correctly.

## 2. Widget Rebuild Optimization
- **Const Constructors**: Use `const` everywhere possible to avoid unnecessary rebuilds of static subtrees.
- **Partial Rebuilds**: Use `BlocBuilder(buildWhen: ...)` or `context.select()` to only rebuild the exact parts of the UI that changed.
- **Small Widgets**: Break large widgets into small, stateless components to minimize the scope of rebuilds.

## 3. List & Scroll Performance
- **Builder Pattern**: Always use `ListView.builder` or `GridView.builder` for lists with more than 10-20 items.
- **ItemExtent**: Specify `itemExtent` if all items have the same height. This allows the scroll view to calculate its size without building every item.
- **Slivers**: Use `CustomScrollView` and `Slivers` for complex scrolling effects to ensure they run on the GPU.

## 4. App Speed & Startup
- **Lazy Loading**: Don't initialize all services in `main()`. Use `get_it`'s lazy singletons for services that aren't needed immediately.
- **Image Optimization**:
  - Use `cached_network_image`.
  - Provide `cacheWidth` and `cacheHeight` to avoid decoding images larger than their display size.
  - Use WebP format for assets.
- **Heavy Computation**: Move CPU-intensive tasks (JSON parsing of large files, data sorting) to an **Isolate** or use `compute`.

## 5. Performance Profiling
- **Flutter DevTools**: Regularly use the **Performance view** to identify jank and the **CPU Profiler** to find slow methods.
- **Raster Cache**: Check if images are being cached correctly in the GPU memory.
