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
        print("🔍 AGENT: analyzeHealthDataStream called")
        print("🔍 AGENT: csvFilePath: \(csvFilePath)")
        print("🔍 AGENT: userInput: \(userInput ?? "nil")")
        print("🔍 AGENT: conversationId: \(conversationId ?? "nil")")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: csvFilePath) else {
            print("🔍 AGENT: CSV file not found at \(csvFilePath)")
            throw NetworkError.fileNotFound
        }

        print("🔍 AGENT: CSV file exists, reading data")
        print("🔍 AGENT: Reading CSV from \(csvFilePath)")

        guard let csvData = fileManager.contents(atPath: csvFilePath) else {
            print("🔍 AGENT: Failed to read CSV file contents")
            throw NetworkError.fileNotFound
        }

        print("🔍 AGENT: CSV data size: \(csvData.count) bytes")

        // First upload the file to get S3 URL
        print("🔍 AGENT: Starting file upload to S3")
        let s3Url = try await fileUploadService.uploadHealthDataFile(fileData: csvData)
        print("🔍 AGENT: File uploaded to S3: \(s3Url)")

        // Now send the S3 URL to the analyze endpoint
        print("🔍 AGENT: Building request body")
        var body: [String: Any] = ["s3_url": s3Url]
        if let userInput = userInput {
            body["user_input"] = userInput
            print("🔍 AGENT: Added userInput to body")
        }
        if let conversationId = conversationId {
            body["conversation_id"] = conversationId
            print("🔍 AGENT: Added conversationId to body")
        }

        print("🔍 AGENT: Final request body: \(body)")
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        print("🔍 AGENT: JSON data created, size: \(jsonData.count) bytes")

        print("🔍 AGENT: Creating authenticated request")
        var request = try await authService.authenticatedRequest(
            for: "/analyze-health-data/",
            method: "POST",
            body: jsonData
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let conversationId = conversationId {
            request.setValue(conversationId, forHTTPHeaderField: "X-Conversation-ID")
        }

        print("🔍 AGENT: Request prepared with \(jsonData.count) bytes")
        print("🔍 AGENT: Request headers: \(request.allHTTPHeaderFields ?? [:])")
        print("🔍 AGENT: Request body: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
        print("🔍 AGENT: Request URL: \(request.url?.absoluteString ?? "nil")")

        print("🔍 AGENT: Starting SSE stream")
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

        // First upload the file to get S3 URL
        let s3Url = try await fileUploadService.uploadHealthDataFile(fileData: csvData)
        print("🔧 generateOutcomeStream: File uploaded to S3: \(s3Url)")

        // Now send the S3 URL to the generate-outcome endpoint
        let body: [String: Any] = [
            "s3_url": s3Url,
            "user_input": userInput
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = try await authService.authenticatedRequest(
            for: "/generate-outcome/",
            method: "POST",
            body: jsonData
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return try await sseService.streamSSE(request: request)
    }

    // MARK: - Study Summarization
    func summarizeStudyStream(userInput: String) async throws -> AsyncStream<String> {
        let body: [String: Any] = ["text": userInput]
        let jsonData = try JSONSerialization.data(withJSONObject: body)

        let request = try await authService.authenticatedRequest(
            for: "/summarize-study/",
            method: "POST",
            body: jsonData
        )

        return try await sseService.streamSSE(request: request)
    }

}