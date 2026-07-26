// FaceAISDK.Service@gmail.com , https://github.com/FaceAISDK

import UIKit

/// Controls screen brightness and idle behavior for native and hybrid hosts.
/// 为原生及 uni-app、Flutter 等混合宿主控制屏幕亮度与自动锁屏。
public class ScreenBrightnessHelper {

    public static let shared = ScreenBrightnessHelper()

    private var originalBrightness: CGFloat?
    private var wasIdleTimerDisabled: Bool = false
    private var isMaximized = false

    private init() {}

    /// Saves the current state and maximizes brightness safely. 保存当前状态并线程安全地调至最亮。
    public func maximizeBrightness() {
        runOnMain { [weak self] in
            guard let self = self else { return }

            // Save once so repeated calls never overwrite the original value. 仅保存一次，避免重复调用覆盖原始亮度。
            if !self.isMaximized {
                self.originalBrightness = self.getCurrentBrightness()
                self.wasIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
                self.isMaximized = true
            }

            self.setBrightness(1.0)

            // Prevent screen lock during face capture. 人脸采集期间禁止自动锁屏。
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }

    /// Restores the saved brightness and idle state safely. 线程安全地恢复亮度和自动锁屏状态。
    public func restoreBrightness() {
        runOnMain { [weak self] in
            guard let self = self else { return }

            guard self.isMaximized, let original = self.originalBrightness else { return }

            self.setBrightness(original)
            UIApplication.shared.isIdleTimerDisabled = self.wasIdleTimerDisabled
            self.isMaximized = false
            self.originalBrightness = nil
        }
    }

    // MARK: - Private helpers / 私有辅助方法

    /// Reads brightness from the active foreground scene. 从当前前台场景读取亮度。
    private func getCurrentBrightness() -> CGFloat {
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
            .first
        {
            scene.screen.brightness = value
        } else {
            UIScreen.main.brightness = value
        }
    }

    /// Runs UIKit changes on the main thread. 在主线程执行 UIKit 状态修改。
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
