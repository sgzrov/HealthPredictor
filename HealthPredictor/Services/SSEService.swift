//
//  SSEService.swift
//  HealthPredictor
//
//  Created by Stephan on 22.06.2025.
//

import Foundation
import Combine

enum SSEEventType {
    case message
    case error
    case done
}

struct SSEEvent {
    let type: SSEEventType
    let data: String
    let id: String?
}

struct StreamingChunk: Codable {
    let content: String?
    let done: Bool
    let error: String?
}

class SSEService: NSObject, URLSessionDataDelegate, SSEServiceProtocol {

    static let shared = SSEService()

    private var session: URLSession!
    private var dataTask: URLSessionDataTask?
    private var eventBuffer = ""
    private var eventPublisher = PassthroughSubject<SSEEvent, Error>()

    private override init() {
        super.init()

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func streamSSE(request: URLRequest) async throws -> AsyncStream<String> {
        return AsyncStream<String> { continuation in
            let publisher = establishConnection(with: request)

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
                self.disconnect()
            }
        }
    }

    func disconnect() {
        dataTask?.cancel()
        dataTask = nil
        eventPublisher.send(completion: .finished)
    }

    private func establishConnection(with request: URLRequest) -> AnyPublisher<SSEEvent, Error> {
        print("SSE: Connecting to: \(request.url?.absoluteString ?? "unknown")")

        var modifiedRequest = request
        modifiedRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        modifiedRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        modifiedRequest.setValue("keep-alive", forHTTPHeaderField: "Connection")

        dataTask = session.dataTask(with: modifiedRequest)
        dataTask?.resume()
        print("SSE: Data task started")

        return eventPublisher.eraseToAnyPublisher()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("SSE: Received \(data.count) bytes")

        guard let receivedString = String(data: data, encoding: .utf8) else {
            print("SSE: Failed to decode data as UTF-8")
            return
        }

        eventBuffer += receivedString
        processCompleteEvents()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("SSE: Connection failed with error: \(error.localizedDescription)")
            eventPublisher.send(completion: .failure(error))
        } else {
            print("SSE: Connection completed successfully")
            eventPublisher.send(completion: .finished)
        }
    }

    private func processCompleteEvents() {
        let events = eventBuffer.components(separatedBy: "\n\n")

        if events.count > 1 {
            eventBuffer = events.last ?? ""
            for eventString in events.dropLast() where !eventString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parseEvent(eventString)
            }
        } else if eventBuffer.contains("\n\n") {
            let completeEvents = eventBuffer.components(separatedBy: "\n\n")

            if completeEvents.count > 1 {
                eventBuffer = completeEvents.last ?? ""
                for eventString in completeEvents.dropLast() where !eventString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    parseEvent(eventString)
                }
            }
        }
    }

    private func parseEvent(_ eventString: String) {
        var eventType: SSEEventType = .message
        var eventData = ""
        var eventId: String?

        let lines = eventString.components(separatedBy: "\n")

        for line in lines {
            if line.hasPrefix("event:") {
                let type = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
                switch type {
                case "error":
                    eventType = .error
                case "done":
                    eventType = .done
                default:
                    eventType = .message
                }
            } else if line.hasPrefix("data:") {
                eventData = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("id:") {
                eventId = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
            }
        }

        if !eventData.isEmpty {
            print("SSE: Publishing event - type: \(eventType), data: '\(eventData)'")
            let event = SSEEvent(type: eventType, data: eventData, id: eventId)
            eventPublisher.send(event)
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
}