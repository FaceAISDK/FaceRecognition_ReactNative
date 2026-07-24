import SwiftUI
import FaceAISDK_Core

/**
 * 1:1 Face Verification and Liveness Detection
 * 1:1 人脸识别以及活体检测
 */
struct VerifyFaceView: View {
    @StateObject private var viewModel: VerifyFaceModel = VerifyFaceModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showFailureDialog = false
    @State private var isTipAppeared = false
    
    // Automatically control screen brightness
    // 自动控制屏幕亮度
    var autoControlBrightness: Bool = true
    var retryTime:Int = 0; //记录失败尝试的次数

    let faceID: String
    let threshold: Float
    
    // Type 1，2，3 include 4 Silent liveness Default 活体检测类型1，2，3默认包含4 静默活体
    // 0. No liveness detection  1. Motion   2. Motion + Color flash  3. Color flash   4.Only Silent liveness detection
    // 0. 无需活体检测 1.动作活体 2.动作+炫彩 3.炫彩 4.仅仅静默活体检测
    let livenessType:Int
    
    // Types of motion liveness: 1. Open mouth 2. Smile 3. Blink 4. Shake head 5. Nod
    // 动作活体种类：1. 张张嘴  2.微笑  3.眨眨眼  4.摇摇头  5.点头
    let motionLiveness:String
    
    // Motion liveness timeout (seconds)
    // 动作活体超时（秒）
    let motionLivenessTimeOut:Int
    
    // Number of motion liveness steps
    // 动作活体步骤个数
    let motionLivenessSteps:Int
    
    // Callback status, face similarity, liveness score,Message
    // 返回状态，人脸相似度，活体分数,Message
    let onDismiss: (Int, Float, Float,String) -> Void

    // Multi-language message tips
    // 多语言信息提示
    private func localizedTips(for code: Int) -> String {
        let key = "Face_Tips_Code_\(code)"
        let defaultValue = "VerifyFace Tips Code=\(code)"
        let tipsString = NSLocalizedString(key, value: defaultValue, comment: "")
        if code != 0 && code != 1 && code != 3 { //剔除不需要语音提示的code，否则太啰嗦
            TTSPlayer.shared.speak(tipsString)
        }
        return tipsString
    }
    
    var body: some View {
        ZStack {
            VStack {
                 HStack {
                    Button(action: {
                        // 0 represents user cancel 代表用户取消
                        onDismiss(0, 0.0, 0.0,"user cancel")
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
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.sdkInterfaceTips.code)
                }
                
                Text(localizedTips(for: viewModel.sdkInterfaceTipsExtra.code))
                    .font(.system(size: 20, weight: .bold))  
                    .padding(.bottom, 6)
                    .frame(minHeight: 30)
                    .foregroundColor(Color.faceMain)
                
                FaceSDKCameraView(session: viewModel.captureSession, cameraSize: FaceCameraSize)
                    .frame(
                        width: FaceCameraSize,
                        height: FaceCameraSize
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
            
            // Failure dialog when verification/liveness fails (两按钮：知道了 / 重试)
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
                                }
                                _ = FaceImageManager.saveFaceImage(faceName: faceID, faceImage: viewModel.faceVerifyResult.faceImage)
                                
                            
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    onDismiss(viewModel.faceVerifyResult.code,
                                              viewModel.faceVerifyResult.similarity,
                                              viewModel.faceVerifyResult.liveness,
                                              message)
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
                     onDismiss(VerifyResultCode.NO_FACE_FEATURE, 0.0, 0.0, "faceFeature.count error : \(faceID)")
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
                motionLivenessTimeOut:motionLivenessTimeOut,
                motionLivenessSteps:motionLivenessSteps
            )
        }
        
         .onChange(of: viewModel.faceVerifyResult.code) {newValue in
            // 忽略默认状态（例如刚初始化或重试时变成 0），避免直接掉入底部的默认退出流程
            if newValue == VerifyResultCode.DEFAULT { return }

            // 如果是下列失败码之一，则弹出失败对话框（允许用户重试），并返回以避免继续执行默认的 toast/退出流程
            let failureCodes: [Int] = [
                VerifyResultCode.VERIFY_FAILED,
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

            _ = FaceImageManager.saveFaceImage(faceName: faceID, faceImage: viewModel.faceVerifyResult.faceImage)
             let message=localizedTips(for: viewModel.faceVerifyResult.tipsCode)
             
             
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                 onDismiss(viewModel.faceVerifyResult.code,
                           viewModel.faceVerifyResult.similarity,
                           viewModel.faceVerifyResult.liveness,
                           message)
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
