import Foundation

@objcMembers
public class FaceSDKLocalizer: NSObject {
    /// 统一的多语言获取方法
    /// - Parameters:
    ///   - key: 多语言 Key
    ///   - defaultValue: 如果找不到则返回的默认字符串
    /// - Returns: 翻译后的字符串
    public static func text(_ key: String, defaultValue: String? = nil) -> String {
        let localizedString = NSLocalizedString(key, comment: "")

        // 如果返回的字符串与 Key 相同，说明没有找到对应的翻译
        if localizedString == key {
            return defaultValue ?? key
        }

        return localizedString
    }
}
