import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghost_app/services/api_service.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final ApiService apiService;

  WalletBloc(this.apiService) : super(WalletInitial()) {
    on<LoadWallet>((event, emit) async {
      emit(WalletLoading());
      try {
        final wallet = await apiService.getWallet(event.userId);
        if (state is WalletLoaded) {
          emit(WalletLoaded(
            wallet: wallet,
            stats: (state as WalletLoaded).stats,
            transactions: (state as WalletLoaded).transactions,
          ));
        } else {
          emit(WalletLoaded(wallet: wallet));
        }
      } catch (e) {
        emit(WalletError(e.toString()));
      }
    });

    on<LoadWalletStats>((event, emit) async {
      emit(WalletLoading());
      try {
        final stats = await apiService.getWalletStats(event.userId);
        if (state is WalletLoaded) {
          emit(WalletLoaded(
            wallet: (state as WalletLoaded).wallet,
            stats: stats,
            transactions: (state as WalletLoaded).transactions,
          ));
        } else {
          emit(WalletLoaded(stats: stats));
        }
      } catch (e) {
        emit(WalletError(e.toString()));
      }
    });

    on<LoadTransactions>((event, emit) async {
      emit(WalletLoading());
      try {
        final transactions = await apiService.getTransactions(
          event.userId,
          limit: event.limit,
          offset: event.offset,
        );
        if (state is WalletLoaded) {
          emit(WalletLoaded(
            wallet: (state as WalletLoaded).wallet,
            stats: (state as WalletLoaded).stats,
            transactions: transactions,
          ));
        } else {
          emit(WalletLoaded(transactions: transactions));
        }
      } catch (e) {
        emit(WalletError(e.toString()));
      }
    });
  }
}
