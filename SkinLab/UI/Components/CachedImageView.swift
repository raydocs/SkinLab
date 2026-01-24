//
//  CachedImageView.swift
//  SkinLab
//
//  SwiftUI view for displaying cached images with automatic loading.
//

import SwiftUI

/// A SwiftUI view that displays an image with automatic caching
struct CachedImageView: View {
    let path: String?
    let placeholder: Image
    let contentMode: ContentMode

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    init(
        path: String?,
        placeholder: Image = Image(systemName: "photo"),
        contentMode: ContentMode = .fill
    ) {
        self.path = path
        self.placeholder = placeholder
        self.contentMode = contentMode
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: path) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let path = path, !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        // Load from cache (memory or disk)
        if let cached = await ImageCache.shared.loadImage(fromPath: path) {
            await MainActor.run {
                loadedImage = cached
            }
        }
    }
}

/// A thumbnail-specific cached image view
struct CachedThumbnailView: View {
    let path: String?
    let placeholder: Image
    let size: CGSize

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    init(
        path: String?,
        placeholder: Image = Image(systemName: "photo"),
        size: CGSize = ImageCompressionConfig.defaultThumbnailSize
    ) {
        self.path = path
        self.placeholder = placeholder
        self.size = size
    }

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .task(id: path) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let path = path, !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        // Try loading thumbnail first using extension-safe path helper
        let thumbnailPath = ImageCache.thumbnailPath(for: path)

        if let cached = await ImageCache.shared.loadImage(fromPath: thumbnailPath) {
            await MainActor.run {
                loadedImage = cached
            }
            return
        }

        // Fall back to full image if thumbnail doesn't exist
        if let cached = await ImageCache.shared.loadImage(fromPath: path) {
            await MainActor.run {
                loadedImage = cached
            }
        }
    }
}

// MARK: - Preview
#Preview("CachedImageView") {
    VStack(spacing: 20) {
        CachedImageView(path: nil)
            .frame(width: 200, height: 200)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12))

        CachedThumbnailView(path: nil)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding()
}
