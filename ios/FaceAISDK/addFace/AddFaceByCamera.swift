// FaceAISDK.Service@gmail.com , https://github.com/FaceAISDK

import AVFoundation
import FaceAISDK_Core
import SwiftUI

@MainActor
var faceCameraSize: CGFloat {
    14 * min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) / 20
}

private struct ConfirmDialogTopAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGPoint>?

    static func reduce(
        value: inout Anchor<CGPoint>?,
        nextValue: () -> Anchor<CGPoint>?
    ) {
        value = nextValue() ?? value
    }
}

public struct AddFaceByCamera: View {
    let faceID: String
    // Reserved performance option. 预留的性能模式参数。
    let addFacePerformanceMode: Int
    // Shows confirmation before saving when enabled. 开启后在保存前显示确认弹窗。
    let needShowConfirmDialog: Bool

    // Returns status, face feature, and message; 0 is cancel, 1 is success.
    // 返回状态、人脸特征和信息；0 表示取消，1 表示成功。
    let onDismiss: (Int, String, String) -> Void

    var autoControlBrightness: Bool = true

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: AddFaceByCameraModel = AddFaceByCameraModel()

    // Resolves localized guidance by status code. 根据状态码获取本地化提示。
    private func localizedTips(for code: Int) -> String {
        let key = "Face_Tips_Code_\(code)"
        let defaultValue = "Add Face Tips Code=\(code)"
        return NSLocalizedString(key, value: defaultValue, comment: "")
    }

    // Speaks only actionable guidance. 仅播报需要用户操作的提示。
    private func speakTipsIfNeeded(for code: Int) {
        let shouldSpeak =
            code != FaceTipsCode.FACE_THE_CAMERA
            && code != FaceTipsCode.NO_FACE_DETECTED
            && code != FaceTipsCode.CONFIRM_ADD_FACE
            && code != FaceTipsCode.CLEAN_TIPS
        
        guard shouldSpeak else {
            //TTSPlayer.shared.stop()
            return
        }
        TTSPlayer.shared.speak(localizedTips(for: code), policy: .interrupt)
    }

    // Persists the accepted face and closes the page. 保存确认的人脸并关闭页面。
    private func saveFaceData() {
        // Saving the face image is optional. 人脸图片可按业务需要选择保存。
        if FaceImageManager.saveFaceImage(faceName: faceID, faceImage: viewModel.croppedFaceImage) {
            print("saveFaceImage success")
        }

        // Saves the face feature. 保存人脸特征。
        UserDefaults.standard.set(viewModel.faceFeatureBySDKCamera, forKey: faceID)

        // Returns the result after persistence. 保存后回调结果。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onDismiss(1, viewModel.faceFeatureBySDKCamera, "Add Face Success")
            dismiss()
        }

    }

    public var body: some View {
        ZStack {
            VStack(spacing: 20) {
                HStack {
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
                    Spacer()
                }
                .padding(.horizontal, 2)
                .padding(.top, 10)

                // Current capture guidance. 当前采集提示。
                Text(localizedTips(for: viewModel.sdkInterfaceTips.code))
                    .font(.system(size: 19).bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundColor(.white)
                    .background(Color.faceMain)
                    .cornerRadius(20)
                    .anchorPreference(
                        key: ConfirmDialogTopAnchorKey.self,
                        value: .top
                    ) {
                        $0
                    }

                ZStack {
                    // Live camera preview. 实时相机预览。
                    FaceSDKCameraView(session: viewModel.captureSession, cameraSize: faceCameraSize)
                        .aspectRatio(1.0, contentMode: .fit)
                        .clipShape(Circle())
                        .background(Circle().fill(Color.white))
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                }
                .frame(width: faceCameraSize, height: faceCameraSize)

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)

            .onAppear {
                TTSPlayer.shared.resetDuplicateHistory()
                TTSPlayer.shared.prepare()

                if autoControlBrightness {
                    ScreenBrightnessHelper.shared.maximizeBrightness()
                }
                viewModel.initAddFace()
            }
            .onDisappear {
                TTSPlayer.shared.stop()

                if autoControlBrightness {
                    ScreenBrightnessHelper.shared.restoreBrightness()
                }
                viewModel.stopAddFace()
            }
            .onChange(of: viewModel.sdkInterfaceTips.code) { newValue in
                speakTipsIfNeeded(for: newValue)
            }
            .onChange(of: viewModel.readyConfirmFace) { _ in

                guard viewModel.readyConfirmFace else { return }
                if needShowConfirmDialog {
                    print("show Confirm Dialog")
                } else {
                    // Saves immediately when confirmation is disabled. 关闭确认弹窗时直接保存。
                    saveFaceData()
                }
            }

        }
        .overlayPreferenceValue(ConfirmDialogTopAnchorKey.self) { topAnchor in
            GeometryReader { proxy in
                if let topAnchor,
                    viewModel.readyConfirmFace,
                    needShowConfirmDialog
                {
                    ZStack(alignment: .top) {
                        Color.black.opacity(0.32)
                            .ignoresSafeArea()
                            .transition(.opacity)

                        ConfirmAddFaceDialog(
                            viewModel: viewModel,
                            cameraSize: faceCameraSize,
                            onConfirm: {
                                saveFaceData()
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, proxy[topAnchor].y)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.94).combined(with: .opacity),
                                removal: .scale(scale: 0.98).combined(with: .opacity)
                            )
                        )
                    }
                }
            }
        }
        .animation(
            .spring(response: 0.32, dampingFraction: 0.86),
            value: viewModel.readyConfirmFace
        )
    }
}

struct ConfirmAddFaceDialog: View {
    let viewModel: AddFaceByCameraModel
    let cameraSize: CGFloat
    let onConfirm: () -> Void

    private var dialogWidth: CGFloat {
        min(max(cameraSize * 1.2, 300), 350)
    }

    private var previewWidth: CGFloat {
        min(dialogWidth - 44, 211)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 11) {
                ZStack {
                    Circle()
                        .fill(Color.faceMain.opacity(0.12))

                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.faceMain)
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Confirm & Enroll")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Spacer(minLength: 0)
            }

            Image(uiImage: viewModel.originFaceImage)
                .resizable()
                .scaledToFill()
                .frame(width: previewWidth-12, height: previewWidth)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.faceMain.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)

            Label("Ensure face is clear and fully visible", systemImage: "sparkles")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .allowsTightening(true)
                .padding(.bottom, 9)

            HStack(spacing: 14) {
                Button(action: viewModel.reInit) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .foregroundColor(.faceMain)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.faceMain.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.faceMain.opacity(0.24), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onConfirm) {
                    Label("Confirm", systemImage: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.faceMain)
                        )
                        .shadow(
                            color: Color.faceMain.opacity(0.28),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(width: dialogWidth)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(UIColor.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
        .accessibilityElement(children: .contain)
    }
}
