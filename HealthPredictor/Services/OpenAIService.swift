//
//  OpenAIService.swift
//  HealthPredictor
//
//  Created by Stephan  on 05.06.2025.
//

import Foundation

struct Message: Codable {
    let role: String
    let content: String
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }
}

enum OpenAIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

class OpenAIService {

    private static let apiKey: String = { guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
            let dict = plist as? [String: Any],
            let key = dict["OPENAI_API_KEY"] as? String
        else {
            fatalError("OpenAI API key missing in Secrets.plist.")
        }
        return key }()
    private static let baseURL = "https://api.openai.com/v1/chat/completions"

    func sendChat(request: OpenAIRequest) async throws -> String {
        guard let url = URL(string: Self.baseURL) else {
            throw OpenAIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(Self.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let debugBody = String(data: data, encoding: .utf8) ?? "n/a"
            print("OpenAI API Error \(httpResponse.statusCode): \(debugBody)")
            throw OpenAIError.invalidResponse
        }

        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }
}
