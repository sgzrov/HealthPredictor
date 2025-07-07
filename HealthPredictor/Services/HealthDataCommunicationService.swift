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

    private init() {}

    private static let baseURL = "http://localhost:8000"  // Local development

    func analyzeHealthDataStream(csvFilePath: String, userInput: String?, conversationId: String? = nil) async throws -> AsyncStream<String> {
        guard let url = URL(string: "\(Self.baseURL)/analyze-health-data/") else {
            throw HealthCommunicationError.invalidURL
        }

        guard FileManager.default.fileExists(atPath: csvFilePath) else {
            throw HealthCommunicationError.fileNotFound
        }

        let request = try makeMultipartRequest(url: url, csvFilePath: csvFilePath, userInput: userInput, conversationId: conversationId)
        return try await streamSSE(request: request)
    }

    func simpleChatStream(userInput: String, conversationId: String? = nil) async throws -> AsyncStream<String> {
        guard let url = URL(string: "\(Self.baseURL)/simple-chat/") else {
            throw HealthCommunicationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["user_input": userInput]
        if let conversationId = conversationId {
            body["conversation_id"] = conversationId
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return try await streamSSE(request: request)
    }

    func generateOutcomeStream(csvFilePath: String, userInput: String) async throws -> AsyncStream<String> {
        guard let url = URL(string: "\(Self.baseURL)/generate-outcome/") else {
            throw HealthCommunicationError.invalidURL
        }

        guard FileManager.default.fileExists(atPath: csvFilePath) else {
            throw HealthCommunicationError.fileNotFound
        }

        let request = try makeMultipartRequest(url: url, csvFilePath: csvFilePath, userInput: userInput)
        return try await streamSSE(request: request)
    }

    func summarizeStudyStream(userInput: String) async throws -> AsyncStream<String> {
        guard let url = URL(string: "\(Self.baseURL)/summarize-study/") else {
            throw HealthCommunicationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["text": userInput]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        return try await streamSSE(request: request)
    }

    func shouldUseCodeInterpreter(userInput: String) async throws -> String {
        guard let url = URL(string: "\(Self.baseURL)/should-use-code-interpreter/") else {
            throw HealthCommunicationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["user_input": userInput]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CodeInterpreterResponse.self, from: data)
        return response.useCodeInterpreter ? "yes" : "no"
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
                            continuation.yield("Error: \(error.localizedDescription)")
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
        switch event.type {
        case .message:
            let jsonData = Data(event.data.utf8)
            if let chunk = try? JSONDecoder().decode(StreamingChunk.self, from: jsonData) {
                if let error = chunk.error {
                    continuation.yield("Error: \(error)")
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
            continuation.yield("Error: \(event.data)")
            continuation.finish()
        case .done:
            continuation.finish()
        }
    }

    // Multipart request with file data, user input, conversation id, and boundaries (to separate each part)
    private func makeMultipartRequest(url: URL, csvFilePath: String, userInput: String?, conversationId: String? = nil) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        let csvData = try Data(contentsOf: URL(fileURLWithPath: csvFilePath))
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"health_data.csv\"\r\n".utf8))
        body.append(Data("Content-Type: text/csv\r\n\r\n".utf8))
        body.append(csvData)
        body.append(Data("\r\n".utf8))

        if let userInput = userInput {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"user_input\"\r\n\r\n".utf8))
            body.append(Data("\(userInput)\r\n".utf8))
        }

        if let conversationId = conversationId {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"conversation_id\"\r\n\r\n".utf8))
            body.append(Data("\(conversationId)\r\n".utf8))
        }

        body.append(Data("--\(boundary)--\r\n".utf8))
        request.httpBody = body

        return request
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
