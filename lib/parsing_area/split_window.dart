import 'package:flutter/material.dart';
import 'package:model_maker/parsing_settings/parsing_settings_model.dart';
import 'package:model_maker/parsing_area/json_model_generator/json_model_generator.dart';
import 'package:model_maker/parsing_area/debouncer.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:model_maker/parsing_area/json_model_generator/json_format_utils.dart';

/// 分体窗口
class SplitWindow extends StatefulWidget {
  const SplitWindow({super.key});
  @override
  _SplitWindowState createState() => _SplitWindowState();
}

class _SplitWindowState extends State<SplitWindow> {
  final Debouncer _debouncer = Debouncer(Duration(seconds: 1));

  /// 初始分割位置为中间
  double _splitPosition = 0.5;

  /// 中间分隔条的宽度
  final double _centerSeplineWidth = 4;

  var textEditingController = TextEditingController();
  var textResultController = TextEditingController();
  late ParsingSettingsModel _confModel;
  String _lastPastedContent = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _confModel = context.read<ParsingSettingsModel>();
    _confModel.setOnPastedJsonStringChanged((value) {
      textEditingController.text = value;
      _handleConfChange();
    });
    _confModel.addListener(_handleConfChange);
  }

  /// 检查并自动格式化粘贴的内容
  void _checkAndFormatPastedContent(String newContent) {
    final formatted = JsonFormatUtils.autoFormatJsonContent(newContent, _lastPastedContent);
    if (formatted != newContent) {
      setState(() {
        textEditingController.text = formatted;
        _lastPastedContent = formatted;
      });
    } else {
      _lastPastedContent = newContent;
    }
  }

  /// 配置变更后刷新页面数据
  void _handleConfChange() {
    _debouncer.run(() {
      JsonModelGenerator.asyncGenerateModels(textEditingController.text, _confModel)
          .then((data) {
        setState(() {
          textResultController.text = data ?? '';
          outputResult = textResultController.text;
        });
      }) // 成功回调
          .catchError((error) {
        print('错误: $error');
        return null;
      }) // 错误回调
          .whenComplete(() => print('操作完成')); // 最终回调
    });
  }

  /// 更改分割线的位置
  void _updateSplitPosition(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      double dx = position.dx;
      double anchorX = 400.0;
      if (dx < anchorX) {
        dx = anchorX;
      } else if (dx > screenWidth - anchorX - _centerSeplineWidth) {
        dx = screenWidth - anchorX - _centerSeplineWidth;
      }
      _splitPosition = dx / screenWidth;
    });
  }



  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final leftWidth = totalWidth * _splitPosition;
        final rightWidth = totalWidth * (1 - _splitPosition) - _centerSeplineWidth;

        return Stack(
          children: [
            // 左侧输入框
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: leftWidth,
              child: _buildPanel(
                controller: textEditingController,
                hintText: "请在此处输入JSON内容",
                isReadOnly: false,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: textEditingController.text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制输入内容')));
                },
                onChanged: (value) {
                  _checkAndFormatPastedContent(value);
                  _confModel.resetpastedJsonString();
                  _handleConfChange();
                },
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(35)),
              ),
            ),

            // 中间分隔条
            Positioned(
              left: leftWidth,
              top: 0,
              bottom: 0,
              width: _centerSeplineWidth + 20, // 扩大拖拽范围
              child: _buildSplitter(),
            ),

            // 右侧输出框
            Positioned(
              left: leftWidth + _centerSeplineWidth,
              top: 0,
              bottom: 0,
              width: rightWidth,
              child: _buildPanel(
                controller: textResultController,
                hintText: "模型类生成后显示在此处",
                isReadOnly: true,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: textResultController.text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制输出内容')));
                },
                borderRadius: const BorderRadius.only(bottomRight: Radius.circular(35)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPanel({
    required TextEditingController controller,
    required String hintText,
    required bool isReadOnly,
    required VoidCallback onCopy,
    BorderRadius? borderRadius,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: borderRadius),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 1, 1, 1),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: isReadOnly,
                maxLines: null,
                expands: true, // 让 TextField 自动撑满空间
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0, right: 20.0),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.black, // 背景色
                    shape: BoxShape.circle, // 圆形
                  ),
                  child: IconButton(
                    iconSize: 22,
                    icon: const Icon(Icons.copy, color: Colors.white), // 图标颜色改为白色
                    tooltip: "复制",
                    onPressed: onCopy,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitter() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) {
        _updateSplitPosition(details.globalPosition);
      },
      child: Center(
        child: Container(
          width: _centerSeplineWidth,
          color: Colors.black,
          child: Icon(Icons.drag_handle, size: _centerSeplineWidth * 0.8),
        ),
      ),
    );
  }
}
