//
//  HealthDataCommunicationService.swift
//  HealthPredictor
//
//  Created by Stephan  on 22.06.2025.
//

import Foundation
import Combine

struct HealthCommunicationResponse: Codable {
    let analysis: String
}

enum HealthCommunicationError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case fileNotFound
    case uploadFailed
    case streamingError(String)
    case authenticationFailed
}

struct StreamingChunk: Codable {
    let content: String?
    let done: Bool
    let error: String?
}

struct CodeInterpreterResponse: Codable {
    let useCodeInterpreter: Bool

    enum CodingKeys: String, CodingKey {
        case useCodeInterpreter = "use_code_interpreter"
    }
}

class HealthDataCommunicationService {

    static let shared = HealthDataCommunicationService()
    private let authService = AuthService.shared

    private init() {}

    private static let baseURL = "http://192.168.68.60:8000"

    private func appendMultipartField(
        to body: inout Data,
        name: String,
        value: String? = nil,
        filename: String? = nil,
        contentType: String? = nil,
        data: Data? = nil,
        boundary: String
    ) {
        body.append("--\(boundary)\r\n")
        if let filename = filename, let contentType = contentType, let data = data {
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(contentType)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        } else if let value = value {
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
    }

    func analyzeHealthDataStream(csvFilePath: String, userInput: String?, conversationId: String? = nil) async throws -> AsyncStream<String> {
        guard FileManager.default.fileExists(atPath: csvFilePath) else {
            throw HealthCommunicationError.fileNotFound
        }

        let boundary = UUID().uuidString
        var body = Data()

        let csvData = try Data(contentsOf: URL(fileURLWithPath: csvFilePath))
        appendMultipartField(to: &body, name: "file", filename: "health_data.csv", contentType: "text/csv", data: csvData, boundary: boundary)
        if let userInput = userInput {
            appendMultipartField(to: &body, name: "user_input", value: userInput, boundary: boundary)
        }
        if let conversationId = conversationId {
            appendMultipartField(to: &body, name: "conversation_id", value: conversationId, boundary: boundary)
        }
        body.append("--\(boundary)--\r\n")

        var request = try await authService.authenticatedRequest(
            for: "/analyze-health-data/",
            method: "POST",
            body: body
        )
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        return try await streamSSE(request: request)
    }

    func simpleChatStream(userInput: String, conversationId: String? = nil) async throws -> AsyncStream<String> {
        var body: [String: Any] = ["user_input": userInput]
        if let conversationId = conversationId {
            body["conversation_id"] = conversationId
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let request = try await authService.authenticatedRequest(
            for: "/simple-chat/",
            method: "POST",
            body: jsonData
        )

        return try await streamSSE(request: request)
    }

    func generateOutcomeStream(csvFilePath: String, userInput: String) async throws -> AsyncStream<String> {
        guard FileManager.default.fileExists(atPath: csvFilePath) else {
            throw HealthCommunicationError.fileNotFound
        }

        let boundary = UUID().uuidString
        var body = Data()

        let csvData = try Data(contentsOf: URL(fileURLWithPath: csvFilePath))
        appendMultipartField(to: &body, name: "file", filename: "health_data.csv", contentType: "text/csv", data: csvData, boundary: boundary)
        appendMultipartField(to: &body, name: "user_input", value: userInput, boundary: boundary)
        body.append("--\(boundary)--\r\n")

        var request = try await authService.authenticatedRequest(
            for: "/generate-outcome/",
            method: "POST",
            body: body
        )
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        return try await streamSSE(request: request)
    }

    func summarizeStudyStream(userInput: String) async throws -> AsyncStream<String> {
        let body: [String: Any] = ["text": userInput]
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let request = try await authService.authenticatedRequest(
            for: "/summarize-study/",
            method: "POST",
            body: jsonData
        )

        return try await streamSSE(request: request)
    }

    func shouldUseCodeInterpreter(userInput: String) async throws -> String {
        let body: [String: Any] = ["user_input": userInput]
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let request = try await authService.authenticatedRequest(
            for: "/should-use-code-interpreter/",
            method: "POST",
            body: jsonData
        )

        let (data, _) = try await URLSession.shared.data(for: request)
        do {
            let response = try JSONDecoder().decode(CodeInterpreterResponse.self, from: data)
            return response.useCodeInterpreter ? "yes" : "no"
        } catch {
            throw HealthCommunicationError.decodingError
        }
    }

    private func streamSSE(request: URLRequest) async throws -> AsyncStream<String> {
        return AsyncStream<String> { continuation in
            let sseClient = SSEClientService()
            let publisher = sseClient.connect(with: request)

            let cancellable = publisher
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            continuation.finish()
                        case .failure(let error):
                            if let urlError = error as? URLError {
                                if urlError.code == .userAuthenticationRequired {
                                    continuation.yield("Error: Authentication required. Please sign in again.")
                                } else {
                                    continuation.yield("Error: \(error.localizedDescription)")
                                }
                            } else {
                                continuation.yield("Error: \(error.localizedDescription)")
                            }
                            continuation.finish()
                        }
                    },
                    receiveValue: { event in
                        self.handleSSEEvent(event, continuation: continuation)
                    }
                )

            continuation.onTermination = { _ in
                cancellable.cancel()
                sseClient.disconnect()
            }
        }
    }

    private func handleSSEEvent(_ event: SSEEvent, continuation: AsyncStream<String>.Continuation) {
        let authErrorKeywords = ["401", "403", "unauthorized"]

        func isAuthError(_ text: String) -> Bool {
            authErrorKeywords.contains { text.localizedCaseInsensitiveContains($0) }
        }

        switch event.type {
        case .message:
            let jsonData = Data(event.data.utf8)
            if let chunk = try? JSONDecoder().decode(StreamingChunk.self, from: jsonData) {
                if let error = chunk.error {
                    if isAuthError(error) {
                        continuation.yield("Error: Authentication failed. Please sign in again.")
                    } else {
                        continuation.yield("Error: \(error)")
                    }
                    return
                }
                if let content = chunk.content, !content.isEmpty {
                    continuation.yield(content)
                }
                if chunk.done {
                    continuation.finish()
                }
            }
        case .error:
            if isAuthError(event.data) {
                continuation.yield("Error: Authentication failed. Please sign in again.")
            } else {
                continuation.yield("Error: \(event.data)")
            }
            continuation.finish()
        case .done:
            continuation.finish()
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
