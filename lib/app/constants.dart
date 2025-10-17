import 'package:flutter/foundation.dart';

printValue(value) {
  if (kDebugMode) {
    print(
      " \n<================================\n $value \n=========================>\n\n",
    );
  }
}
