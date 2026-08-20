import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/config.dart';

/// Callback path Supabase uses to return from the OAuth flow.
/// Must match AuthService.signInWithGoogle's `redirectTo`.
/// Google Cloud Console requires an HTTPS redirect URI for Web OAuth clients,
/// so we use the Supabase server callback URL and intercept it in the WebView.
const String kSupabaseOAuthScheme = 'io.supabase.flutter';
String get kSupabaseCallbackUrl => '${AppConfig.supabaseUrl}/auth/v1/callback';

/// In-app Google sign-in page.
///
/// Shows Supabase's hosted Google OAuth page inside a WebView so the user
/// never leaves the app (no Chrome / browser redirect). When Google finishes,
/// Supabase redirects to `io.supabase.flutter://callback?...` — we intercept
/// that navigation and pop this page with the full callback [Uri], which the
/// caller feeds to `auth.getSessionFromUrl(...)` to complete the PKCE login.
class GoogleOAuthWebViewPage extends StatefulWidget {
  const GoogleOAuthWebViewPage({super.key, required this.initialUrl});

  final String initialUrl;

  @override
  State<GoogleOAuthWebViewPage> createState() => _GoogleOAuthWebViewPageState();
}

class _GoogleOAuthWebViewPageState extends State<GoogleOAuthWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            // Intercept the custom-scheme redirect Supabase sends after
            // completing the PKCE token exchange with Google.
            if (url.startsWith('$kSupabaseOAuthScheme://')) {
              Navigator.of(context).pop(Uri.parse(url));
              return NavigationDecision.prevent;
            }
            // Stay inside the app for every step of the OAuth page.
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) async {
            if (mounted) setState(() => _loading = false);
            await _checkForSupabaseErrorPage();
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _failed = true;
                _errorMessage = _friendlyError(error);
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _retry() {
    setState(() {
      _failed = false;
      _loading = true;
    });
    _controller.loadRequest(Uri.parse(widget.initialUrl));
  }

  /// Detects Supabase's JSON error pages (e.g. the Google provider missing
  /// its OAuth secret) and replaces them with a clear, actionable message.
  Future<void> _checkForSupabaseErrorPage() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'document.body ? document.body.innerText : ""',
      );
      final text = result.toString();
      if (text.contains('missing OAuth secret') ||
          text.contains('Unsupported provider') ||
          text.contains('validation_failed')) {
        if (mounted) {
          setState(() {
            _failed = true;
            _errorMessage = 'Google sign-in is not fully set up yet.\n\n'
                'Supabase needs the Google Client secret. Add it in '
                'Supabase → Authentication → Providers → Google, then tap '
                'Try Again.';
          });
        }
      }
    } on Object catch (_) {
      // Best-effort page inspection; ignore failures.
    }
  }

  /// Translates raw WebView errors into something a user can act on.
  String _friendlyError(WebResourceError error) {
    final desc = error.description;
    final isNetworkIssue =
        error.errorType == WebResourceErrorType.hostLookup ||
            error.errorType == WebResourceErrorType.connect ||
            error.errorType == WebResourceErrorType.timeout ||
            desc.contains('NAME_NOT_RESOLVED') ||
            desc.contains('INTERNET_DISCONNECTED') ||
            desc.contains('TIMED_OUT') ||
            desc.contains('CONNECTION');
    if (isNetworkIssue) {
      return 'Could not reach the sign-in server.\n\n'
          'Check your internet connection (try switching between Wi-Fi '
          'and mobile data) and tap Try Again.';
    }
    return desc.isNotEmpty
        ? desc
        : 'Could not load the sign-in page. Tap Try Again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.of(context).continueWithGoogle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_failed)
            _ErrorView(message: _errorMessage, onRetry: _retry)
          else
            WebViewWidget(controller: _controller),
          if (_loading && !_failed)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
