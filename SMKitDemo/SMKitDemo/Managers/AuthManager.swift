//
//  AuthManager.swift
//  SMKitDemoApp
//
//  Created by netanel-yerushalmi on 03/07/2024.
//

import Foundation

private enum LocalEnvironment {
    static func value(for key: String, sourceFilePath: String = #filePath) -> String? {
        if let value = clean(ProcessInfo.processInfo.environment[key]) {
            return value
        }

        return valueFromLocalEnvFile(for: key, sourceFilePath: sourceFilePath)
    }

    private static func valueFromLocalEnvFile(for key: String, sourceFilePath: String) -> String? {
        var directory = URL(fileURLWithPath: sourceFilePath).deletingLastPathComponent()

        for _ in 0..<8 {
            let envURL = directory.appendingPathComponent(".env")
            if let contents = try? String(contentsOf: envURL, encoding: .utf8),
               let value = parse(contents: contents, key: key) {
                return value
            }

            let parent = directory.deletingLastPathComponent()
            guard parent.path != directory.path else { break }
            directory = parent
        }

        return nil
    }

    private static func parse(contents: String, key: String) -> String? {
        for rawLine in contents.components(separatedBy: .newlines) {
            var line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }

            if line.hasPrefix("export ") {
                line.removeFirst("export ".count)
            }

            let parts = line.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }

            let candidateKey = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            guard candidateKey == key else { continue }

            return clean(String(parts[1]))
        }

        return nil
    }

    private static func clean(_ value: String?) -> String? {
        guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
            (value.hasPrefix("'") && value.hasSuffix("'")) {
            value.removeFirst()
            value.removeLast()
        }

        return value.isEmpty ? nil : value
    }
}

protocol AuthManagerDelegate:NSObject{
    func didFinishAuth()
    func didFailAuth()
}

class AuthManager:ObservableObject{
    static let shared = AuthManager()
    
    @Published var didFinishAuth = false{
        didSet{
            if didFaildAuth{
                delegate?.didFinishAuth()
            }
        }
    }
    @Published var didFaildAuth = false{
        didSet{
            delegate?.didFailAuth()
        }
    }
    
    weak var delegate:AuthManagerDelegate?

    var smKitAuthKey: String {
        LocalEnvironment.value(for: "SMKIT_AUTH_KEY") ?? ""
    }
}
