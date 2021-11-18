import "dart:ffi";
import "dart:convert";
import 'package:ffi/ffi.dart';

class GoString extends Struct {
  Pointer<Uint8> string;

  @IntPtr()
  int length;

  String toString() {
    List<int> units = [];
    for (int i = 0; i < length; ++i) {
      units.add(string.elementAt(i).value);
    }
    return Utf8Decoder().convert(units);
  }

  static Pointer<GoString> fromString(String string) {
    List<int> units = Utf8Encoder().convert(string);
    final ptr = malloc<Uint8>(units.length);
    for (int i = 0; i < units.length; ++i) {
      ptr.elementAt(i).value = units[i];
    }
    Pointer<GoString> goPtr = malloc<GoString>();
    final GoString str = goPtr.ref;
    str.length = units.length;
    str.string = ptr;
    return goPtr;
  }
}
