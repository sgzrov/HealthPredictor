//
//  AIService.swift
//  HealthPredictor
//
//  Created by Stephan  on 05.06.2025.
//

import Foundation

class AIService {

    private static let apiKey: String = {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
            let dict = plist as? [String: Any],
            let key = dict["OPENAI_API_KEY"] as? String
        else {
            fatalError("OpenAI API key missing in Secrets.plist.")
        }
        return key
    }()
    private static let baseURL = "https://api.openai.com/v1/chat/completions"

    func sendChat(messages: [[String: String]], model: String = "gpt-4o", temperature: Double = 0.5, maxTokens: Int = 150) async throws -> String {
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": maxTokens
        ]

        guard let url = URL(string: Self.baseURL) else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Self.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OpenAIError.invalidResponse
        }

        let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }
}

enum OpenAIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

struct OpenAIResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String
    }
}
