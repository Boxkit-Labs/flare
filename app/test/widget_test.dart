import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flare_app/app.dart';
import 'package:flare_app/injection_container.dart' as di;
import 'package:flare_app/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  setUp(() async {
    final sl = GetIt.instance;
    await sl.reset();
    await di.init();
  });

  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthBloc>(
        create: (context) => di.sl<AuthBloc>(),
        child: const FlareApp(),
      ),
    );

    // Verify the home screen placeholder renders.
    expect(find.text('Home'), findsWidgets);
  });
}
