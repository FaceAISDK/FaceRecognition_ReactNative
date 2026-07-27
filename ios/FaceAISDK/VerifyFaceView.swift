// FaceAISDK.Service@gmail.com , https://github.com/FaceAISDK

import FaceAISDK_Core
import SwiftUI

/// 1:1 Face Verification and Liveness Detection
/// 1:1 人脸识别以及活体检测
struct VerifyFaceView: View {
    @StateObject private var viewModel: VerifyFaceModel = VerifyFaceModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showFailureDialog = false
    @State private var isTipAppeared = false

    // Automatically control screen brightness
    // 自动控制屏幕亮度
    var autoControlBrightness: Bool = true
    // Tracks failed attempts. 记录失败尝试次数。
    var retryTime: Int = 0

    let faceID: String
    let threshold: Float

    // Types 1–3 include silent liveness by default. 类型 1–3 默认包含静默活体。
    // 0: None, 1: Motion, 2: Motion + Color, 3: Color, 4: Silent only.
    // 0：无，1：动作，2：动作+炫彩，3：炫彩，4：仅静默。
    let livenessType: Int

    // Types of motion liveness: 1. Open mouth 2. Smile 3. Blink 4. Shake head 5. Nod
    // 动作活体种类：1. 张张嘴  2.微笑  3.眨眨眼  4.摇摇头  5.点头
    let motionLiveness: String

    // Motion liveness timeout (seconds)
    // 动作活体超时（秒）
    let motionLivenessTimeOut: Int

    // Number of motion liveness steps
    // 动作活体步骤个数
    let motionLivenessSteps: Int

    // Callback status, face similarity, liveness score,Message
    // 返回状态，人脸相似度，活体分数,Message
    let onDismiss: (Int, Float, Float, String) -> Void

    // Multi-language message tips
    // 多语言信息提示
    private func localizedTips(for code: Int) -> String {
        let key = "Face_Tips_Code_\(code)"
        let defaultValue = "VerifyFace Tips Code=\(code)"
        return NSLocalizedString(key, value: defaultValue, comment: "")
    }

    /// Keep speech out of SwiftUI `body`; only state changes may trigger TTS.
    /// TTS 不在 SwiftUI `body` 中执行，仅由状态变化触发。
    private func speakTipsIfNeeded(for code: Int) {
        let shouldSpeak =
            code != FaceTipsCode.FACE_THE_CAMERA
            && code != FaceTipsCode.NO_FACE_DETECTED
            && code != FaceTipsCode.COME_CLOSER
            && code != FaceTipsCode.CLEAN_TIPS
        guard shouldSpeak else {
            TTSPlayer.shared.stop()
            return
        }
        TTSPlayer.shared.speak(localizedTips(for: code), policy: .interrupt)
    }

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: {
                        // Status 0 represents user cancellation. 状态 0 表示用户取消。
                        onDismiss(0, 0.0, 0.0, "user cancel")
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

                if isTipAppeared {
                    Text(localizedTips(for: viewModel.sdkInterfaceTips.code))
                        .font(.system(size: 21).bold())
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .background(Color.faceMain)
                        .cornerRadius(20)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.7), value: viewModel.sdkInterfaceTips.code)
                }

                Text(localizedTips(for: viewModel.sdkInterfaceTipsExtra.code))
                    .font(.system(size: 20, weight: .bold))
                    .padding(.bottom, 6)
                    .frame(minHeight: 30)
                    .foregroundColor(Color.faceMain)

                FaceSDKCameraView(session: viewModel.captureSession, cameraSize: faceCameraSize)
                    .frame(
                        width: faceCameraSize,
                        height: faceCameraSize
                    )
                    .padding(.vertical, 8)
                    .aspectRatio(1.0, contentMode: .fit)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(viewModel.colorFlash.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)

            // Shows acknowledgment and retry actions after failure. 失败后显示“知道了”和“重试”操作。
            if showFailureDialog {
                ZStack {
                    VStack(spacing: 18) {
                        let message = localizedTips(for: viewModel.faceVerifyResult.tipsCode)
                        Text(message)
                            .font(.system(size: 18).bold())
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 4)

                        HStack(spacing: 12) {
                            Button(action: {
                                withAnimation {
                                    showFailureDialog = false
                                }
                                _ = FaceImageManager.saveFaceImage(
                                    faceName: faceID, faceImage: viewModel.faceVerifyResult.faceImage)

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    onDismiss(
                                        viewModel.faceVerifyResult.code,
                                        viewModel.faceVerifyResult.similarity,
                                        viewModel.faceVerifyResult.liveness,
                                        message)
                                    dismiss()
                                }

                            }) {
                                Text("Got It")
                                    .font(.system(size: 18).bold())
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }

                            Button(action: {
                                withAnimation {
                                    showFailureDialog = false
                                }
                                viewModel.reInit()
                            }) {
                                Text("Retry")
                                    .font(.system(size: 18).bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.faceMain)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 30)
                }
                .zIndex(2)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .onAppear {
            TTSPlayer.shared.resetDuplicateHistory()
            TTSPlayer.shared.prepare()

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.9)) {
                isTipAppeared = true
            }

            if autoControlBrightness {
                ScreenBrightnessHelper.shared.maximizeBrightness()
            }

            withAnimation(.easeInOut(duration: 0.3)) {
                UIScreen.main.brightness = 1.0
            }

            // Check if there is a local feature value for the faceID
            // 校验本地是否有特征值
            guard let faceFeature = UserDefaults.standard.string(forKey: faceID) else {

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDismiss(VerifyResultCode.NO_FACE_FEATURE, 0.0, 0.0, "No Face Feature for : \(faceID)")
                    dismiss()
                }

                return
            }

            guard faceFeature.count == 1024 else {

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDismiss(
                        VerifyResultCode.NO_FACE_FEATURE, 0.0, 0.0, "faceFeature.count error : \(faceID)")
                    dismiss()
                }

                return
            }

            viewModel.initFaceAISDK(
                faceIDFeature: faceFeature,
                threshold: threshold,
                livenessType: livenessType,
                onlyLiveness: false,
                motionLiveness: motionLiveness,
                motionLivenessTimeOut: motionLivenessTimeOut,
                motionLivenessSteps: motionLivenessSteps
            )
        }
        .onChange(of: viewModel.sdkInterfaceTips.code) { code in
            speakTipsIfNeeded(for: code)
        }

        .onChange(of: viewModel.faceVerifyResult.code) { newValue in
            // Ignore the initial/reset state to avoid premature dismissal. 忽略初始化或重试状态，避免提前退出。
            if newValue == VerifyResultCode.DEFAULT { return }

            // Some terminal states bypass sdkInterfaceTips; duplicate speech is filtered. 部分终态不经过 sdkInterfaceTips，重复语音会被过滤。
            speakTipsIfNeeded(for: viewModel.faceVerifyResult.tipsCode)

            // Keep recoverable failures on screen for retry. 可恢复失败停留在当前页供用户重试。
            let failureCodes: [Int] = [
                VerifyResultCode.VERIFY_FAILED,
                VerifyResultCode.MOTION_LIVENESS_TIMEOUT,
                VerifyResultCode.NO_FACE_MULTI,
                VerifyResultCode.COLOR_LIVENESS_LIGHT_TOO_HIGH,
                VerifyResultCode.COLOR_LIVENESS_FAILED,
                VerifyResultCode.SILENT_LIVENESS_FAILED,
            ]

            if failureCodes.contains(newValue) {
                withAnimation {
                    showFailureDialog = true
                }
                return
            }

            _ = FaceImageManager.saveFaceImage(
                faceName: faceID, faceImage: viewModel.faceVerifyResult.faceImage)
            let message = localizedTips(for: viewModel.faceVerifyResult.tipsCode)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                onDismiss(
                    viewModel.faceVerifyResult.code,
                    viewModel.faceVerifyResult.similarity,
                    viewModel.faceVerifyResult.liveness,
                    message)
                dismiss()
            }

        }
        .onDisappear {
            TTSPlayer.shared.stop()

            if autoControlBrightness {
                ScreenBrightnessHelper.shared.restoreBrightness()
            }

            viewModel.stopFaceVerify()
        }
    }
}
