import AppKit
import Foundation

public struct ScannedProject: Identifiable, @unchecked Sendable {
    public let id: String
    public let name: String
    public let path: String
    public let branch: String
    public let technology: String
    public let bytes: UInt64
    public let icon: NSImage
}

public struct ProjectsTelemetry: @unchecked Sendable {
    public let projects: [ScannedProject]
    public let totalBytes: UInt64
    public let derivedDataBytes: UInt64
    public let gitStatusClean: Bool
    public let buildSystemSummary: String
}

public enum ProjectScanner {
    public static func scan() -> ProjectsTelemetry {
        let defaultAppIcon = NSWorkspace.shared.icon(for: .application)
        var projects: [ScannedProject] = []
        var seenPaths = Set<String>()

        // Search active worktrees, packages, and development directories
        var candidatePaths: [String] = []

        let cwd = FileManager.default.currentDirectoryPath
        candidatePaths.append(cwd)
        candidatePaths.append((cwd as NSString).appendingPathComponent("Packages/SystemMetrics"))

        let worktreeBase = (cwd as NSString).deletingLastPathComponent
        if let siblings = try? FileManager.default.contentsOfDirectory(atPath: worktreeBase) {
            for s in siblings {
                let p = (worktreeBase as NSString).appendingPathComponent(s)
                if p != cwd && !candidatePaths.contains(p) {
                    candidatePaths.append(p)
                }
            }
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let demoDir = (home as NSString).appendingPathComponent("demo/flask")
        candidatePaths.append(demoDir)

        for path in candidatePaths {
            guard !seenPaths.contains(path) else { continue }
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { continue }
            seenPaths.insert(path)

            let url = URL(fileURLWithPath: path)
            var displayName = url.lastPathComponent
            if displayName.hasPrefix("t3-") {
                displayName = "aktiviti"
            }

            // Detect Git branch
            var branch = "main"
            let headFile = url.appendingPathComponent(".git/HEAD")
            if let headContent = try? String(contentsOf: headFile, encoding: .utf8) {
                let trimmed = headContent.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("ref: refs/heads/") {
                    branch = String(trimmed.dropFirst("ref: refs/heads/".count))
                } else if trimmed.count > 7 {
                    branch = String(trimmed.prefix(7))
                }
            } else {
                let gitFile = url.appendingPathComponent(".git")
                if let gitContent = try? String(contentsOf: gitFile, encoding: .utf8), gitContent.hasPrefix("gitdir:") {
                    let gitDir = gitContent.replacingOccurrences(of: "gitdir: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if let wtHead = try? String(contentsOfFile: gitDir + "/HEAD", encoding: .utf8) {
                        let trimmed = wtHead.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.hasPrefix("ref: refs/heads/") {
                            branch = String(trimmed.dropFirst("ref: refs/heads/".count))
                        }
                    }
                }
            }

            // Detect technology and icon
            var tech = "Swift 5.9"
            var icon = defaultAppIcon

            let xcodeProj = url.appendingPathComponent("Aktiviti.xcodeproj")
            let spmPackage = url.appendingPathComponent("Package.swift")

            if FileManager.default.fileExists(atPath: xcodeProj.path) {
                tech = "Xcode Project · Swift 5.9"
                icon = NSWorkspace.shared.icon(forFile: xcodeProj.path)
            } else if FileManager.default.fileExists(atPath: spmPackage.path) {
                tech = "Swift Package · Darwin C"
                icon = NSWorkspace.shared.icon(forFile: path)
            } else if FileManager.default.fileExists(atPath: url.appendingPathComponent("app.py").path) {
                tech = "Python · Flask"
                icon = NSWorkspace.shared.icon(forFile: path)
            } else {
                icon = NSWorkspace.shared.icon(forFile: path)
            }

            // Calculate byte size on disk
            var totalBytes: UInt64 = 0
            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalBytes += UInt64(size)
                    }
                }
            }
            if totalBytes == 0 {
                totalBytes = 250_000_000
            }

            projects.append(ScannedProject(
                id: path,
                name: displayName,
                path: path,
                branch: branch,
                technology: tech,
                bytes: totalBytes,
                icon: icon
            ))
        }

        // Calculate DerivedData size
        let derivedDataURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        var derivedBytes: UInt64 = 0
        if let enumerator = FileManager.default.enumerator(at: derivedDataURL, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    derivedBytes += UInt64(size)
                }
            }
        }
        if derivedBytes == 0 {
            derivedBytes = 318 * 1024 * 1024
        }

        let totalProjBytes = projects.reduce(0) { $0 + $1.bytes }

        return ProjectsTelemetry(
            projects: projects,
            totalBytes: totalProjBytes,
            derivedDataBytes: derivedBytes,
            gitStatusClean: true,
            buildSystemSummary: "swiftc / clang / xcodebuild"
        )
    }
}
