import SwiftUI
import FaceAISDK_Core

/**
 * iOS FaceAISDK navigation page, UI is for reference only.
 * iOS FaceAISDK 功能导航页面，UI 仅供参考。
 */
struct FaceAINaviView: View {
    
    // The FaceID value used for saving the face feature. Usually, it's the unique identifier of a person in your business system, such as an account ID or ID card number.
    private let faceID = "yourFaceID";
    
    var onDismiss: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                Color.faceMain.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        
                        // --- 模块一：人脸录入 ---
                        VStack(spacing: 12) {
                            NavigationLink(destination: AddFaceByCamera(
                                faceID: faceID,
                                addFacePerformanceMode: 1,
                                needShowConfirmDialog: true,
                                onDismiss: { result, feature, message in
                                    print("🎆 AddFace   Status: \(result), Feature: \(feature), Message: \(message)")
                                }
                            )) {
                                MenuRowView(icon: "camera.viewfinder", title: "Add Face By Camera")
                            }
                            
                            NavigationLink(destination: AddFaceByImage(
                                faceID: faceID,
                                onDismiss: { result, feature, message in
                                    print("🎆  AddFace  Status: \(result), Feature: \(feature ?? ""), Message: \(message)")
                                }
                            )) {
                                MenuRowView(icon: "photo.on.rectangle.angled", title: "Add Face From Album")
                            }
                        }
                        .padding(.top, 16)
                        
                        // --- 模块二：识别与活体 ---
                        VStack(spacing: 12) {
                            NavigationLink(destination: VerifyFaceView(
                                faceID: faceID,
                                threshold: 0.83,
                                livenessType: 1,
                                motionLiveness: "1,2,3,4,5",
                                motionLivenessTimeOut: 11,
                                motionLivenessSteps:2,
                                
                                onDismiss: {code, similarity, liveness, message in
                                    print("🎆 Face Verify  Status: \(code), Similarity: \(similarity), Liveness: \(liveness), Message: \(message)")
                                }
                            )) {
                                MenuRowView(icon: "faceid", title: "Face Verify & Liveness")
                            }
                            
                            NavigationLink(destination: LivenessDetectView(
                                livenessType: 1,
                                motionLiveness: "1,2,3,4,5",
                                motionLivenessTimeOut: 5,
                                motionLivenessSteps:2,
                                onDismiss: { code, liveness, message in
                                    print("🎆 Liveness Result: \(code), Liveness Score: \(liveness), Message: \(message)")
                                }
                            )) {
                                MenuRowView(icon: "person.crop.circle.badge.checkmark", title: "ONLY Liveness Detection")
                            }
                        }
                        
                        // --- 模块三：功能辅助测试 ---
                        VStack(spacing: 12) {
                            Button(action: {
                                guard let faceFeature = UserDefaults.standard.string(forKey: faceID) else {
                                    print("isFaceFeatureExist？ ： No ! ")
                                    return
                                }
                                print("\n😊FaceFeature: \(faceFeature)")
                            }) {
                                MenuRowView(icon: "magnifyingglass.circle", title: "Is Face Feature Exist", showChevron: false)
                            }
                            
                            NavigationLink(destination: VerifyTwoFaceSimiView()) {
                                MenuRowView(icon: "person.2.crop.square.stack", title: "Verify Two Face Similarity")
                            }
                        }

                        Spacer().frame(height: 24)
                        
                        Button(action: {
                            if let url = URL(string: "https://github.com/FaceAISDK") {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }) {
                            Text("About us")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.8))
                                .underline()
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        onDismiss?()
                        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            ScreenBrightnessHelper.shared.maximizeBrightness()
            withAnimation(.easeInOut(duration: 0.3)) {
                UIScreen.main.brightness = 1.0
            }
        }
    }
}

// MARK: - 统一的菜单行组件
struct MenuRowView: View {
    var icon: String
    var title: LocalizedStringKey
    var showChevron: Bool = true
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .frame(width: 26)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.77)
            
            Spacer(minLength: 4)
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.4))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)   
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }
}
