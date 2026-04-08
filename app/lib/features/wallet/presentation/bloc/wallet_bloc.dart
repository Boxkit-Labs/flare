import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flare_app/services/api_service.dart';
import 'package:flare_app/core/models/models.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';
import 'package:flare_app/core/utils/error_formatter.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final ApiService apiService;

  WalletBloc(this.apiService) : super(WalletInitial()) {
    on<LoadAllWalletData>((event, emit) async {
      if (!event.isRefresh) emit(WalletLoading());
      try {
        final responses = await Future.wait([
          apiService.getWallet(event.userId),
          apiService.getWalletStats(event.userId),
          apiService.getTransactions(event.userId, limit: 20, offset: 0),
        ]);
        emit(WalletLoaded(
          wallet: responses[0] as WalletModel,
          stats: responses[1] as SpendingStatsModel,
          transactions: responses[2] as List<TransactionModel>,
        ));
      } catch (e) {
        emit(WalletError(ErrorFormatter.format(e)));
      }
    });

    on<FundWalletUser>((event, emit) async {
       if (state is WalletLoaded) {
         emit(WalletLoaded(
            wallet: (state as WalletLoaded).wallet,
            stats: (state as WalletLoaded).stats,
            transactions: (state as WalletLoaded).transactions,
            isFunding: true,
         ));
       } else {
         emit(WalletLoading());
       }
       try {
         await apiService.fundWallet(event.userId);
         add(LoadAllWalletData(event.userId, isRefresh: true));
       } catch (e) {
         emit(WalletError(e.toString()));
       }
    });
  }
}
