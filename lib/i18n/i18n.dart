import 'dart:convert';
import 'package:flutter/services.dart';

class I18N {
  Map data = new Map<String, dynamic>();
  Map defaultData = new Map<String, dynamic>();

  // 初始化数据
  init(String locale) async {
    // 设置的语言
    String filename;
    if (locale == "zh") {
      filename = "lib/assets/locale/zh.json";
    } else {
      filename = "lib/assets/locale/en.json";
    }
    String jsonStr = await rootBundle.loadString(filename);
    // final jsonStr = new File(filename).readAsStringSync();
    data = json.decode(jsonStr);
    // 默认语言
    String jsonStrDefault = await rootBundle.loadString('lib/assets/locale/en.json');// new File("assets/locale/en.json").readAsStringSync();
    defaultData = json.decode(jsonStrDefault);
  }

  // 获取对应语言值 . 分隔
  String get(String key) {
    List<String> keys = key.split(".");
    int len = keys?.length;
    if (len == 0) {
      return "😂";
    }
    String val = '';
    if (len == 1) {
      val = data[keys[0]] ?? '';
    } else {
      dynamic val1 = data[keys[0]] ?? null;
      if (val1 != null) {
        val = val1[keys[1]] ?? '';
      }
    }
    if (val == '') {
      if (len == 1) {
        val = defaultData[keys[0]] ?? '';
      } else {
        Map val1 = defaultData[keys[0]] ?? null;
        if (val1 != null) {
          val = val1[keys[1]] ?? '';
        }
      }
    }
    return val;
  }
}
