//
//  HealthDataCommunicationService.swift
//  HealthPredictor
//
//  Created by Stephan  on 22.06.2025.
//

import Foundation

struct HealthCommunicationResponse: Codable {
    let analysis: String
}

enum HealthCommunicationError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case fileNotFound
    case uploadFailed
}

class HealthDataCommunicationService {
    private static let baseURL = "http://192.168.68.60:8000"  // My computer IP address

    func analyzeHealthData(csvFilePath: String, question: String?) async throws -> String {
        guard let url = URL(string: "\(Self.baseURL)/analyze-health-data/") else {
            throw HealthCommunicationError.invalidURL
        }
        guard FileManager.default.fileExists(atPath: csvFilePath) else {
            throw HealthCommunicationError.fileNotFound
        }

        let request = try makeMultipartRequest(url: url, csvFilePath: csvFilePath, question: question)
        let session = URLSession(configuration: .default)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let debugBody = String(data: data, encoding: .utf8) ?? "n/a"
            print("Health Analysis API Error: \(debugBody)")
            throw HealthCommunicationError.invalidResponse
        }

        do {
            let result = try JSONDecoder().decode(HealthCommunicationResponse.self, from: data)
            return result.analysis
        } catch {
            print("Decoding error: \(error)")
            throw HealthCommunicationError.decodingError
        }
    }

    private func makeMultipartRequest(url: URL, csvFilePath: String, question: String?) throws -> URLRequest {
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let csvData = try Data(contentsOf: URL(fileURLWithPath: csvFilePath))
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"user_health_data.csv\"\r\n")
        body.append("Content-Type: text/csv\r\n\r\n")
        body.append(csvData)
        body.append("\r\n")

        if let question = question, !question.isEmpty {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"question\"\r\n\r\n")
            body.append(question)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        return request
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
