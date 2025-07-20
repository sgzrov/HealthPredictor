//
//  BackendService.swift
//  HealthPredictor
//
//  Created by Stephan  on 22.06.2025.
//

import Foundation
import Combine

class BackendService {

    static let shared = BackendService()

    private let agentService: AgentBackendServiceProtocol
    private let textExtractionService: TextExtractionBackendServiceProtocol
    private let fileUploadService: FileUploadToBackendServiceProtocol

    private init() {
        self.agentService = AgentBackendService.shared
        self.textExtractionService = TextExtractionBackendService.shared
        self.fileUploadService = FileUploadToBackendService.shared
    }

    func analyzeHealthData(csvFilePath: String, userInput: String?, conversationId: String? = nil) async throws -> AsyncStream<String> {
        return try await agentService.analyzeHealthDataStream(csvFilePath: csvFilePath, userInput: userInput, conversationId: conversationId)
    }

    func simpleChat(userInput: String, conversationId: String? = nil) async throws -> AsyncStream<String> {
        return try await agentService.simpleChatStream(userInput: userInput, conversationId: conversationId)
    }

    func generateOutcome(csvFilePath: String, userInput: String) async throws -> AsyncStream<String> {
        return try await agentService.generateOutcomeStream(csvFilePath: csvFilePath, userInput: userInput)
    }

    func summarizeStudy(userInput: String) async throws -> AsyncStream<String> {
        return try await agentService.summarizeStudyStream(userInput: userInput)
    }

    func shouldUseCodeInterpreter(userInput: String) async throws -> String {
        return try await agentService.shouldUseCodeInterpreter(userInput: userInput)
    }

    func extractTextFromFile(fileURL: URL) async throws -> String {
        return try await textExtractionService.extractTextFromFile(fileURL: fileURL)
    }

    func extractTextFromURL(urlString: String) async throws -> String {
        return try await textExtractionService.extractTextFromURL(urlString: urlString)
    }

    func uploadHealthDataFile(fileData: Data) async throws -> String {
        return try await fileUploadService.uploadHealthDataFile(fileData: fileData)
    }
}
