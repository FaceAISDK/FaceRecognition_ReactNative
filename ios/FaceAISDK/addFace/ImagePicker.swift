import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

// Extension for UIImage providing utility functions for image processing
extension UIImage {
    
    // Scales the image to a specified size and removes complex metadata
    // 将图像缩放到指定尺寸，并剔除复杂的元数据
    public func scaledImage(with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size))
        
        // Core step: "Flatten" the image through encode/decode to strip metadata (like orientation flags)
        // 核心步骤：通过编码/解码将图像“拍扁”，剔除复杂元数据（如方向标识等）
        // 注：不论原始是 WebP 还是 HEIC，这里都会被统一转码为标准格式数据
        return UIGraphicsGetImageFromCurrentImageContext()?.data.flatMap(UIImage.init)
    }

    // Helper property to extract image data
    // 获取图像数据的辅助属性
    private var data: Data? {
        // Using a compression quality of 0.8 is the golden standard to balance memory usage and recognition accuracy
        // 使用 0.8 的压缩质量是平衡内存与识别精度的黄金标准
        return self.pngData() ?? self.jpegData(compressionQuality: 0.8)
    }
}

// A SwiftUI wrapper for PHPickerViewController to pick images from the photo library
// PHPickerViewController 的 SwiftUI 封装，用于从照片库中选择图像
struct ImagePicker: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    // Optional callback triggered when an image is successfully picked and processed
    // 当成功选择并处理图像时触发的可选回调
    var onImagePicked: ((UIImage) -> Void)?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()

        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // 此视图控制器生命周期不需要更新
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Coordinator class to act as the PHPickerViewControllerDelegate
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            // Ensure the selected item exists 确保选中的项目存在
            guard let provider = results.first?.itemProvider else { return }

            // 2. support WebP, HEIC, GIF, RAW ,PNG ,JPEG
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
                    guard let self = self else { return }
                    
                    if let data = data, let uiImage = UIImage(data: data) {
                        self.processAndReturn(uiImage: uiImage)
                    } else {
                        // 兜底策略：如果 Data 解析失败，尝试系统原生对象加载
                        self.fallbackToObjectLoad(provider: provider)
                    }
                }
            }else {
                // 如果连泛用的 UTType.image 都不符合，直接尝试强制按 UIImage 加载
                self.fallbackToObjectLoad(provider: provider)
            }
        }
        

        private func processAndReturn(uiImage: UIImage) {
            // Scale to a base width of 999 to maintain facial feature extraction accuracy while avoiding memory overflow.
            // 建议缩放至 999 基础宽度，既能保证特征提取的准确性，又不会导致内存溢出。
            let targetSize = CGSize(
                width: 999,
                height: 999 * (uiImage.size.height / uiImage.size.width)
            )
            
            if let processedImage = uiImage.scaledImage(with: targetSize) {
                // 回调必须在主线程
                DispatchQueue.main.async {
                    self.parent.selectedImage = processedImage
                    self.parent.onImagePicked?(processedImage)
                }
            }
        }
        
        // 提取的兜底加载方法
        private func fallbackToObjectLoad(provider: NSItemProvider) {
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    if let uiImage = image as? UIImage {
                        self?.processAndReturn(uiImage: uiImage)
                    }
                }
            }
        }
    }
}
