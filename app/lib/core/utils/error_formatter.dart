import 'package:flare_app/core/error/exceptions.dart';

class ErrorFormatter {
  static String format(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';
    
    if (error is AppException) {
      return error.message;
    }

    final strError = error.toString().toLowerCase();

    // Legacy string matching for third-party or unmapped errors
    if (strError.contains('dioexception') || strError.contains('socketexception') || strError.contains('connection refused')) {
      return 'We are having trouble connecting to the server. Please check your internet connection.';
    }
    
    if (strError.contains('user not found')) {
      return 'We couldn\'t verify your account details. Please log in again.';
    }

    if (strError.contains('cannot toggle watcher in status: error')) {
      return 'This agent encountered an unrecoverable error and cannot be toggled right now. Please delete and recreate it if this persists.';
    }

    if (strError.contains('insufficient') || strError.contains('balance')) {
      return 'Insufficient funds to complete this action. Please check your wallet.';
    }

    if (strError.contains('unauthorized') || strError.contains('401')) {
      return 'Your session has expired. Please log in again.';
    }
    
    if (strError.contains('500')) {
      return 'Our servers are experiencing a temporary hiccup. Please try again later.';
    }

    // Default catch-all that cleans up generic exception text
    final cleanMessage = error.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '');
    return 'Something went wrong: $cleanMessage';
  }
}
