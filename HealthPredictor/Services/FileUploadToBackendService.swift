//
//  FileUploadToBackendService.swift
//  HealthPredictor
//
//  Created by Stephan on 22.06.2025.
//

import Foundation

struct UploadResponse: Codable {
    let s3Url: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case s3Url = "s3_url"
        case message
    }
}

class FileUploadToBackendService: FileUploadToBackendServiceProtocol {

    static let shared = FileUploadToBackendService()

    private let authService: AuthServiceProtocol

    private init() {
        self.authService = AuthService.shared
    }

    func uploadHealthDataFile(fileData: Data) async throws -> String {
        let fields: [MultipartField] = [
            .file(name: "file", filename: "user_health_data.csv", contentType: "text/csv", data: fileData)
        ]

        let boundary = UUID().uuidString
        let body = MultipartFormBuilder.buildMultipartForm(fields: fields, boundary: boundary)

        var request = try await authService.authenticatedRequest(
            for: "/upload-health-data/",
            method: "POST",
            body: body
        )
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        print("🔧 uploadHealthDataFile: Request prepared with \(body.count) bytes")
        print("🔧 uploadHealthDataFile: Request headers: \(request.allHTTPHeaderFields ?? [:])")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("🔧 uploadHealthDataFile: Response status: \(httpResponse.statusCode)")
            print("🔧 uploadHealthDataFile: Response headers: \(httpResponse.allHeaderFields)")
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("🔧 uploadHealthDataFile: Upload failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("🔧 uploadHealthDataFile: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.uploadFailed
        }

        do {
            let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
            print("🔧 uploadHealthDataFile: Successfully uploaded, S3 URL: \(uploadResponse.s3Url)")
            return uploadResponse.s3Url
        } catch {
            print("🔧 uploadHealthDataFile: Decoding error: \(error)")
            print("🔧 uploadHealthDataFile: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.decodingError
        }
    }

    func buildMultipartRequest(endpoint: String, fileData: Data, additionalFields: [String: String] = [:]) async throws -> URLRequest {
        var fields: [MultipartField] = [
            .file(name: "file", filename: "health_data.csv", contentType: "text/csv", data: fileData)
        ]

        // Add additional text fields
        for (name, value) in additionalFields {
            fields.append(.text(name: name, value: value))
        }

        let boundary = UUID().uuidString
        let body = MultipartFormBuilder.buildMultipartForm(fields: fields, boundary: boundary)

        var request = try await authService.authenticatedRequest(
            for: endpoint,
            method: "POST",
            body: body
        )
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        return request
    }
}