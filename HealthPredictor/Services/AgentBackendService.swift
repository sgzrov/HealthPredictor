//
//  AgentBackendService.swift
//  HealthPredictor
//
//  Created by Stephan on 22.06.2025.
//

import Foundation

struct CodeInterpreterResponse: Codable {
    let useCodeInterpreter: Bool

    enum CodingKeys: String, CodingKey {
        case useCodeInterpreter = "use_code_interpreter"
    }
}

class AgentBackendService: AgentBackendServiceProtocol {

    static let shared = AgentBackendService()

    private let authService: AuthServiceProtocol
    private let sseService: SSEServiceProtocol
    private let userFileCacheService: UserFileCacheServiceProtocol
    private let fileUploadService: FileUploadToBackendServiceProtocol

    private init() {
        self.authService = AuthService.shared
        self.sseService = SSEService.shared
        self.userFileCacheService = UserFileCacheService.shared
        self.fileUploadService = FileUploadToBackendService.shared
    }

    // MARK: - Code Interpreter Detection
    func shouldUseCodeInterpreter(userInput: String) async throws -> String {
        let body: [String: Any] = ["user_input": userInput]
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let request = try await authService.authenticatedRequest(
            for: "/should-use-code-interpreter/",
            method: "POST",
            body: jsonData
        )

        print("🔧 shouldUseCodeInterpreter: Request headers: \(request.allHTTPHeaderFields ?? [:])")
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("🔧 shouldUseCodeInterpreter: Response status: \(httpResponse.statusCode)")
        }

        do {
            let response = try JSONDecoder().decode(CodeInterpreterResponse.self, from: data)
            return response.useCodeInterpreter ? "yes" : "no"
        } catch {
            print("🔧 shouldUseCodeInterpreter: Decoding error: \(error)")
            print("🔧 shouldUseCodeInterpreter: Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.decodingError
        }
    }

    // MARK: - Health Data Analysis
    func analyzeHealthDataStream(csvFilePath: String, userInput: String?, conversationId: String?) async throws -> AsyncStream<String> {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: csvFilePath) else {
            print("🔧 analyzeHealthDataStream: CSV file not found at \(csvFilePath)")
            throw NetworkError.fileNotFound
        }

        print("🔧 analyzeHealthDataStream: Reading CSV from \(csvFilePath)")

        guard let csvData = fileManager.contents(atPath: csvFilePath) else {
            throw NetworkError.fileNotFound
        }

        print("🔧 analyzeHealthDataStream: CSV data size: \(csvData.count) bytes")

        var additionalFields: [String: String] = [:]
        if let userInput = userInput {
            additionalFields["user_input"] = userInput
        }
        if let conversationId = conversationId {
            additionalFields["conversation_id"] = conversationId
        }

        let request = try await fileUploadService.buildMultipartRequest(
            endpoint: "/analyze-health-data/",
            fileData: csvData,
            additionalFields: additionalFields
        )

        print("🔧 analyzeHealthDataStream: Request prepared with \(request.httpBody?.count ?? 0) bytes")
        print("🔧 analyzeHealthDataStream: Request headers: \(request.allHTTPHeaderFields ?? [:])")
        return try await sseService.streamSSE(request: request)
    }

    // MARK: - Simple Chat
    func simpleChatStream(userInput: String, conversationId: String?) async throws -> AsyncStream<String> {
        let body: [String: Any] = ["user_input": userInput]
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = try await authService.authenticatedRequest(
            for: "/simple-chat/",
            method: "POST",
            body: jsonData
        )

        if let conversationId = conversationId {
            request.setValue(conversationId, forHTTPHeaderField: "X-Conversation-ID")
        }

        return try await sseService.streamSSE(request: request)
    }

    // MARK: - Outcome Generation
    func generateOutcomeStream(csvFilePath: String, userInput: String) async throws -> AsyncStream<String> {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: csvFilePath) else {
            throw NetworkError.fileNotFound
        }

        guard let csvData = fileManager.contents(atPath: csvFilePath) else {
            throw NetworkError.fileNotFound
        }

        let request = try await fileUploadService.buildMultipartRequest(
            endpoint: "/generate-outcome/",
            fileData: csvData,
            additionalFields: ["user_input": userInput]
        )

        return try await sseService.streamSSE(request: request)
    }

    // MARK: - Study Summarization
    func summarizeStudyStream(userInput: String) async throws -> AsyncStream<String> {
        let body: [String: Any] = ["user_input": userInput]
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let request = try await authService.authenticatedRequest(
            for: "/summarize-study/",
            method: "POST",
            body: jsonData
        )

        return try await sseService.streamSSE(request: request)
    }


}