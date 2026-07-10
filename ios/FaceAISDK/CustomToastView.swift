import Foundation
import SwiftUI

//  Created by anylife on 2025/12/2.

// 定义 Toast 样式
enum ToastStyle {
    case success
    case failure
    var backgroundColor: Color {
        switch self {
        case .success: return Color.faceMain
        case .failure: return Color.red
        }
    }
}
struct CustomToastView: View {
    let message: String
    let style: ToastStyle
    var body: some View {
        VStack {
            HStack {
                Text(message)
                    .foregroundColor(.white)
                    .font(.system(size: 19).bold())
                    .padding(.vertical, 14)
                    .padding(.horizontal, 22)
            }
            .background(style.backgroundColor)
            .cornerRadius(25)
            .shadow(radius: 5)
        }
    }
}
