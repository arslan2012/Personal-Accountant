import OpenAI
import PhotosUI
import SwiftUI

struct ImageUploadView: View {
  @Environment(\.dismiss) private var dismiss

  // Image upload states
  @State private var selectedImage: PhotosPickerItem? = nil
  @State private var imageData: Data? = nil
  @State private var isUploadingImage = false
  @State private var showingImagePicker = false
  @State private var showingCamera = false
  @State private var uploadError: String? = nil

  // Transaction review states
  @State private var extractedTransactions: [TransactionData] = []
  @State private var showingReview = false

  // Callbacks
  let onSingleTransaction: (TransactionData) -> Void
  let onMultipleTransactions: ([TransactionData]) -> Void

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        // Header
        VStack(spacing: 8) {
          Image(systemName: "camera.viewfinder")
            .font(.system(size: 60))
            .foregroundColor(.blue)

          Text("Upload Receipt")
            .font(.title2)
            .fontWeight(.semibold)

          Text(
            "Take a photo or select an image from your library to automatically extract transaction details"
          )
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
        }
        .padding(.top, 40)

        Spacer()

        // Upload options
        if isUploadingImage {
          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.2)
            Text("Processing image...")
              .font(.headline)
              .foregroundColor(.secondary)
          }
          .padding()
        } else {
          VStack(spacing: 16) {
            // Camera button
            Button(action: {
              showingCamera = true
            }) {
              HStack {
                Image(systemName: "camera.fill")
                  .font(.title3)
                Text("Take Photo")
                  .font(.headline)
              }
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.blue)
              .cornerRadius(12)
            }

            // Photo library button
            Button(action: {
              showingImagePicker = true
            }) {
              HStack {
                Image(systemName: "photo.on.rectangle")
                  .font(.title3)
                Text("Select from Library")
                  .font(.headline)
              }
              .foregroundColor(.blue)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.blue.opacity(0.1))
              .cornerRadius(12)
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(Color.blue, lineWidth: 2)
              )
            }
          }
          .padding(.horizontal, 24)
        }

        // Error message
        if let error = uploadError {
          VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
              .foregroundColor(.red)
            Text(error)
              .font(.caption)
              .foregroundColor(.red)
              .multilineTextAlignment(.center)
          }
          .padding()
          .background(Color.red.opacity(0.1))
          .cornerRadius(8)
          .padding(.horizontal, 24)
        }

        Spacer()

        // Tips section
        VStack(alignment: .leading, spacing: 8) {
          Text("Tips for better results:")
            .font(.subheadline)
            .fontWeight(.semibold)

          VStack(alignment: .leading, spacing: 4) {
            Text("• Ensure good lighting")
            Text("• Keep receipt flat and fully visible")
            Text("• Avoid shadows and glare")
            Text("• Make sure text is clear and readable")
          }
          .font(.caption)
          .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
      }
      .navigationTitle("Upload Receipt")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .sheet(isPresented: $showingCamera) {
        CameraView { image in
          Task {
            await processSelectedImage(image)
          }
        }
      }
      .sheet(isPresented: $showingReview) {
        TransactionReviewView(
          transactions: extractedTransactions,
          onSave: { transactions in
            // Handle saving based on count
            if transactions.count == 1 {
              onSingleTransaction(transactions[0])
            } else {
              onMultipleTransactions(transactions)
            }
            // Dismiss the ImageUploadView after saving
            dismiss()
          },
          onCancel: {
            // Just close the review view, stay on ImageUploadView
            showingReview = false
          }
        )
      }
      .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
      .onChange(of: selectedImage) { _, newItem in
        Task {
          if let newItem = newItem {
            await loadImageData(from: newItem)
          }
        }
      }
    }
  }

  // MARK: - Image Processing
  private func loadImageData(from item: PhotosPickerItem) async {
    guard let data = try? await item.loadTransferable(type: Data.self) else {
      await MainActor.run {
        uploadError = "Failed to load image"
      }
      return
    }

    guard let image = UIImage(data: data) else {
      await MainActor.run {
        uploadError = "Invalid image format"
      }
      return
    }

    await processSelectedImage(image)
  }

  private func processSelectedImage(_ image: UIImage) async {
    await MainActor.run {
      isUploadingImage = true
      uploadError = nil
    }

    do {
      let transactions = try await ImageToTransactionAPI.shared.processReceiptImage(image)

      await MainActor.run {
        isUploadingImage = false

        if transactions.isEmpty {
          uploadError = "No transactions found in the image"
        } else {
          // Store transactions and show review view
          extractedTransactions = transactions
          showingReview = true
        }
      }
    } catch {
      await MainActor.run {
        isUploadingImage = false
        uploadError = error.localizedDescription
      }
    }
  }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
  let onImageSelected: (UIImage) -> Void
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: CameraView

    init(_ parent: CameraView) {
      self.parent = parent
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let image = info[.originalImage] as? UIImage {
        parent.onImageSelected(image)
      }
      parent.dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.dismiss()
    }
  }
}

// MARK: - Transaction Data Structure
struct TransactionData {
  let category: String
  let amount: Double
  let currency: String
  let detail: String
  let date: Date
  let type: TransactionType
}

// MARK: - Image to Transaction API Service
class ImageToTransactionAPI {
  static let shared = ImageToTransactionAPI()

  private init() {}

  func processReceiptImage(_ image: UIImage) async throws -> [TransactionData] {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      throw APIError.invalidImage
    }
    let openAI = OpenAI(
      apiToken: OPENAI_API_KEY
    )

    let chatQuery = ChatQuery(
      messages: [
        .system(
          .init(
            content: .textContent(
              "You are a receipt parser. Extract transaction information from the provided receipt image. Return all transactions found in the receipt. For each transaction, provide the category, amount, currency, description, date, and type (spending/income). If no clear date is visible, use the current date."
            ))),
        .user(
          .init(
            content: .contentParts([
              .image(.init(imageUrl: .init(imageData: imageData, detail: .high)))
            ]))),
      ],
      model: .gpt4_1_nano,
      responseFormat: .derivedJsonSchema(name: "transaction-list", type: TransactionListInfo.self)
    )

    let response = try await openAI.chats(query: chatQuery)

    guard let content = response.choices.first?.message.content else {
      throw APIError.invalidResponse
    }

    guard let jsonData = content.data(using: .utf8) else {
      throw APIError.decodingError
    }

    let transactionListInfo = try JSONDecoder().decode(TransactionListInfo.self, from: jsonData)

    return transactionListInfo.transactions.map { apiTransaction in
      TransactionData(
        category: apiTransaction.category,
        amount: apiTransaction.amount,
        currency: apiTransaction.currency,
        detail: apiTransaction.detail,
        date: ISO8601DateFormatter().date(from: apiTransaction.date) ?? Date(),
        type: apiTransaction.type
      )
    }
  }
}

// MARK: - API Errors
enum APIError: LocalizedError {
  case invalidImage
  case invalidResponse
  case decodingError

  var errorDescription: String? {
    switch self {
    case .invalidImage:
      return "Invalid image format"
    case .invalidResponse:
      return "Invalid server response"
    case .decodingError:
      return "Failed to decode server response"
    }
  }
}
