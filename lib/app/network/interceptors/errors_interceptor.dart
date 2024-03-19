import 'package:l10n_breeds/app/breeds_ui.dart';
import 'package:network_breeds/app/network/error_format.dart';
import 'package:network_breeds/app/network/http_client.dart';
import 'package:utils_breeds/utils/preferences.dart';
import 'package:utils_breeds/utils/toast.dart';

class ErrorsInterceptor extends Interceptor {
  final Preferences prefs;
  ErrorsInterceptor(this.prefs);

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      var showMessage = true;
      const key = 'showMessage';
      final traceId = prefs.traceId;

      if (err.requestOptions.extra.containsKey(key)) {
        showMessage = err.requestOptions.extra[key] ?? true;
      }

      if (!showMessage) {
        return super.onError(err, handler);
      }

      final method = err.requestOptions.method.toUpperCase();
      final isMethodValid = method == 'POST' || method == 'PATCH';
      final statusCode = err.response?.statusCode ?? 0;

      if ((statusCode == 400 || statusCode == 422) && isMethodValid) {
        final message = err.response?.data['message'];
        final errors = err.response?.data['errors'];

        if (errors != null) {
          ProTToast.showShortError(
            format422Errors(errors ?? []),
          );
          return super.onError(err, handler);
        }

        if (message != null) {
          ProTToast.showShortError(message);
          return super.onError(err, handler);
        }

        final list = err.response?.data;

        if ((list is List?) && (list?.isNotEmpty ?? false)) {
          ProTToast.showShortError(
            err.response?.data.first ?? '',
          );
          return super.onError(err, handler);
        }
      }

      if (statusCode >= 500 && isMethodValid && showMessage) {
        ProTToast.showShortError(
          BreedUiValues.weHaveAErrorContactSuport(traceId),
        );
      }
    } catch (_) {}
    return super.onError(err, handler);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    try {
      final msDio = Modular.get<XigoHttpClient>().msDio;
      msDio.options.extra['showMessage'] = true;
      response.extra['showMessage'] = true;
    } catch (_) {}

    return super.onResponse(response, handler);
  }
}
