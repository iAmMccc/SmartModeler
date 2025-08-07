import 'dart:convert';

/// JSON格式化工具类
class JsonFormatUtils {
  /// 尝试格式化JSON字符串
  /// 返回格式化后的字符串，如果格式错误返回null
  static String? tryFormatJson(String input) {
    if (input.trim().isEmpty) return null;
    
    try {
      final jsonObject = jsonDecode(input);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObject);
    } catch (e) {
      return null;
    }
  }

  /// 检查是否为有效的JSON格式
  static bool isValidJson(String input) {
    if (input.trim().isEmpty) return false;
    
    try {
      jsonDecode(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 自动格式化JSON内容（用于输入框内容变化检测）
  /// 返回格式化后的内容，如果不是JSON则返回原内容
  static String autoFormatJsonContent(String newContent, String lastContent) {
    // 如果内容没有变化或为空，直接返回
    if (newContent == lastContent || newContent.isEmpty) {
      return newContent;
    }
    
    // 尝试格式化JSON
    final formatted = tryFormatJson(newContent);
    return formatted ?? newContent;
  }
} 