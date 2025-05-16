import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAuthStore implements AuthStore {
  static const String _tokenKey = 'pb_auth_token';
  static const String _modelKey = 'pb_auth_model';
  
  final SharedPreferences _prefs;
  String _token = '';
  RecordModel? _model;
  final _onChange = Stream<AuthStoreEvent>.empty();

  SharedPreferencesAuthStore(this._prefs) {
    // Load saved token and model on initialization
    final savedToken = _prefs.getString(_tokenKey);
    final savedModelString = _prefs.getString(_modelKey);

    if (savedToken != null) {
      _token = savedToken;
    }

    if (savedModelString != null) {
      try {
        final modelData = json.decode(savedModelString) as Map<String, dynamic>;
        _model = RecordModel.fromJson(modelData);
      } catch (e) {
        print('Error loading saved auth model: $e');
      }
    }
  }

  @override
  String get token => _token;

  @override
  RecordModel? get model => _model;

  @override
  bool get isValid => token.isNotEmpty;

  @override
  Stream<AuthStoreEvent> get onChange => _onChange;

  @override
  void save(String newToken, [dynamic newModel]) {
    _token = newToken;
    _model = newModel as RecordModel?;
    
    // Save token
    if (newToken.isNotEmpty) {
      _prefs.setString(_tokenKey, newToken);
    } else {
      _prefs.remove(_tokenKey);
    }

    // Save model
    if (newModel != null) {
      final modelJson = json.encode((newModel).toJson());
      _prefs.setString(_modelKey, modelJson);
    } else {
      _prefs.remove(_modelKey);
    }
  }

  @override
  void clear() {
    _token = '';
    _model = null;
    _prefs.remove(_tokenKey);
    _prefs.remove(_modelKey);
  }
} 