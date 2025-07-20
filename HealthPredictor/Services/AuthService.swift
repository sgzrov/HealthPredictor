//
//  AuthService.swift
//  HealthPredictor
//
//  Created by Stephan on 13.07.2025.
//

import Foundation
import Clerk

class AuthService: AuthServiceProtocol {

    static let shared = AuthService()

    private init() {}

    private let baseURL = APIConstants.baseURL

    // Get the current user's JWT token from Clerk
    private func getAuthToken() throws -> String {
        var token: String?
        var authError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        Task { @MainActor in
            if let user = Clerk.shared.user {
                token = user.id
                print("Got user ID: \(user.id)")
            } else {
                print("No user found in Clerk.shared.user")
                authError = AuthError.notAuthenticated
            }
            semaphore.signal()
        }
        semaphore.wait()

        if let error = authError {
            throw error
        }

        guard let jwtToken = token else {
            print("No token available")
            throw AuthError.notAuthenticated
        }
        return jwtToken
    }

    // Create an authenticated URLRequest with the Clerk JWT token
    func authenticatedRequest(for endpoint: String, method: String = "GET", body: Data? = nil) async throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        let token = try getAuthToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body = body {
            // Only set Content-Type if not already set (for multipart requests)
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            request.httpBody = body
        }

        return request
    }
}

enum AuthError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case serverError(code: Int, message: String)
}