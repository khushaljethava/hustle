import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _ratesKey = 'currency_rates_json';
  static const String _ratesFetchedAtKey = 'currency_rates_fetched_at';
  static const Duration _cacheTtl = Duration(hours: 4);

  final SharedPreferences _prefs;
  Map<String, double> _rates = {'USD': 1.0};

  CurrencyService(this._prefs) {
    _loadCachedRates();
  }

  Map<String, double> get rates => Map.unmodifiable(_rates);

  /// Convert [amount] from [from] currency to [to] currency using cached rates.
  /// Falls back to the original amount if rates are unavailable.
  double convert(double amount, String from, String to) {
    if (from == to) return amount;
    final fromRate = _rates[from] ?? 1.0;
    final toRate = _rates[to] ?? 1.0;
    return (amount / fromRate) * toRate;
  }

  void _loadCachedRates() {
    final cached = _prefs.getString(_ratesKey);
    if (cached == null) return;
    try {
      final map = json.decode(cached) as Map<String, dynamic>;
      _rates = map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {}
  }

  /// Fetch latest rates from frankfurter.app (free, no API key required).
  /// Uses cached rates if they are still within [_cacheTtl].
  Future<void> fetchRates({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final fetchedAt = _prefs.getInt(_ratesFetchedAtKey);
      if (fetchedAt != null && _rates.length > 1) {
        final age = DateTime.now().millisecondsSinceEpoch - fetchedAt;
        if (age < _cacheTtl.inMilliseconds) return;
      }
    }
    try {
      final response = await http
          .get(Uri.parse('https://api.frankfurter.app/latest?base=USD'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final fetched = (data['rates'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        fetched['USD'] = 1.0;
        _rates = fetched;
        await _prefs.setString(_ratesKey, json.encode(_rates));
        await _prefs.setInt(
          _ratesFetchedAtKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (_) {}
  }
}
