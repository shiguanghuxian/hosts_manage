import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:macos_ui/macos_ui.dart';

// 语言切换
class LangPage extends StatefulWidget {
  const LangPage({
    Key key,
  }) : super(key: key);

  @override
  _LangPageState createState() => _LangPageState();
}

class _LangPageState extends State<LangPage> {
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
        titleBar: TitleBar(
          title: Text(lang.get('lang.title')),
        ),
        children: [
          ContentArea(builder: (context, scrollController) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              controller: scrollController,
              child: Container(
                child: const Text('语言'),
              ),
            );
          }),
        ],
        // floatingActionButton: HomePublishBtn(),// 这里可放设置按钮
      );
    });
  }
}
