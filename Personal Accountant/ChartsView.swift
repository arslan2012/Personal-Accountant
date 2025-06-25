import SwiftUI

struct ChartsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.orange)
                Text("Charts")
                    .font(.title)
                    .padding(.top)
                Text("Coming soon...")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .navigationTitle("Charts")
        }
    }
} 