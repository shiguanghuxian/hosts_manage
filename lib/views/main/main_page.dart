import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/about/about_page.dart';
import 'package:hosts_manage/views/dns/dns_page.dart';
import 'package:hosts_manage/views/home/home_page.dart';
import 'package:hosts_manage/views/lang/lang_page.dart';
import 'package:hosts_manage/views/theme/theme_page.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 当前显示页面
  int pageIndex = 0;

  final List<IndexedStackChild> pages = [
    IndexedStackChild(
      child: const HomePage(),
    ),
    IndexedStackChild(
      child: const DNSPage(),
    ),
    IndexedStackChild(
      child: const ThemePage(),
    ),
    IndexedStackChild(
      child: const LangPage(),
    ),
    IndexedStackChild(
      child: const AboutPage(),
    ),
  ];

  Color textLuminance(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(builder: (context, store) {
      I18N lang = StoreProvider.of<ZState>(context).state.lang;

      return MacosWindow(
        child: ProsteIndexedStack(
          index: pageIndex,
          children: pages,
        ),
        sidebar: Sidebar(
          minWidth: 180,
          bottom: const Padding(
            padding: EdgeInsets.all(16.0),
            child: MacosListTile(
              leading: MacosIcon(CupertinoIcons.profile_circled),
              title: Text('时光弧线'),
              subtitle: Text('zuoxiupeng@live.com'),
            ),
          ),
          builder: (context, controller) {
            return SidebarItems(
              currentIndex: pageIndex,
              onChanged: (i) => setState(() => pageIndex = i),
              scrollController: controller,
              items: [
                SidebarItem(
                  leading: MacosIcon(
                    CupertinoIcons.home,
                    color: MacosTheme.of(context).typography.title1.color,
                  ),
                  label: Text(lang.get('home.title')),
                ),
                SidebarItem(
                  leading: MacosIcon(
                    CupertinoIcons.personalhotspot,
                    color: MacosTheme.of(context).typography.title1.color,
                  ),
                  label: Text(lang.get('dns.title')),
                ),
                SidebarItem(
                  leading: MacosIcon(
                    // Icons.auto_graph_sharp
                    CupertinoIcons.rectangle_on_rectangle,
                    color: MacosTheme.of(context).typography.title1.color,
                  ),
                  label: Text(lang.get('theme.title')),
                ),
                SidebarItem(
                  leading: MacosIcon(
                    CupertinoIcons.textformat_abc,
                    color: MacosTheme.of(context).typography.title1.color,
                  ),
                  label: Text(lang.get('lang.title')),
                ),
                SidebarItem(
                  leading: MacosIcon(
                    CupertinoIcons.umbrella,
                    color: MacosTheme.of(context).typography.title1.color,
                  ),
                  label: Text(lang.get('about.title')),
                ),
              ],
            );
          },
        ),
      );
    });
  }
}
