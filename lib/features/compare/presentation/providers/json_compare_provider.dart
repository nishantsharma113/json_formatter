import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/json_compare_utils.dart';

class _CompareParams {
  final String textA;
  final String textB;
  _CompareParams(this.textA, this.textB);
}

SideBySideDiff _isolateCompare(_CompareParams params) {
  return JsonCompareUtils.compare(params.textA, params.textB);
}

class JsonCompareState {
  final String jsonA;
  final String jsonB;
  final SideBySideDiff? diffResult;
  final bool isLoading;

  JsonCompareState({
    required this.jsonA,
    required this.jsonB,
    this.diffResult,
    required this.isLoading,
  });

  factory JsonCompareState.initial() {
    return JsonCompareState(
      jsonA: '',
      jsonB: '',
      diffResult: null,
      isLoading: false,
    );
  }

  JsonCompareState copyWith({
    String? jsonA,
    String? jsonB,
    SideBySideDiff? diffResult,
    bool? isLoading,
  }) {
    return JsonCompareState(
      jsonA: jsonA ?? this.jsonA,
      jsonB: jsonB ?? this.jsonB,
      diffResult: diffResult ?? this.diffResult,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class JsonCompareNotifier extends Notifier<JsonCompareState> {
  @override
  JsonCompareState build() {
    return JsonCompareState.initial();
  }

  void updateJsonA(String val) {
    state = state.copyWith(jsonA: val);
    compare();
  }

  void updateJsonB(String val) {
    state = state.copyWith(jsonB: val);
    compare();
  }

  Future<void> compare() async {
    final textA = state.jsonA;
    final textB = state.jsonB;

    if (textA.trim().isEmpty && textB.trim().isEmpty) {
      state = state.copyWith(diffResult: null);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final diff = await compute(
        _isolateCompare,
        _CompareParams(textA, textB),
      );
      state = state.copyWith(diffResult: diff, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void clear() {
    state = JsonCompareState.initial();
  }
}

final jsonCompareProvider = NotifierProvider<JsonCompareNotifier, JsonCompareState>(() {
  return JsonCompareNotifier();
});
