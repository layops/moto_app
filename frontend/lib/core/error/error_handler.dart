import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/color_schemes.dart';

class AppError {
  final String message;
  final String? code;
  final dynamic details;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    this.code,
    this.details,
    this.stackTrace,
  });

  factory AppError.fromException(dynamic exception) {
    if (exception is AppError) {
      return exception;
    }

    String message = 'Beklenmeyen bir hata oluştu';
    String? code;

    if (exception.toString().contains('SocketException')) {
      message = 'İnternet bağlantınızı kontrol edin';
      code = 'NETWORK_ERROR';
    } else if (exception.toString().contains('TimeoutException')) {
      message = 'İstek zaman aşımına uğradı';
      code = 'TIMEOUT_ERROR';
    } else if (exception.toString().contains('FormatException')) {
      message = 'Veri formatı hatası';
      code = 'FORMAT_ERROR';
    } else if (exception.toString().contains('Unauthorized')) {
      message = 'Oturum süreniz dolmuş, lütfen tekrar giriş yapın';
      code = 'AUTH_ERROR';
    } else if (exception.toString().contains('Forbidden')) {
      message = 'Bu işlem için yetkiniz bulunmuyor';
      code = 'PERMISSION_ERROR';
    } else if (exception.toString().contains('NotFound')) {
      message = 'Aradığınız kaynak bulunamadı';
      code = 'NOT_FOUND_ERROR';
    }

    return AppError(
      message: message,
      code: code,
      details: exception.toString(),
    );
  }

  @override
  String toString() => message;
}

class ErrorHandler {
  static void handleError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    final appError = AppError.fromException(error);
    
    // Log error for debugging
    debugPrint('Error: ${appError.message}');
    debugPrint('Code: ${appError.code}');
    debugPrint('Details: ${appError.details}');
    
    // Show error dialog
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: appError,
        customMessage: customMessage,
        onRetry: onRetry,
      ),
    );
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppColorSchemes.errorColor,
        duration: duration,
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppColorSchemes.successColor,
      duration: duration,
    );
  }

  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: AppColorSchemes.warningColor,
      duration: duration,
    );
  }
}

class ErrorDialog extends StatelessWidget {
  final AppError error;
  final String? customMessage;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.error,
    this.customMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColorSchemes.errorColor,
            size: 28.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Hata',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColorSchemes.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customMessage ?? error.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (error.code != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColorSchemes.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Hata Kodu: ${error.code}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColorSchemes.errorColor,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: Text(
              'Tekrar Dene',
              style: TextStyle(
                color: AppColorSchemes.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Tamam',
            style: TextStyle(
              color: AppColorSchemes.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class ErrorWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final String? customMessage;

  const ErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.w,
              color: AppColorSchemes.errorColor,
            ),
            SizedBox(height: 16.h),
            Text(
              customMessage ?? error.message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (error.code != null) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColorSchemes.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hata Kodu: ${error.code}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColorSchemes.errorColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorSchemes.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColorSchemes.primaryColor,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            SizedBox(height: 16.h),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64.w,
              color: AppColorSchemes.textTertiary,
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColorSchemes.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorSchemes.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
