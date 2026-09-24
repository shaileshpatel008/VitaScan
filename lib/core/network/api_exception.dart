import '../constants/app_strings.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromStatus(int? code, String? serverMessage) {
    if (code == null) return const ApiException(AppStrings.noInternet);
    return switch (code) {
      400 => ApiException(serverMessage ?? 'The request was not valid.', statusCode: code),
      401 || 403 => ApiException('Please sign in again.', statusCode: code),
      404 => ApiException('We couldn\'t find what you asked for.', statusCode: code),
      >= 500 => ApiException('Our server is having trouble. Please try later.', statusCode: code),
      _ => ApiException(serverMessage ?? AppStrings.somethingWrong, statusCode: code),
    };
  }

  @override
  String toString() => message;
}
