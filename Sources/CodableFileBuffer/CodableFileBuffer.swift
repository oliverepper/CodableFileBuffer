//
//  CodableFileBuffer.swift
//
//  Created by Oliver Epper on 26.12.19.
//  Copyright © 2020 Oliver Epper. All rights reserved.
//

import Foundation
import os.log


enum CodableFileBufferError: Error {
    case notFound
    case fileExists
    case appendFailed
    case retrieveDataFailed
    case resetFailed
}

extension Data {
    enum Characters: String {
        case openBracket = "["
        case comma = ","
        case closingBracket = "]"
    }

    static var openBracket: Self {
        data(for: .openBracket)
    }

    static var comma: Self {
        data(for: .comma)
    }

    static var closingBracket: Self {
        data(for: .closingBracket)
    }

    static private func data(for character: Characters) -> Data {
        character.rawValue.data(using: .utf8)!
    }
}

public final class CodableFileBuffer<T: Codable> {

    public private(set) var count = 0

    private var fileURL: URL

    private lazy var fileHandle: FileHandle? = {
        // create FileHandle and insert "[" at the beginning of the file
        let handle = try? FileHandle(forUpdating: fileURL)
        handle?.write(.openBracket)
        return handle
    }()

    // MARK: init
    public init(filename: String? = nil, path: FileManager.SearchPathDirectory = .cachesDirectory) throws {
        guard let dir = FileManager.default.urls(for: path, in: .userDomainMask).first else {
            throw CodableFileBufferError.notFound
        }

        // create directory if needed
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }

        fileURL = dir.appendingPathComponent(filename ?? "\(Bundle.main.bundleIdentifier!)_" + UUID().uuidString)
        fileURL.appendPathExtension("json")

        // create the file
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path,
                                           contents: nil,
                                           attributes: nil)
            os_log("%@ created in %@", fileURL.lastPathComponent, fileURL.deletingLastPathComponent().path)
        } else {
            throw CodableFileBufferError.fileExists
        }
    }

    // MARK: append
    public func append(_ codable: T, encoder: JSONEncoder = JSONEncoder()) throws {
        let data = try encoder.encode(codable)

        // write to filehandle
        do {
            try fileHandle?.write(contentsOf: data)
            try fileHandle?.write(contentsOf: Data.comma)
        } catch {
            throw CodableFileBufferError.appendFailed
        }

        count += 1

        os_log("Did append codable to Buffer: %@", fileURL.lastPathComponent)
    }

    // MARK: retrieve
    public func retrieve(decoder: JSONDecoder = JSONDecoder()) -> [T] {
        // decode and return
        do {
            guard let data = try getData() else {
                throw CodableFileBufferError.retrieveDataFailed
            }
            return try decoder.decode([T].self, from: data)
        } catch {
            return [T]()
        }
    }

    // MARK: reset
    public func reset() throws {
        os_log("Wiping the file %@", fileURL.path)
        fileHandle?.truncateFile(atOffset: 0)
        do {
            try fileHandle?.write(contentsOf: Data.openBracket)
            try fileHandle?.synchronize()
        } catch {
            throw CodableFileBufferError.resetFailed
        }

        count = 0
    }

    // MARK: deinitializer
    deinit {
        try? fileHandle?.close()
        os_log("FileHandle %@ closed", fileHandle.debugDescription)
        
        try? FileManager.default.removeItem(at: fileURL)
        os_log("File at path %@ deleted.", fileURL.path)
    }

    private func getData() throws -> Data? {
        guard let fileHandle = fileHandle else {
            return nil
        }
        let eof = try fileHandle.seekToEnd()
        try fileHandle.seek(toOffset: 0)
        var data = try fileHandle.read(upToCount: Int(eof))
        data?.append(.closingBracket)
        return data
    }
}

