import 'package:hosts_manage/views/about/about_page.dart';
import 'package:hosts_manage/views/dns/dns_page.dart';
import 'package:hosts_manage/views/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:hosts_manage/views/settings/settings_page.dart';

final routes = <String, WidgetBuilder>{
  // 首页
  '/home': (_) => HomePage(),
  // 本地DNS代理
  '/dns': (_) => DNSPage(),
  // 语言
  '/settings': (_) => SettingsPage(),
  // 关于
  '/about': (_) => AboutPage(),
};
