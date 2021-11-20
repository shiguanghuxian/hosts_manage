import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:url_launcher/url_launcher.dart';

// 关于
class AboutPage extends StatefulWidget {
  const AboutPage({
    Key key,
  }) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(builder: (context, store) {
      I18N lang = StoreProvider.of<ZState>(context).state.lang;
      return MacosScaffold(
        titleBar: Platform.isWindows
            ? null
            : TitleBar(
                title: Text(lang.get('about.title')),
              ),
        children: [
          ContentArea(builder: (context, scrollController) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                  top: 20, bottom: 20, left: 50, right: 50),
              controller: scrollController,
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      child: Text(
                        'hosts文件管理软件',
                        style: MacosTheme.of(context).typography.title2,
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 10, bottom: 5),
                      child: Text(
                        '1. 支持将多个hosts配置组合为一个文件写入系统hosts文件。',
                        style: MacosTheme.of(context).typography.body,
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 5, bottom: 5),
                      child: Text(
                        '2. 支持以(1)所述组合的hosts代理DNS服务，可用于手机和其它人共享一份hosts配置。',
                        style: MacosTheme.of(context).typography.body,
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(top: 5, bottom: 5),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Text(
                                '3. 开源地址：',
                                style: MacosTheme.of(context).typography.body,
                              ),
                            ),
                            WidgetSpan(
                              child: InkWell(
                                onTap: () {
                                  launch(
                                      'https://github.com/shiguanghuxian/hosts_manage');
                                },
                                child: Text(
                                  'https://github.com/shiguanghuxian/hosts_manage',
                                  style: TextStyle(
                                    color: MacosTheme.of(context).primaryColor,
                                    fontSize: MacosTheme.of(context)
                                        .typography
                                        .body
                                        .fontSize,
                                  ),
                                ),
                              ),
                            ),
                            WidgetSpan(
                              child: Text(
                                ' 喜欢的话点个小星星。',
                                style: MacosTheme.of(context).typography.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}
