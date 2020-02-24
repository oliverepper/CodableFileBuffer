//
//  CodableFileBuffer.swift
//
//  Created by Oliver Epper on 26.12.19.
//  Copyright © 2020 Oliver Epper. All rights reserved.
//

import Foundation
import os.log

@available(iOS 10.0, *)
extension OSLog {
    static let CodableFileBuffer = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Codable File Buffer")
}

enum CodableFileBufferError: Error {
    case fileExists
    case directoryMissing
}

@available(iOS 13.0, *)
public class CodableFileBuffer<T: Codable> {

    public private(set) var count = 0

    private var fileURL: URL
    private var encoder = JSONEncoder()
    private var decoder = JSONDecoder()

    // MARK: lazy fileHandle
    private lazy var fileHandle: FileHandle = {
        // create FileHandle and insert "[" at the beginning of the file
        var handle = FileHandle()
        do {
            handle = try FileHandle(forUpdating: fileURL)
            handle.write("[".data(using: .utf8)!)
        } catch {
            fatalError("CodableFileBuffer could not create a FileHandle for \(fileURL.lastPathComponent): \(error.localizedDescription)")
        }

        return handle
    }()

    // MARK: initializer
    public init(filename: String? = nil, searchPath: FileManager.SearchPathDirectory = .documentDirectory) throws {
        // build the URL
        guard let dir = FileManager.default.urls(for: searchPath, in: .userDomainMask).first else {
            fatalError("Cannot find \(searchPath)")
        }

        // create dir if it doesn't exists
        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("CodableFileBuffer could not create the required directory")
            }
        }

        fileURL = dir.appendingPathComponent(filename ?? "\(Bundle.main.bundleIdentifier!)_\(UUID())")
        fileURL.appendPathExtension("json")

        // create file
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            os_log("%@ created in %@", log: OSLog.CodableFileBuffer, type: .debug, fileURL.lastPathComponent, fileURL.deletingLastPathComponent().path)
        } else {
            throw CodableFileBufferError.fileExists
        }
    }

    public convenience init() {
        try! self.init(filename: nil, searchPath: .documentDirectory)
    }

    // MARK: append
    public func append(_ codable: T) {
        // encode codable
        guard let data = try? encoder.encode(codable) else {
            fatalError("Cannot encode \(codable)")
        }

        // write to FileHandle
        fileHandle.write(data)
        fileHandle.write(",".data(using: .utf8)!)

        // update the count
        count += 1

        // log
        os_log("Did append codable to CodableFileBuffer at: %@", log: OSLog.CodableFileBuffer, type: .debug, fileURL.lastPathComponent)
    }

    // MARK: retrieve
    public func retrieve() -> [T] {
        // decode and return
        do {
            return try decoder.decode([T].self, from: getData())
        } catch {
            return [T]()
        }
    }

    // MARK: reset
    public func reset() {
        // wipe the file
        os_log("Wiping the file %@", log: OSLog.CodableFileBuffer, type: .info, fileURL.path)
        fileHandle.truncateFile(atOffset: 0)
        fileHandle.write("[".data(using: .utf8)!)
        try? fileHandle.synchronize()

        // reset the count
        count = 0

        // log
        os_log("Did reset.", log: OSLog.CodableFileBuffer, type: .info)
    }

    // MARK: deinitializer
    deinit {
        try? fileHandle.close()
        os_log("FileHandle %@ closed", log: OSLog.CodableFileBuffer, type: .debug, fileHandle.debugDescription)
        try? FileManager.default.removeItem(at: fileURL)
        os_log("File at path %@ deleted.", log: OSLog.CodableFileBuffer, type: .debug, fileURL.path)
    }

    private func getData() -> Data {
        fileHandle.seek(toFileOffset: 0)
        var data = fileHandle.readDataToEndOfFile()
        data.append("]".data(using: .utf8)!)

        return data
    }
}
