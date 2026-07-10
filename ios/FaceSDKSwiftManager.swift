import SwiftUI
import UIKit
import FaceAISDK_Core
import AVFoundation
import Combine 

@objcMembers
public class FaceSDKSwiftManager: NSObject {

    private static func localizedTips(for code: Int) -> String {
        FaceSDKLocalizer.text("Face_Tips_Code_\(code)", defaultValue: "VerifyFace Tips Code=\(code)")
    }
    
    // MARK: - 相机权限检查
    private static func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        // 首次授权时系统权限弹窗刚关闭，立即 present 可能拿到不稳定的顶层 VC。
                        // 延迟一小段时间再继续，确保后续能正常跳转到 LivenessDetectView。
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            completion(true)
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        default:
            completion(false)
        }
    }
    
    // MARK: - 特征值管理 (核心修复点)
   public static func getiOSFaceFeature(_ faceID: String) -> String {
        return UserDefaults.standard.string(forKey: faceID) ?? ""
    }
	
	
    // MARK: - Base64 提取人脸特征 (支持插件/外部调用)
    public static func addFaceByBase64(_ faceID: String,
                                       _ base64Str: String, 
                                       _ callback: @escaping (NSNumber, String, String) -> Void) {
        
        // 1. 预处理 Base64 字符串（可以在后台线程做）
        var cleanBase64 = base64Str
        if let idx = cleanBase64.range(of: "base64,")?.upperBound {
            cleanBase64 = String(cleanBase64[idx...])
        }
        
        guard let data = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters),
              let image = UIImage(data: data) else {
                        callback(0, "", FaceSDKLocalizer.text("Base64 image parse failed"))
            return
        }

        // 2. 切换到主线程操作 @MainActor 隔离的 Model
        DispatchQueue.main.async {
            let model = AddFaceByImageModel() 
            let feature = model.getFaceFeature(faceUIImage: image)
            if !feature.isEmpty {
                UserDefaults.standard.set(feature, forKey: faceID)
                UserDefaults.standard.synchronize()
                // 回调成功
                callback(
                    1,
                    feature,
                    String(
                        format: FaceSDKLocalizer.text("Face feature extracted successfully, length: %ld"),
                        feature.count
                    )
                )
            } else {
                // 提取失败
                callback(0, "", FaceSDKLocalizer.text("Unable to extract face feature, ensure image is clear and contains a face"))
            }
        }
    }
		

	
	// 插入人脸特征值：增加长度判断拦截
	public static func insertFaceFeature(_ faceID: String,
	                                     _ feature: String, 
	                                     _ callback: @escaping (NSNumber,String) -> Void) {
	    
	    // 1. 拦截：判断字符串是否为空，或者长度是否小于 1024
	    // 特征值通常是加密后的超长字符串，如果太短说明数据不完整
	    if feature.isEmpty || feature.count < 1024 {
            callback(
                NSNumber(value: 0),
                String(
                    format: FaceSDKLocalizer.text("Feature length only %ld"),
                    feature.count
                )
            ) // 返回 0 表示失败
	        return
	    }
	
	    // 2. 校验通过，执行存储
	    UserDefaults.standard.set(feature, forKey: faceID)
	    
	    print("【FaceSDK】人脸特征值插入成功，ID: \(faceID)")
        callback(NSNumber(value: 1),"\(faceID) \(FaceSDKLocalizer.text("Face sync succeeded"))") // 返回 1 表示成功
	}


    // MARK: - 呼出相机录入人脸
    public static func showAddFaceByCamera(_ faceID: String,
                                           _ performanceMode: NSNumber,
                                           _ needConfirm: Bool,
                                           _ callback: @escaping (NSNumber, String, String) -> Void) {
        DispatchQueue.main.async {
            checkCameraPermission { granted in
                guard granted else {
                    callback(NSNumber(value: 0), "", FaceSDKLocalizer.text("User canceled/interrupted"))
                    return
                }
                guard let topVC = self.getTopViewController() else {
                    callback(NSNumber(value: 0), "", FaceSDKLocalizer.text("Unknown status code"))
                    return
                }

                var sdkView = AddFaceByCamera(
                    faceID: faceID,
                    addFacePerformanceMode: performanceMode.intValue, 
                    needShowConfirmDialog: needConfirm,
                    onDismiss: { [weak topVC] (resultCode: Int, feature: String, message: String) in
                        
                        let safeCode = NSNumber(value: resultCode)
                        
                        DispatchQueue.main.async {
                            ScreenBrightnessHelper.shared.restoreBrightness()
                            topVC?.dismiss(animated: true) {
                                callback(safeCode, feature, message)
                            }
                        }
                    }
                )
                sdkView.autoControlBrightness = false

                let hostingController = UIHostingController(rootView: sdkView)
                hostingController.modalPresentationStyle = .fullScreen
                topVC.present(hostingController, animated: true)
            }
        }
    }
	
	// MARK: - 1:1 人脸识别
	public static func showFaceVerify(_ faceID: String,
	                                  _ threshold: NSNumber,
	                                  _ livenessType: NSNumber,
	                                  _ motionLivenessTypes: String,
	                                  _ motionLivenessTimeOut : NSNumber,
	                                  _ motionLivenessSteps : NSNumber,
	                                  _ callback: @escaping (NSNumber, NSNumber, NSNumber, String) -> Void) {
	    DispatchQueue.main.async {
	        checkCameraPermission { granted in
	            guard granted else {
	                callback(NSNumber(value: 0), NSNumber(value: 0), NSNumber(value: 0), Self.localizedTips(for: 0))
	                return
	            }
	            guard let topVC = self.getTopViewController() else {
	                callback(NSNumber(value: 0), NSNumber(value: 0), NSNumber(value: 0), Self.localizedTips(for: 0))
	                return
	            }
	            ScreenBrightnessHelper.shared.maximizeBrightness()
	            
	            var sdkView = VerifyFaceView(
	                faceID: faceID,
	                threshold: threshold.floatValue,
	                livenessType: livenessType.intValue,
	                motionLiveness: motionLivenessTypes,
	                motionLivenessTimeOut: motionLivenessTimeOut.intValue,
	                motionLivenessSteps: motionLivenessSteps.intValue,
	                onDismiss: { [weak topVC] (resultCode: Int, similarity: Float, liveness: Float, message: String) in
	                    DispatchQueue.main.async {
	                        ScreenBrightnessHelper.shared.restoreBrightness()
	                        topVC?.dismiss(animated: true) {
	                            callback(
	                                NSNumber(value: resultCode),
	                                NSNumber(value: similarity),
	                                NSNumber(value: liveness),
	                                message
	                            )
	                        }
	                    }
	                }
	            )
	            sdkView.autoControlBrightness = false

	            let hostingController = UIHostingController(rootView: sdkView)
	            hostingController.modalPresentationStyle = .fullScreen
	            topVC.present(hostingController, animated: true)
	        }
	    }
	}
	
	// MARK: - 活体检测 
	public static func showLivenessVerify(_ livenessType: NSNumber,
	                                      _ motionLivenessTypes: String,
	                                      _ motionLivenessTimeOut : NSNumber,
	                                      _ motionLivenessSteps : NSNumber,
	                                      _ callback: @escaping (NSNumber, NSNumber, String) -> Void) {
	    DispatchQueue.main.async {
	        checkCameraPermission { granted in
	            guard granted else {
	                callback(NSNumber(value: 0), NSNumber(value: 0), Self.localizedTips(for: 0))
	                return
	            }
	            guard let topVC = self.getTopViewController() else {
	                callback(NSNumber(value: 0), NSNumber(value: 0), Self.localizedTips(for: 0))
	                return
	            }
	            ScreenBrightnessHelper.shared.maximizeBrightness()
	            
	            var sdkView = LivenessDetectView(
	                livenessType: livenessType.intValue,
	                motionLiveness: motionLivenessTypes,
	                motionLivenessTimeOut: motionLivenessTimeOut.intValue,
	                motionLivenessSteps: motionLivenessSteps.intValue,
	                onDismiss: { [weak topVC] (resultCode: Int, liveness: Float, message: String) in
	                    DispatchQueue.main.async {
	                        ScreenBrightnessHelper.shared.restoreBrightness()
	                        topVC?.dismiss(animated: true) {
	                            callback(
	                                NSNumber(value: resultCode),
	                                NSNumber(value: liveness),
	                                message
	                            )
	                        }
	                    }
	                }
	            )
	            sdkView.autoControlBrightness = false
	            
	            let hostingController = UIHostingController(rootView: sdkView)
	            hostingController.modalPresentationStyle = .fullScreen
	            topVC.present(hostingController, animated: true)
	        }
	    }
	}
	
    // 临时操作的图片转Base64 编码
    public static func getFaceImageBase64(_ faceName: String) -> String {
        guard let faceImageBase64 = FaceImageManager.faceImageToBase64(fileName: faceName) else {
            print("❌ [Swift] getFaceImageBase64 failed")
            return ""
        }
        return faceImageBase64
    }

	
    
    public static func isFaceFeatureExist(_ faceID: String, _ callback: @escaping (NSNumber,String) -> Void) {
        let featureString = UserDefaults.standard.string(forKey: faceID)
        // 2. 只有当字符串不为 nil 且长度正好为 1024 时，才判定为 true
        let exists = (featureString?.count == 1024)
        callback(
            NSNumber(value: exists ? 1 : 0),
            String(
                format: FaceSDKLocalizer.text("Feature length=%ld"),
                featureString?.count ?? 0
            )
        )
    }
	
    
    public static func deleteFaceFeature(_ faceID: String) {
        UserDefaults.standard.removeObject(forKey: faceID)
        UserDefaults.standard.removeObject(forKey: "\(faceID)_base64")
    }
	
    
    
    // MARK: - 辅助方法
    private static func getTopViewController() -> UIViewController? {
        let windowScene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        
        guard let keyWindow = windowScene?.windows.first(where: { $0.isKeyWindow }),
              let rootVC = keyWindow.rootViewController else {
            return nil
        }
        
        var topController = rootVC
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}