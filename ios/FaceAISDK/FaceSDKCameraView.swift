import SwiftUI
import AVFoundation

/**
 * 人脸相机预览管理
 *
 */
public struct FaceSDKCameraView: UIViewControllerRepresentable {
    let session: AVCaptureSession
    let cameraSize:CGFloat
    
    public init(session: AVCaptureSession, cameraSize: CGFloat) {
        self.session = session
        self.cameraSize = cameraSize
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        // Ensure square preview
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = CGRect(x: 0, y: 0, width: cameraSize, height: cameraSize)
        
        viewController.view.layer.addSublayer(previewLayer)
        viewController.view.clipsToBounds = true
        
        return viewController
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update preview layer frame if needed
        if let previewLayer = uiViewController.view.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = CGRect(x: 0, y: 0, width: cameraSize, height:cameraSize)
        }
    }
    
}

