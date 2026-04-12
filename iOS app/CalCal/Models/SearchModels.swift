import Foundation

public struct SearchResult: Codable, Hashable {
    public let title: String
    public let link: String
    public let snippet: String
    
    public init(title: String, link: String, snippet: String) {
        self.title = title
        self.link = link
        self.snippet = snippet
    }
}

public struct SearchStep: Codable, Hashable {
    public let query: String
    public let results: [SearchResult]
    public let answerBox: String?
    
    public init(query: String, results: [SearchResult], answerBox: String? = nil) {
        self.query = query
        self.results = results
        self.answerBox = answerBox
    }
}
