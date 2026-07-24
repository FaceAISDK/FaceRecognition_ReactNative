import UIKit

// 亮度控制单例工具，为了兼容uniapp Flutter等插件
public class ScreenBrightnessHelper {
    
    // 单例入口
    public static let shared = ScreenBrightnessHelper()
    
    // 内部状态
    private var originalBrightness: CGFloat?
    private var wasIdleTimerDisabled: Bool = false
    
    // 防止重复设置的标记
    private var isMaximized = false
    
    private init() {}
        
    /// 保存当前环境并调至最亮 (线程安全)
    public func maximizeBrightness() {
        runOnMain { [weak self] in
            guard let self = self else { return }
            
            // 1. 如果当前没有处于“已调亮”状态，才保存原始值
            // 这样可以防止连续调用 maximize 导致把 1.0 误保存为原始亮度
            if !self.isMaximized {
                self.originalBrightness = self.getCurrentBrightness()
                self.wasIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
                self.isMaximized = true
            }
            
            // 2. 调亮屏幕
            self.setBrightness(1.0)
            
            // 3. 禁止自动锁屏
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    /// 恢复环境 (线程安全)
    public func restoreBrightness() {
        runOnMain { [weak self] in
            guard let self = self else { return }
            
            // 只有在“已调亮”状态下才执行恢复
            guard self.isMaximized, let original = self.originalBrightness else { return }
            
            // 1. 恢复亮度
            self.setBrightness(original)
            
            // 2. 恢复锁屏设置
            UIApplication.shared.isIdleTimerDisabled = self.wasIdleTimerDisabled
            
            // 3. 重置状态
            self.isMaximized = false
            self.originalBrightness = nil
        }
    }
    
    // MARK: - 内部私有方法
    
    /// 获取当前亮度
    private func getCurrentBrightness() -> CGFloat {
        // 优先获取活跃的前台 Scene
        let scene = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first
        return scene?.screen.brightness ?? UIScreen.main.brightness
    }
    
    private func setBrightness(_ value: CGFloat) {
        if let scene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first {
            scene.screen.brightness = value
        } else {
            UIScreen.main.brightness = value
        }
    }
    
    /// 辅助方法：确保闭包在主线程执行
    private func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
