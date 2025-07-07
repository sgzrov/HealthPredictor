//
//  SSEClient.swift
//  HealthPredictor
//
//  Created by Assistant on 2025.
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

class SSEClientService: NSObject, URLSessionDataDelegate {
    private var session: URLSession!
    private var dataTask: URLSessionDataTask?
    private var eventBuffer = ""
    private var eventPublisher = PassthroughSubject<SSEEvent, Error>()

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func connect(to url: URL, headers: [String: String] = [:]) -> AnyPublisher<SSEEvent, Error> {
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")

        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        dataTask = session.dataTask(with: request)
        dataTask?.resume()

        return eventPublisher.eraseToAnyPublisher()
    }

    func connect(with request: URLRequest) -> AnyPublisher<SSEEvent, Error> {
        print("SSE: Connecting to: \(request.url?.absoluteString ?? "unknown")")
        print("SSE: Method: \(request.httpMethod ?? "unknown")")

        var modifiedRequest = request
        modifiedRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        modifiedRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        modifiedRequest.setValue("keep-alive", forHTTPHeaderField: "Connection")

        dataTask = session.dataTask(with: modifiedRequest)
        dataTask?.resume()
        print("SSE: Data task started")

        return eventPublisher.eraseToAnyPublisher()
    }

    func disconnect() {
        dataTask?.cancel()
        dataTask = nil
        eventPublisher.send(completion: .finished)
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
        // SSE events are separated by double newlines (\n\n)
        let events = eventBuffer.components(separatedBy: "\n\n")

        if events.count > 1 {
            // Keep the last (potentially incomplete) event in the buffer
            eventBuffer = events.last ?? ""

            // Process all complete events (everything except the last one)
            for eventString in events.dropLast() where !eventString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parseEvent(eventString)
            }
        } else if eventBuffer.contains("\n\n") {
            // Handle edge case: we have a complete event in the buffer
            let completeEvents = eventBuffer.components(separatedBy: "\n\n")
            if completeEvents.count > 1 {
                eventBuffer = completeEvents.last ?? ""

                for eventString in completeEvents.dropLast() where !eventString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    print("SSE: Processing event: '\(eventString)'")
                    parseEvent(eventString)
                }
            }
        }
    }

    private func parseEvent(_ eventString: String) {
        var eventType: SSEEventType = .message
        var eventData = ""
        var eventId: String?

        // Parse each line of the SSE event
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
                // Extract the actual data content (everything after "data:")
                eventData = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("id:") {
                // Extract optional event ID (everything after "id:")
                eventId = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
            }
        }

        // If we have data but no event type was specified, treat it as a message
        if !eventData.isEmpty {
            print("SSE: Publishing event - type: \(eventType), data: '\(eventData)'")
            let event = SSEEvent(type: eventType, data: eventData, id: eventId)
            eventPublisher.send(event)
        } else {
            print("SSE: No data found in event")
        }
    }
}