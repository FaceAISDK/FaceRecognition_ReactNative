import SwiftUI
import PhotosUI
import FaceAISDK_Core

// 定义单侧人脸的数据模型
struct FaceSlot {
    var originalImage: UIImage?
    var croppedImage: UIImage?
    var feature: String?
    var isLoading: Bool = false
}

//SDK API viewModel.evaluateSimilarity(f1: f1, f2: f2)
public struct VerifyTwoFaceSimiView: View {
    // 恢复 dismiss 以支持自定义导航栏返回
    @Environment(\.dismiss) private var dismiss
    
    @State private var leftSlot = FaceSlot()
    @State private var rightSlot = FaceSlot()
    
    @StateObject private var viewModel = VerifyTwoFaceSimiModel()
    @State private var similarityResult: String = ""
    @State private var activePicker: PickerType?
    
    // CustomToastView 相关状态
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastStyle: ToastStyle = .success
    
    enum PickerType: Identifiable {
        case left, right
        var id: Int { hashValue }
    }
    
    // 干净的初始化方法
    public init() {}

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Text("Verify Two Face Similarity")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 30) {
                        HStack(spacing: 20) {
                            faceBox(slot: leftSlot) { activePicker = .left }
                            faceBox(slot: rightSlot) { activePicker = .right }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 25)

                        if !similarityResult.isEmpty {
                            VStack(spacing: 8) {
                                Text(similarityResult)
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 22)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                            .padding(.horizontal, 33)
                        }

                        // MARK: - 4. 操作按钮
                        Button(action: runComparison) {
                            Text("Verify Two Face Similarity")
                                .font(.headline).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 55)
                                .background(canCompare ? Color.blue : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(!canCompare)
                        .padding(.horizontal, 33)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            
            if showToast {
                VStack {
                    Spacer()
                    CustomToastView(
                        message: toastMessage,
                        style: toastStyle
                    )
                    .padding(.bottom, 77)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .sheet(item: $activePicker) { type in
            ImagePicker(selectedImage: .constant(nil)) { uiImage in
                handleImageSelected(uiImage, for: type)
            }
        }
        // 监听 Model 提示状态改变，弹出 Toast
        .onChange(of: viewModel.sdkInterfaceTips.code) { code in
            if code != 0 {
                let msg = NSLocalizedString("Face_Tips_Code_\(code)", comment: "")
                toastMessage = msg
                
                // 简单约定：如果检测到人脸（Code为确认录入等）视为 success，否则视为 failure
                toastStyle = (code == FaceTipsCode.CONFIRM_ADD_FACE) ? .success : .failure
                
                withAnimation {
                    showToast = true
                }
                
                // 2秒后自动隐藏 Toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showToast = false
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showToast)
    }

    private var canCompare: Bool {
        leftSlot.feature != nil && rightSlot.feature != nil
    }

    // 处理图片选择后的初始化与直接回调闭包
    private func handleImageSelected(_ image: UIImage, for type: PickerType) {
        // 选择图片后，先重置当前 Slot 的状态
        if type == .left {
            leftSlot.originalImage = image
            leftSlot.isLoading = true
            leftSlot.feature = nil
        } else {
            rightSlot.originalImage = image
            rightSlot.isLoading = true
            rightSlot.feature = nil
        }
        
        // 调用 Model 闭包处理人脸
        viewModel.processImage(image) { croppedImage, feature in
            // 无论成功还是失败，都会走到这里，从而安全地关闭 Loading 状态
            if type == .left {
                leftSlot.isLoading = false
                leftSlot.croppedImage = croppedImage
                leftSlot.feature = feature
            } else {
                rightSlot.isLoading = false
                rightSlot.croppedImage = croppedImage
                rightSlot.feature = feature
            }
            similarityResult = "" //清空之前的结果
        }
    }

    private func runComparison() {
        guard let f1 = leftSlot.feature, let f2 = rightSlot.feature else { return }
        let score = viewModel.evaluateSimilarity(f1: f1, f2: f2)
        similarityResult = String(format: "%.2f%%", score * 100)
    }

    // 复用 UI 组件
    @ViewBuilder
    private func faceBox(slot: FaceSlot, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if let displayImg = slot.croppedImage ?? slot.originalImage {
                    Image(uiImage: displayImg).resizable().scaledToFill()
                } else {
                    VStack {
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.largeTitle)
                    }.foregroundColor(.gray)
                }
                
                if slot.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                        ProgressView().tint(.white)
                    }
                }
            }
            .frame(width: 150, height: 150)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            .clipped()
        }.buttonStyle(PlainButtonStyle())
    }
}
