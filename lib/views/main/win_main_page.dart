import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/about/about_page.dart';
import 'package:hosts_manage/views/dns/dns_page.dart';
import 'package:hosts_manage/views/home/home_page.dart';
import 'package:hosts_manage/views/settings/settings_page.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class WinMainPage extends StatefulWidget {
  const WinMainPage({Key key}) : super(key: key);

  @override
  _WinMainPageState createState() => _WinMainPageState();
}

class _WinMainPageState extends State<WinMainPage> {
  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 左侧菜单
  bool isOpen = true;

  // 当前显示页面
  int pageIndex = 0;

  final List<Widget> pages = [
    const HomePage(),
    const DNSPage(),
    const SettingsPage(),
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(builder: (context, store) {
      I18N lang = StoreProvider.of<ZState>(context).state.lang;
      if (lang == null) {
        return Container();
      }

      return NavigationView(
        pane: NavigationPane(
          selected: pageIndex,
          onChanged: (i) => setState(() => pageIndex = i),
          displayMode: isOpen ? PaneDisplayMode.open : PaneDisplayMode.compact,
          menuButton: SizedBox(
            width: 44,
            height: 44,
            child: InkWell(
              onTap: () {
                setState(() {
                  isOpen = !isOpen;
                });
              },
              child: Icon(
                isOpen ? Icons.menu_open : Icons.menu,
                size: 25,
              ),
            ),
          ),
          items: [
            PaneItem(
              title: Text(lang.get('home.title')),
              icon: const Icon(
                CupertinoIcons.home,
                size: 18,
              ),
              // autofocus: true,
            ),
            PaneItem(
              title: Text(lang.get('dns.title')),
              icon: const Icon(
                CupertinoIcons.personalhotspot,
                size: 18,
              ),
            ),
            PaneItem(
              title: Text(lang.get('settings.title')),
              icon: const Icon(
                CupertinoIcons.settings,
                size: 18,
              ),
            ),
            PaneItem(
              title: Text(lang.get('about.title')),
              icon: const Icon(
                CupertinoIcons.umbrella,
                size: 18,
              ),
            ),
          ],
          footerItems: [
            PaneItemHeader(
              header: MacosTooltip(
                message: '点击查看作者开源主页',
                child: MacosListTile(
                  onClick: () {
                    launch('https://github.com/shiguanghuxian');
                  },
                  leading: const MacosIcon(CupertinoIcons.profile_circled),
                  title: const Text('时光弧线'),
                  subtitle: const Text('zuoxiupeng@live.com'),
                ),
              ),
            ),
          ],
        ),
        content: NavigationBody(
          index: pageIndex,
          children: pages,
        ),
      );
    });
  }
}
