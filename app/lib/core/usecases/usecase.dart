import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:ghost_app/core/error/failure.dart';

/// Base class for all domain use cases.
///
/// [Type] is what the use case returns.
/// [Params] is what is passed to the use case.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
