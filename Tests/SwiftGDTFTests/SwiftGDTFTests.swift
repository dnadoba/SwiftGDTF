import Testing
import Foundation

let env = ProcessInfo.processInfo.environment

// These fixtures have known issues with their profiles
// and should be ignored in reguards to validating this library
// as they do not follow proper spec

let FIXTURE_BLACKLIST = [
    "None"
]

// MARK: - Credentials

struct Credentials {
    let username: String
    let password: String
}

// MARK: - Fixture

struct Fixture: Decodable {
    var uuid: String
    var rid: Int
    var fixture: String
    var manufacturer: String
    var creationDate: Int
    
    func filename() -> String {
        return "\(self.fixture)_\(self.manufacturer)_\(self.uuid).gdtf".replacingOccurrences(of: "/", with: "_")
    }
}

// MARK: - Session Manager

actor SessionManager {
    private let credentials: Credentials
    private var isLoggedIn = false

    init(credentials: Credentials) {
        self.credentials = credentials
    }

    func login() async throws {
        guard !isLoggedIn else { return }

        let loginURL = URL(string: "https://gdtf-share.com/apis/public/login.php")!
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "user": credentials.username,
            "password": credentials.password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "LoginError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        isLoggedIn = true
    }

    func invalidateSession() {
        isLoggedIn = false
    }
}

// MARK: - GDTF Downloader

class GDTFDownloader {
    private let sessionManager: SessionManager
    private let downloadDirectory: URL
    private var fixtures: [Fixture] = []

    init(credentials: Credentials, downloadDirectory: URL) {
        self.sessionManager = SessionManager(credentials: credentials)
        self.downloadDirectory = downloadDirectory
    }

    func start() async throws {
        try await sessionManager.login()
        try await fetchFixtures()
        try await downloadFixtures()
    }

    private func fetchFixtures() async throws {
        let listURL = URL(string: "https://gdtf-share.com/apis/public/getList.php")!
        var request = URLRequest(url: listURL)
        request.httpMethod = "GET"

        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = .shared
        configuration.httpMaximumConnectionsPerHost = 200
        
        let session = URLSession(configuration: configuration)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "FetchFixturesError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        struct ListResponse: Decodable {
            let result: Bool
            let list: [Fixture]
        }

        let decoder = JSONDecoder()
        let responseObj = try decoder.decode(ListResponse.self, from: data)

        // Group by UUID and pick the newest creationDate
        var latestByUUID: [String: Fixture] = [:]

        for fixture in responseObj.list {
            if let existing = latestByUUID[fixture.uuid] {
                if fixture.creationDate > existing.creationDate {
                    latestByUUID[fixture.uuid] = fixture
                }
            } else {
                latestByUUID[fixture.uuid] = fixture
            }
        }

        self.fixtures = Array(latestByUUID.values.sorted(by: { $0.rid < $1.rid }))
        
        // filter out blacklisted fixtures
        self.fixtures = fixtures.filter({ f in
            return !FIXTURE_BLACKLIST.contains(f.filename())
        })
    }

    private func downloadFixtures() async throws {
        try FileManager.default.createDirectory(at: downloadDirectory, withIntermediateDirectories: true, attributes: nil)
        print("downloading to \(downloadDirectory)")

        let totalCount = fixtures.count
        var downloadedCount = 0

        await withTaskGroup(of: Void.self) { group in
            func addTask(_ fixture: Fixture) {
                group.addTask {
                    do {
                        try await self.downloadFixture(fixture)
                        downloadedCount += 1
                        let progress = Double(downloadedCount) / Double(totalCount) * 100
                        print(String(format: "Progress: %.2f%% (%d/%d)", progress, downloadedCount, totalCount))
                    } catch {
                        print("Failed to download fixture \(fixture.uuid): \(error)")
                    }
                }
            }
            var fixtures = fixtures.makeIterator()
            var i = 0
            while let fixture = fixtures.next(), i < 20 {
                i += 1
                addTask(fixture)
            }
            for await _ in group {
                if let fixture = fixtures.next() {
                    addTask(fixture)
                } else {
                    break
                }
            }
        }
    }

    private func downloadFixture(_ fixture: Fixture) async throws {
        let destinationURL = downloadDirectory.appendingPathComponent(fixture.filename())

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("Skipping \(fixture.filename()), already exists.")
            return
        }

        let downloadURL = URL(string: "https://gdtf-share.com/apis/public/downloadFile.php?rid=\(fixture.rid)")!
        var request = URLRequest(url: downloadURL)
        request.httpMethod = "GET"

        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = .shared
        let session = URLSession(configuration: configuration)

        let (tempURL, response) = try await session.download(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: try Data(contentsOf: tempURL), encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "DownloadError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        print("Downloaded \(fixture.filename())")
    }
}

import SwiftGDTF

// MARK: - GDTF Validator

class GDTFValidator {
    private let fixturesDirectory: URL
    private var successes: [String] = []
    private var failures: [(String, String)] = []

    init(fixturesDirectory: URL) {
        self.fixturesDirectory = fixturesDirectory
    }

    func validateAll() async {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: fixturesDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            let gdtfFiles = fileURLs.filter { $0.pathExtension.lowercased() == "gdtf" }

            print("Found \(gdtfFiles.count) GDTF files to validate.\n")

            await withTaskGroup(of: (String, Result<Void, Error>).self) { group in
                for fileURL in gdtfFiles {
                    group.addTask {
                        let filename = fileURL.lastPathComponent
                        do {
                            _ = try loadGDTF(url: fileURL)
                            return (filename, .success(()))
                        } catch {
                            return (filename, .failure(error))
                        }
                    }
                }

                for await (filename, result) in group {
                    switch result {
                    case .success:
                        successes.append(filename)
                        print("✅ Successfully parsed: \(filename)")
                    case .failure(let error):
                        failures.append((filename, "\(error)"))
                        print("❌ Failed to parse: \(filename)\n   Error: \(error)")
                    }
                }
            }

            // Summary
            print("\nValidation Summary:")
            print("✅ Successes: \(successes.count)")
            print("❌ Failures: \(failures.count)")
            let errorGrouped = Dictionary.init(zip(failures.map(\.1), repeatElement(1, count: .max)), uniquingKeysWith: +).sorted(by: { $0.value > $1.value})
            print("Failure Reasons")
            for error in errorGrouped {
                print("\(error.key): \(error.value)")
            }
            
            

            if !failures.isEmpty {
                print("\nFailed Files:")
                for (filename, errorDescription) in failures {
                    print(" - \(filename): \(errorDescription)")
                }
            }

        } catch {
            print("Error accessing fixtures directory: \(error.localizedDescription)")
        }
    }
}

// MARK: - Main Execution




@Suite
struct GDTFShare {
    let downloadFolder = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Fixtures")
    let credentials = Credentials(username: "SwiftGDTF", password: env["GDTF_SHARE_PASSWORD"]!)
    
    @Test func parseAllFixtures() async throws {
        
        let downloader = GDTFDownloader(credentials: credentials, downloadDirectory: downloadFolder)
        try await downloader.start()

        await GDTFValidator(fixturesDirectory: downloadFolder).validateAll()
    }
    
    // Useful for debugging
//    @Test func testIndividual() async throws {
//        _ = try loadGDTF(url: downloadFolder.appending(component: "Reflect Color Studio_Brother Brother and Sons_379FE751-C45E-4734-A6C8-843A2BF28F42.gdtf"))
//    }
}
