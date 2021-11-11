import 'package:hosts_manage/views/about/about_page.dart';
import 'package:hosts_manage/views/dns/dns_page.dart';
import 'package:hosts_manage/views/home/home_page.dart';

import 'package:flutter/material.dart';
import 'package:hosts_manage/views/lang/lang_page.dart';
import 'package:hosts_manage/views/theme/theme_page.dart';

final routes = <String, WidgetBuilder>{
  // 首页
  '/home': (_) => HomePage(),
  // 本地DNS代理
  '/dns': (_) => DNSPage(),
  // 主题
  '/theme': (_) => ThemePage(),
  // 语言
  '/lang': (_) => LangPage(),
  // 关于
  '/about': (_) => AboutPage(),
};
