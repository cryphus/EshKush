import 'dart:html' as html;

Map<String, String> _parseFragmentParams(String fragment) {
  if (fragment.isEmpty) return <String, String>{};
  try {
    return Uri.splitQueryString(fragment);
  } catch (_) {
    return <String, String>{};
  }
}

void cleanupOAuthParamsFromUrl() {
  final uri = Uri.base;
  final updatedQuery = Map<String, String>.from(uri.queryParameters);
  final originalFragment = _parseFragmentParams(uri.fragment);
  final fragmentParams = Map<String, String>.from(originalFragment);

  updatedQuery.remove('access_token');
  updatedQuery.remove('refresh_token');
  updatedQuery.remove('oauth_error');

  fragmentParams.remove('access_token');
  fragmentParams.remove('refresh_token');
  fragmentParams.remove('oauth_error');

  final queryChanged = updatedQuery.length != uri.queryParameters.length;
  final fragmentChanged = fragmentParams.length != originalFragment.length;
  if (!queryChanged && !fragmentChanged) return;

  final cleaned = uri.replace(
    queryParameters: updatedQuery.isEmpty ? null : updatedQuery,
    fragment: fragmentParams.isEmpty ? null : Uri(queryParameters: fragmentParams).query,
  );
  html.window.history.replaceState(null, '', cleaned.toString());
}
