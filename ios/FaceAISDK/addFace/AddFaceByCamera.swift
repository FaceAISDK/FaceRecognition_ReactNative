import SwiftUI
import AVFoundation
import FaceAISDK_Core

@MainActor
var FaceCameraSize: CGFloat {
    14 * min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) / 20
}

public struct AddFaceByCamera: View {
    let faceID: String
    let addFacePerformanceMode: Int //Alternate fields备用字段
    let needShowConfirmDialog: Bool //是否需要显示确认框还是直接提取特征值确认
    
    // callback Status , FaceFeature,message
    let onDismiss: (Int, String,String) -> Void //status 0 cancel， 1 success
    
    var autoControlBrightness: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: AddFaceByCameraModel = AddFaceByCameraModel()
    
    // 根据状态码转换为对应的文字提示
    private func localizedTips(for code: Int) -> String {
        let key = "Face_Tips_Code_\(code)"
        let defaultValue = "Add Face Tips Code=\(code)"
        return NSLocalizedString(key, value: defaultValue, comment: "")
    }
    
    private func speakTipsIfNeeded(for code: Int) {
        guard code != 0 && code != 1 && code != 11 else { return }
        TTSPlayer.shared.speak(localizedTips(for: code))
    }
    
    // 统一处理人脸录入成功的逻辑
    private func saveFaceData() {
        // Optional
         if FaceImageManager.saveFaceImage(faceName: faceID, faceImage: viewModel.croppedFaceImage) {
             print("saveFaceImage success")
         }
                
        // Save face feature 保存人脸特征信息，
        UserDefaults.standard.set(viewModel.faceFeatureBySDKCamera, forKey: faceID)
        
        // Close Page, CallBack
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onDismiss(1, viewModel.faceFeatureBySDKCamera,"Add Face Success")
            dismiss()
        }
        
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        onDismiss(0, "","User Cancel")
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
                
                // Status Tips
                Text(localizedTips(for: viewModel.sdkInterfaceTips.code))
                    .font(.system(size: 19).bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundColor(.white)
                    .background(Color.faceMain)
                    .cornerRadius(20)
                
                ZStack {
                    // Camera
                    FaceSDKCameraView(session: viewModel.captureSession, cameraSize: FaceCameraSize)
                        .aspectRatio(1.0, contentMode: .fit)
                        .clipShape(Circle())
                        .background(Circle().fill(Color.white))
                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                    
                    // Confirm Add Face
                    if viewModel.readyConfirmFace, needShowConfirmDialog {
                        //Color.black.opacity(0.3).clipShape(Circle())

                        ConfirmAddFaceDialog(
                            viewModel: viewModel,
                            cameraSize: FaceCameraSize,
                            onConfirm: {
                                saveFaceData()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: FaceCameraSize, height: FaceCameraSize)
                .animation(.easeInOut(duration: 0.25), value: viewModel.readyConfirmFace)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            
            .onAppear {
                if autoControlBrightness {
                    ScreenBrightnessHelper.shared.maximizeBrightness()
                }
                viewModel.initAddFace()
            }
            .onDisappear {
                if autoControlBrightness {
                    ScreenBrightnessHelper.shared.restoreBrightness()
                }
                viewModel.stopAddFace()
            }
            .onChange(of: viewModel.sdkInterfaceTips.code) { newValue in
                speakTipsIfNeeded(for: newValue)
            }
            .onChange(of: viewModel.readyConfirmFace) { _ in      
                print("viewModel.readyConfirmFace is now \(viewModel.readyConfirmFace)")

                guard viewModel.readyConfirmFace else { return }
                if needShowConfirmDialog {
                    print("show Confirm Dialog")
                } else { //不需要确认框就直接保存提取人脸数据
                    saveFaceData()
                }
            }
        }
    }
}


struct ConfirmAddFaceDialog: View {
    let viewModel: AddFaceByCameraModel
    let cameraSize: CGFloat
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            
            Text("Confirm Add Face")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color.faceMain)
                .padding(.top, 18)
            
            //
            Image(uiImage: viewModel.originFaceImage)
                .resizable()
                .scaledToFill()
                .frame(width: 190, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            Text("Ensure face is clear")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 按钮组
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.reInit()
                }) {
                    Text("Retry")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(Color.gray.opacity(0.6))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    onConfirm()
                }) {
                    Text("Confirm")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.faceMain)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .padding(.top, 8)
        }
        .frame(width: cameraSize * 1.22)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}
