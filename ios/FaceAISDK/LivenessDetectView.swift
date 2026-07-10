import SwiftUI
import AVFoundation
import FaceAISDK_Core

/**
 * Liveness Detection (Supports motion, color flash, and silent liveness)
 * UI style is for reference only and can be adjusted according to your business needs
 * 活体检测（支持动作活体，炫彩活体，静默活体）UI 样式仅供参考，根据你的业务可自行调整
 */
struct LivenessDetectView: View {
    @StateObject private var viewModel: VerifyFaceModel = VerifyFaceModel()
    @State private var showLightHighDialog = false
    @State private var showFailureDialog = false
    @State private var isTipAppeared = false
    
    @Environment(\.dismiss) private var dismiss

    // Automatically control screen brightness
    // 自动控制屏幕亮度
    var autoControlBrightness: Bool = true
    
    // 0. No liveness detection  1. Motion only  2. Motion + Color flash  3. Color flash only
    // 0. 无需活体检测 1.仅仅动作 2.动作+炫彩 3.炫彩
    let livenessType:Int
    
    // Types of motion liveness:  1. Open mouth  2. Smile  3. Blink  4. Shake head  5. Nod
    // 动作活体种类：1. 张张嘴  2.微笑  3.眨眨眼  4.摇摇头  5.点头
    let motionLiveness:String
    
    // Timeout in seconds
    // 动作活体超时时间，秒
    let motionLivenessTimeOut:Int
    
    // Number of motion steps
    // 动作活体个数
    let motionLivenessSteps:Int
    
    // callback status code, liveness score,message
    let onDismiss: (Int, Float,String) -> Void
    
    // Multi-language tips can be provided based on the Code
    // 可以根据Code进行多语言提示
    private func localizedTips(for code: Int) -> String {
        let key = "Face_Tips_Code_\(code)"
        let defaultValue = "LivenessDetect Tips Code=\(code)"
        let tipsString = NSLocalizedString(key, value: defaultValue, comment: "")
        if code != 0 && code != 1 && code != 3 {
            TTSPlayer.shared.speak(tipsString)
        }
        return tipsString
    }
    
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: {
                        // 0 represents user cancellation 0代表用户取消
                        onDismiss(0,0.0,"User canceled")
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
                .padding(.horizontal, 10)
                .padding(.top, 10)
                
                
                if isTipAppeared {
                    Text(localizedTips(for: viewModel.sdkInterfaceTips.code))
                        .font(.system(size: 20).bold())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .background(Color.faceMain)
                        .cornerRadius(20)
                        .id(viewModel.sdkInterfaceTips.code)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.sdkInterfaceTips.code)
                }
                
                
                Text(localizedTips(for: viewModel.sdkInterfaceTipsExtra.code))
                    .font(.system(size: 20).bold())
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
                    .frame(minHeight: 30)
                    .foregroundColor(.black)
                
                FaceSDKCameraView(session: viewModel.captureSession, cameraSize: FaceCameraSize)
                    .frame(width: FaceCameraSize, height: FaceCameraSize)
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding(.vertical, 8)
                    .clipShape(Circle())
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(viewModel.colorFlash.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)


            // Failure dialog when liveness detection fails (两按钮：知道了 / 重试)
            if showFailureDialog {
                ZStack {
                    VStack(spacing: 18) {
                        let message=localizedTips(for: viewModel.faceVerifyResult.tipsCode)

                        Text(message)
                            .font(.system(size: 18).bold())
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                            .padding(.vertical,18)
                            .padding(.horizontal, 4)  

                        HStack(spacing: 12) {
                            Button(action: {
                                withAnimation {
                                    showFailureDialog = false
                                    _ = FaceImageManager.saveFaceImage(faceName: "Liveness", faceImage: viewModel.faceVerifyResult.faceImage)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    onDismiss(viewModel.faceVerifyResult.code, viewModel.faceVerifyResult.liveness,message)
                                    dismiss()
                                }
                            }) {
                                Text("I Know")
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
                                viewModel.reInit() //重新
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
            if autoControlBrightness {
                ScreenBrightnessHelper.shared.maximizeBrightness()
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.9)) {
                isTipAppeared = true
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                UIScreen.main.brightness = 1.0
            }
            
            viewModel.initFaceAISDK(faceIDFeature: "",
                                    livenessType: livenessType,
                                    onlyLiveness: true,
                                    motionLiveness: motionLiveness,
                                    motionLivenessTimeOut:motionLivenessTimeOut,
                                    motionLivenessSteps:motionLivenessSteps)
        }
        .onChange(of: viewModel.faceVerifyResult.code) { newValue in
            // 忽略默认状态（例如刚初始化或重试时变成 0），避免直接掉入底部的默认退出流程
            if newValue == VerifyResultCode.DEFAULT { return }
            

            // 如果是下列失败码之一，则弹出失败对话框（允许用户知道了或重试），并返回以避免继续执行默认的 toast/退出流程
            let failureCodes: [Int] = [
                VerifyResultCode.MOTION_LIVENESS_TIMEOUT,
                VerifyResultCode.NO_FACE_MULTI,
                VerifyResultCode.COLOR_LIVENESS_LIGHT_TOO_HIGH,
                VerifyResultCode.COLOR_LIVENESS_FAILED,
                VerifyResultCode.SILENT_LIVENESS_FAILED
            ]

            if failureCodes.contains(newValue) {
                withAnimation {
                    showFailureDialog = true
                }
                return
            }

            // 其余情况沿用原有流程：展示 toast -> 回调 -> 退出
            withAnimation {
                showFailureDialog = false
                _ = FaceImageManager.saveFaceImage(faceName: "Liveness", faceImage: viewModel.faceVerifyResult.faceImage)
            }
            
            let message=localizedTips(for: viewModel.faceVerifyResult.tipsCode)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onDismiss(viewModel.faceVerifyResult.code, viewModel.faceVerifyResult.liveness,message)
                dismiss()
            }
            
        }
        .onDisappear {
            if autoControlBrightness {
                ScreenBrightnessHelper.shared.restoreBrightness()
            }
            
            viewModel.stopFaceVerify()
        }
    }
}
