// FaceAISDK.Service@gmail.com , https://github.com/FaceAISDK

import FaceAISDK_Core
import PhotosUI
import SwiftUI

// Holds one side of the face comparison. 保存单侧人脸比对数据。
struct FaceSlot {
    var originalImage: UIImage?
    var croppedImage: UIImage?
    var feature: String?
    var isLoading: Bool = false
}

// SDK API: viewModel.evaluateSimilarity(f1:f2:).
// SDK 接口：viewModel.evaluateSimilarity(f1:f2:)。
public struct VerifyTwoFaceSimiView: View {
    // Supports the custom back action. 支持自定义返回操作。
    @Environment(\.dismiss) private var dismiss

    @State private var leftSlot = FaceSlot()
    @State private var rightSlot = FaceSlot()

    @StateObject private var viewModel = VerifyTwoFaceSimiModel()
    @State private var similarityResult: String = ""
    @State private var activePicker: PickerType?

    // Toast presentation state. Toast 展示状态。
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastStyle: ToastStyle = .success

    enum PickerType: Identifiable {
        case left, right
        var id: Int { hashValue }
    }

    // Public initializer for SDK samples. SDK 示例使用的公开初始化方法。
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
                    Text("Compare Two Faces")
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

                        // MARK: - Compare action / 比对操作
                        Button(action: runComparison) {
                            Text("Compare Two Faces")
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
        // Presents model status changes as toast messages. 将模型状态变化显示为 Toast。
        .onChange(of: viewModel.sdkInterfaceTips.code) { code in
            if code != 0 {
                let msg = NSLocalizedString("Face_Tips_Code_\(code)", comment: "")
                toastMessage = msg

                // Treats a confirmed face as success; other codes are failures. 确认检测到人脸视为成功，其他状态视为失败。
                toastStyle = (code == FaceTipsCode.CONFIRM_ADD_FACE) ? .success : .failure

                withAnimation {
                    showToast = true
                }

                // Hides the toast automatically. 自动隐藏 Toast。
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

    // Resets and processes the selected side. 重置并处理选中的一侧。
    private func handleImageSelected(_ image: UIImage, for type: PickerType) {
        // Clears stale state before processing. 处理前清除旧状态。
        if type == .left {
            leftSlot.originalImage = image
            leftSlot.isLoading = true
            leftSlot.feature = nil
        } else {
            rightSlot.originalImage = image
            rightSlot.isLoading = true
            rightSlot.feature = nil
        }

        // Processes and publishes the cropped face and feature. 处理并更新裁剪人脸及特征。
        viewModel.processImage(image) { croppedImage, feature in
            // Always ends loading on success or failure. 无论成功失败都结束加载状态。
            if type == .left {
                leftSlot.isLoading = false
                leftSlot.croppedImage = croppedImage
                leftSlot.feature = feature
            } else {
                rightSlot.isLoading = false
                rightSlot.croppedImage = croppedImage
                rightSlot.feature = feature
            }
            similarityResult = ""
        }
    }

    private func runComparison() {
        guard let f1 = leftSlot.feature, let f2 = rightSlot.feature else { return }
        let score = viewModel.evaluateSimilarity(f1: f1, f2: f2)
        similarityResult = String(format: "%.2f%%", score * 100)
    }

    // Shared face-slot component. 通用人脸槽位组件。
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
