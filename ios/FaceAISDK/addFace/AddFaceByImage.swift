// FaceAISDK.Service@gmail.com , https://github.com/FaceAISDK

import FaceAISDK_Core
import PhotosUI
import SwiftUI

/// Adds a face from the photo library. 从系统相册录入人脸。
public struct AddFaceByImage: View {

    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var canSave = false

    // Image used for preview and processing. 用于预览和处理的图片。
    @State private var selectedImage: UIImage?

    @StateObject private var viewModel: AddFaceByImageModel = AddFaceByImageModel()

    let faceID: String
    // Returns status, face feature, and message; 0 is cancel, 1 is success.
    // 返回状态、人脸特征和信息；0 表示取消，1 表示成功。
    let onDismiss: (Int, String, String) -> Void

    @Environment(\.dismiss) private var dismiss

    private func localizedTip(for code: Int) -> String {
        let key = "Face_Tips_Code_\(code)"
        let defaultValue = "LivenessDetect Tips Code=\(code)"
        return NSLocalizedString(key, value: defaultValue, comment: "")
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 20) {

                HStack {
                    // Back action. 返回操作。
                    Button(action: {
                        onDismiss(0, "", "User Cancel")
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }

                    // Page title. 页面标题。
                    Text("Enroll Face From Album")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)

                    Spacer()

                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                ScrollView {
                    VStack(spacing: 25) {

                        Text(viewModel.message)
                            .font(.system(size: 17).bold())
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .foregroundColor(Color.faceMain)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                        // Image preview and picker hit area. 图片预览及相册选择热区。
                        Group {
                            if let selectedImage {
                                ZStack {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 166, maxHeight: 166)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(radius: 8)

                                    if isLoading {
                                        ZStack {
                                            Color.black.opacity(0.4)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                            ProgressView()
                                                .scaleEffect(1.5)
                                                .tint(.white)
                                        }
                                        .frame(maxWidth: 166, maxHeight: 166)
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .foregroundStyle(.tertiary)

                                    Text("Select from album")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 166, height: 166)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                )
                            }
                        }
                        .onTapGesture {
                            showImagePicker = true
                        }

                        Button(action: {
                            // The async detector has updated the aligned crop. 异步检测已更新对齐后的人脸图。
                            let feature = viewModel.getFaceFeature(faceUIImage: viewModel.croppedFaceImage)
                            if !feature.isEmpty {

                                // Saves the extracted feature. 保存提取的人脸特征。
                                UserDefaults.standard.set(feature, forKey: faceID)
                                onDismiss(1, feature, "Add Face Success")
                                dismiss()
                            }

                        }) {
                            Text("Save Face Feature")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(canSave ? .green : .gray)
                        .disabled(!canSave)
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)

            .onChange(of: viewModel.croppedFaceImage) { newValue in
                withAnimation {
                    selectedImage = newValue
                    isLoading = false
                    canSave = true
                }
            }

            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage) { uiImage in
                    isLoading = true
                    canSave = false

                    // Bridges the async detector into the SwiftUI action. 在 SwiftUI 操作中通过 Task 调用异步检测。
                    Task {
                        await viewModel.addFaceByUIImageAsync(faceUIImage: uiImage)
                    }

                }
            }

        }
    }
}
