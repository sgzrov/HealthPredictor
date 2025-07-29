//
//  BackendService.swift
//  HealthPredictor
//
//  Created by Stephan  on 22.06.2025.
//

import Foundation
import Combine

struct SessionDTO: Decodable {
    let conversationId: String
    let lastActiveDate: String?

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case lastActiveDate = "last_active_date"
    }
}

struct ChatSessionsResponse: Decodable {
    let sessions: [SessionDTO]
}

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

    func chatWithCI(csvFilePath: String, userInput: String, conversationId: String? = nil) async throws -> AsyncStream<String> {
        return try await agentService.chatWithCIStream(csvFilePath: csvFilePath, userInput: userInput, conversationId: conversationId)
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

    func shouldUseCodeInterpreter(userInput: String) async throws -> Bool {
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

extension BackendService {
    func fetchChatSessions(userToken: String, completion: @escaping ([(String, Date?)]) -> Void) {
        print("[DEBUG] fetchChatSessions called with userToken: \(userToken.prefix(12))...")
        guard let url = URL(string: "\(APIConstants.baseURL)/chat/retrieve-chat-sessions/") else {
            print("[DEBUG] Failed to create URL for fetchChatSessions")
            DispatchQueue.main.async { completion([]) }
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[DEBUG] fetchChatSessions error: \(error)")
                DispatchQueue.main.async { completion([]) }
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("[DEBUG] fetchChatSessions HTTP status: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    print("[DEBUG] fetchChatSessions got 401, attempting token refresh")
                    // Try with fresh token
                    Task {
                        do {
                            let freshToken = try await TokenManager.shared.forceRefreshToken()
                            print("[DEBUG] fetchChatSessions retrying with fresh token")
                            self.fetchChatSessions(userToken: freshToken, completion: completion)
                        } catch {
                            print("[DEBUG] fetchChatSessions failed to refresh token: \(error)")
                            DispatchQueue.main.async { completion([]) }
                        }
                    }
                    return
                }
                if httpResponse.statusCode != 200 {
                    print("[DEBUG] fetchChatSessions failed with status: \(httpResponse.statusCode)")
                    DispatchQueue.main.async { completion([]) }
                    return
                }
            }
            guard let data = data else {
                print("[DEBUG] fetchChatSessions no data received")
                DispatchQueue.main.async { completion([]) }
                return
            }
            print("[DEBUG] fetchChatSessions received data: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard let result = try? decoder.decode(ChatSessionsResponse.self, from: data) else {
                print("[DEBUG] fetchChatSessions failed to decode response")
                DispatchQueue.main.async { completion([]) }
                return
            }
            let sessions = result.sessions.map { session in
                let date = session.lastActiveDate.flatMap { dateString in
                    print("[DEBUG] Converting date string: \(dateString)")
                    // Use a more flexible date formatter that can handle microseconds
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)

                    var parsedDate = formatter.date(from: dateString)
                    if parsedDate == nil {
                        // Try without microseconds
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                        parsedDate = formatter.date(from: dateString)
                    }
                    if parsedDate == nil {
                        // Try ISO8601 formatter as fallback
                        parsedDate = ISO8601DateFormatter().date(from: dateString)
                    }
                    return parsedDate
                }
                print("[DEBUG] Session \(session.conversationId): original date string = \(session.lastActiveDate ?? "nil"), converted date = \(date?.description ?? "nil")")
                return (session.conversationId, date)
            }
            print("[DEBUG] fetchChatSessions found \(sessions.count) sessions")
            DispatchQueue.main.async { completion(sessions) }
        }.resume()
    }

    func fetchChatHistory(conversationId: String, userToken: String, completion: @escaping ([ChatMessage]) -> Void) {
        print("[DEBUG] fetchChatHistory called with userToken: \(userToken.prefix(12))... conversationId: \(conversationId)")
        guard let url = URL(string: "\(APIConstants.baseURL)/chat/all-messages/\(conversationId)") else {
            print("[DEBUG] Failed to create URL for fetchChatHistory")
            DispatchQueue.main.async { completion([]) }
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[DEBUG] fetchChatHistory error: \(error)")
                DispatchQueue.main.async { completion([]) }
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("[DEBUG] fetchChatHistory HTTP status: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    print("[DEBUG] fetchChatHistory got 401, attempting token refresh")
                    // Try with fresh token
                    Task {
                        do {
                            let freshToken = try await TokenManager.shared.forceRefreshToken()
                            print("[DEBUG] fetchChatHistory retrying with fresh token")
                            self.fetchChatHistory(conversationId: conversationId, userToken: freshToken, completion: completion)
                        } catch {
                            print("[DEBUG] fetchChatHistory failed to refresh token: \(error)")
                            DispatchQueue.main.async { completion([]) }
                        }
                    }
                    return
                }
                if httpResponse.statusCode != 200 {
                    print("[DEBUG] fetchChatHistory failed with status: \(httpResponse.statusCode)")
                    DispatchQueue.main.async { completion([]) }
                    return
                }
            }
            guard let data = data,
                  let messages = try? decoder.decode([ChatMessage].self, from: data) else {
                print("[DEBUG] fetchChatHistory failed to decode response or no data")
                DispatchQueue.main.async { completion([]) }
                return
            }
            print("[DEBUG] fetchChatHistory found \(messages.count) messages for conversation \(conversationId)")
            DispatchQueue.main.async { completion(messages) }
        }.resume()
    }

    func fetchStudies(userToken: String, completion: @escaping ([Study]) -> Void) {
        print("[DEBUG] fetchStudies called with userToken: \(userToken.prefix(12))...")
        guard let url = URL(string: "\(APIConstants.baseURL)/studies/retrieve-user-studies") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let studies = try? decoder.decode([Study].self, from: data) else { return }
            DispatchQueue.main.async { completion(studies) }
        }.resume()
    }

    func createStudy(userToken: String, title: String, summary: String = "", outcome: String = "", completion: @escaping (Study?) -> Void) {
        print("[DEBUG] createStudy called with userToken: \(userToken.prefix(12))...")
        guard let url = URL(string: "\(APIConstants.baseURL)/studies/add-new-study") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(userToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "title=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&summary=\(summary.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&outcome=\(outcome.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = body.data(using: .utf8)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let study = try? decoder.decode(Study.self, from: data) else { return }
            DispatchQueue.main.async { completion(study) }
        }.resume()
    }
}
