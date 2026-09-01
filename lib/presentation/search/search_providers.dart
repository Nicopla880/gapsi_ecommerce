import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'search_notifier.dart';
import 'search_state.dart';

export 'search_dependencies.dart' show searchHistoryProvider;

final NotifierProvider<SearchNotifier, SearchState> searchNotifierProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
