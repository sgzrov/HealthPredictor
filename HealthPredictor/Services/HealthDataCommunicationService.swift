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

    static let shared = HealthDataCommunicationService()

    private init() {}

    private static let baseURL = "http://localhost:8000"  // Local development

    func analyzeHealthData(csvFilePath: String, userInput: String?) async throws -> String {
        guard let url = URL(string: "\(Self.baseURL)/analyze-health-data/") else {
            throw HealthCommunicationError.invalidURL
        }
        guard FileManager.default.fileExists(atPath: csvFilePath) else {
            throw HealthCommunicationError.fileNotFound
        }

        let request = try makeMultipartRequest(url: url, csvFilePath: csvFilePath, userInput: userInput)
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

    func generateOutcome(csvFilePath: String, userInput: String) async throws -> String {
        guard let url = URL(string: "\(Self.baseURL)/generate-outcome/") else {
            throw HealthCommunicationError.invalidURL
        }
        guard FileManager.default.fileExists(atPath: csvFilePath) else {
            throw HealthCommunicationError.fileNotFound
        }

        let request = try makeMultipartRequest(url: url, csvFilePath: csvFilePath, userInput: userInput)
        let session = URLSession(configuration: .default)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw HealthCommunicationError.invalidResponse
        }
        let result = try JSONDecoder().decode([String: String].self, from: data)
        return result["outcome"] ?? ""
    }

    func summarizeStudy(userInput: String) async throws -> String {
        guard let url = URL(string: "\(Self.baseURL)/summarize-study/") else {
            throw HealthCommunicationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["text": userInput]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // 2 minutes
        config.timeoutIntervalForResource = 180 // 3 minutes
        let session = URLSession(configuration: config)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw HealthCommunicationError.invalidResponse
        }
        let result = try JSONDecoder().decode([String: String].self, from: data)
        return result["summary"] ?? ""
    }

    func shouldUseCodeInterpreter(userInput: String) async throws -> String {
        guard let url = URL(string: "\(Self.baseURL)/should-use-code-interpreter/") else {
            throw HealthCommunicationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["user_input": userInput]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let session = URLSession(configuration: .default)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw HealthCommunicationError.invalidResponse
        }

        let result = try JSONDecoder().decode([String: String].self, from: data)
        return result["use_code_interpreter"] ?? "no"
    }

    func simpleChat(userInput: String) async throws -> String {
        guard let url = URL(string: "\(Self.baseURL)/simple-chat/") else {
            throw HealthCommunicationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["user_input": userInput]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let session = URLSession(configuration: .default)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw HealthCommunicationError.invalidResponse
        }

        let result = try JSONDecoder().decode([String: String].self, from: data)
        return result["response"] ?? ""
    }

    private func makeMultipartRequest(url: URL, csvFilePath: String, userInput: String? = nil, studyText: String? = nil) throws -> URLRequest {
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

        if let userInput = userInput, !userInput.isEmpty {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"user_input\"\r\n\r\n")
            body.append(userInput)
            body.append("\r\n")
        }

        if let studyText = studyText, !studyText.isEmpty {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"studytext\"\r\n\r\n")
            body.append(studyText)
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
