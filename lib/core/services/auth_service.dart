import 'package:injectable/injectable.dart';
import '../../core/auth/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/usecase.dart';

@lazySingleton
class AuthService {
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthService(this.getCurrentUserUseCase);

  /// Get current user ID, returns empty string if not authenticated
  Future<String> getCurrentUserId() async {
    final result = await getCurrentUserUseCase(const NoParams());
    return result.fold((_) => '', (user) => user?.id ?? '');
  }
}
