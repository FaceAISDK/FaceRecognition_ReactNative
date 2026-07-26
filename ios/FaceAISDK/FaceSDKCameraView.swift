// FaceAISDK.Service@gmail.com , https://github.com/FaceAISDK

import AVFoundation
import SwiftUI

/// Hosts an AVCaptureSession preview in SwiftUI.
/// 在 SwiftUI 中承载 AVCaptureSession 相机预览。
public struct FaceSDKCameraView: UIViewControllerRepresentable {
    let session: AVCaptureSession
    let cameraSize: CGFloat

    public init(session: AVCaptureSession, cameraSize: CGFloat) {
        self.session = session
        self.cameraSize = cameraSize
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)

        // Keeps the preview square and center-cropped. 保持方形预览并居中裁剪。
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = CGRect(x: 0, y: 0, width: cameraSize, height: cameraSize)

        viewController.view.layer.addSublayer(previewLayer)
        viewController.view.clipsToBounds = true

        return viewController
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Synchronizes the preview layer after layout changes. 布局变化后同步预览图层尺寸。
        if let previewLayer = uiViewController.view.layer.sublayers?.first
            as? AVCaptureVideoPreviewLayer
        {
            previewLayer.frame = CGRect(x: 0, y: 0, width: cameraSize, height: cameraSize)
        }
    }

}
