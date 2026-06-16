import Foundation

enum SerperError: Error, LocalizedError {
    case invalidAPIKey
    case badResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Serper API key not found. Please add it in Settings."
        case .badResponse:
            return "The Serper server returned an invalid response."
        case .apiError(let message):
            return "Serper API Error: \(message)"
        }
    }
}

class SerperService {
    private let apiKey: String
    private let apiURL = URL(string: "https://google.serper.dev/search")!
    private let retryPolicy = OpenAICompatibleRetryPolicy.default

    init(apiKey: String) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func search(query: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw SerperError.invalidAPIKey
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.addValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["q": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw SerperError.invalidAPIKey
            }
            throw SerperError.badResponse
        }

        // We return a simplified string representation of the search results
        // that the LLM can easily consume.
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SerperError.badResponse
        }

        var resultString = ""

        if let answerBox = json["answerBox"] as? [String: Any] {
            if let title = answerBox["title"] as? String {
                resultString += "Answer Box Title: \(title)\n"
            }
            if let answer = answerBox["answer"] as? String {
                resultString += "Answer: \(answer)\n"
            }
            if let snippet = answerBox["snippet"] as? String {
                resultString += "Snippet: \(snippet)\n"
            }
        }

        if let organic = json["organic"] as? [[String: Any]] {
            resultString += "Organic Results:\n"
            for (index, item) in organic.prefix(3).enumerated() {
                if let title = item["title"] as? String, let snippet = item["snippet"] as? String {
                    resultString += "\(index + 1). \(title): \(snippet)\n"
                }
            }
        }

        if resultString.isEmpty {
            return "No relevant search results found."
        }

        return resultString
    }

    func searchStructured(query: String) async throws -> SearchStep {
        guard !apiKey.isEmpty else {
            throw SerperError.invalidAPIKey
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.addValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["q": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw SerperError.invalidAPIKey
            }
            throw SerperError.badResponse
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SerperError.badResponse
        }

        var results: [SearchResult] = []
        var answerBoxContent: String?

        if let answerBox = json["answerBox"] as? [String: Any] {
            if let answer = answerBox["answer"] as? String {
                answerBoxContent = answer
            } else if let snippet = answerBox["snippet"] as? String {
                answerBoxContent = snippet
            }
        }

        if let organic = json["organic"] as? [[String: Any]] {
            for item in organic.prefix(4) {
                if let title = item["title"] as? String,
                   let link = item["link"] as? String,
                   let snippet = item["snippet"] as? String {
                    results.append(SearchResult(title: title, link: link, snippet: snippet))
                }
            }
        }

        return SearchStep(query: query, results: results, answerBox: answerBoxContent)
    }

    private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 1...retryPolicy.maxAttempts {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw SerperError.badResponse
                }

                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw SerperError.invalidAPIKey
                }

                let statusError = OpenAICompatibleRequestError.httpStatus(
                    httpResponse.statusCode,
                    retryAfterSeconds: retryAfterSeconds(from: httpResponse)
                )

                if httpResponse.statusCode != 200,
                   retryPolicy.shouldRetry(statusError, attempt: attempt) {
                    lastError = SerperError.badResponse
                    try await Task.sleep(nanoseconds: retryPolicy.delayNanoseconds(for: statusError, attempt: attempt))
                    continue
                }

                return (data, response)
            } catch let error as URLError {
                if error.code == .cancelled {
                    throw CancellationError()
                }

                let transportError = OpenAICompatibleRequestError.transport(error)
                if retryPolicy.shouldRetry(transportError, attempt: attempt) {
                    lastError = error
                    try await Task.sleep(nanoseconds: retryPolicy.delayNanoseconds(for: transportError, attempt: attempt))
                    continue
                }
                throw error
            }
        }

        throw lastError ?? SerperError.badResponse
    }

    private func retryAfterSeconds(from response: HTTPURLResponse) -> Double? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After") else { return nil }
        return Double(value)
    }
}
