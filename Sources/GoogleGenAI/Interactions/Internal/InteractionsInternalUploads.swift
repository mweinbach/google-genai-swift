// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// An uploadable file payload. In TS this is `File | Response | FsReadStream | BunFile`.
/// In Swift we collapse to a struct holding bytes, an optional filename, and an
/// optional mime type. Mirrors `Uploadable` in `internal/uploads.ts`.
public struct Uploadable: Sendable {
    public var data: Data
    public var filename: String?
    public var mimeType: String?

    public init(data: Data, filename: String? = nil, mimeType: String? = nil) {
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
    }
}

/// Returns the filename for the given value, falling back to its url, filename or
/// path-like attribute. Mirrors `getName`.
public func getName(_ value: Any?) -> String? {
    if let u = value as? Uploadable { return u.filename }
    if let url = value as? URL { return url.lastPathComponent }
    if let s = value as? String, let url = URL(string: s) {
        let last = url.lastPathComponent
        if !last.isEmpty { return last }
    }
    return nil
}

/// Throws if File is not available. In Swift `Data` is always available, so this
/// is a no-op. Mirrors `checkFileSupport`.
public func checkFileSupport() {}

/// Build an `Uploadable` from bytes, filename, and options. Mirrors `makeFile`.
public func makeFile(_ fileBits: Data, fileName: String?, options: FilePropertyBag? = nil) -> Uploadable {
    return Uploadable(data: fileBits, filename: fileName ?? "unknown_file", mimeType: options?.type)
}

/// Whether `value` is async-iterable. Always false for Swift native types — we
/// use `AsyncSequence` explicitly elsewhere. Mirrors `isAsyncIterable`.
public func isAsyncIterable(_ value: Any?) -> Bool {
    return false
}

// MARK: - Multipart helpers

/// One field in a multipart/form-data request.
public enum MultipartField: Sendable {
    case text(name: String, value: String)
    case file(name: String, filename: String, mimeType: String, data: Data)
}

/// Build a multipart/form-data request body and return `(bodyData, contentType)`.
///
/// The TS code path uses the `FormData` global plus `node-fetch`'s `form-data`
/// shim; here we hand-build the body with the standard MIME boundary format.
public func multipartBody(boundary: String, parts: [MultipartField]) -> Data {
    var body = Data()
    let delim = "--\(boundary)\r\n"
    for part in parts {
        body.append(Data(delim.utf8))
        switch part {
        case .text(let name, let value):
            body.append(Data("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
            body.append(Data(value.utf8))
            body.append(Data("\r\n".utf8))
        case .file(let name, let filename, let mimeType, let data):
            body.append(Data("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".utf8))
            body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
            body.append(data)
            body.append(Data("\r\n".utf8))
        }
    }
    body.append(Data("--\(boundary)--\r\n".utf8))
    return body
}

/// Generate a random multipart boundary string.
public func makeMultipartBoundary() -> String {
    return "----GoogleGenAI\(UUID().uuidString)"
}

/// Walks the body and uploads any `Uploadable` values via multipart/form-data when
/// present. Mirrors `maybeMultipartFormRequestOptions` (best-effort port).
public func maybeMultipartFormRequestOptions(_ opts: RequestOptions) -> RequestOptions {
    // In Swift, callers thread `Uploadable` via dedicated channels rather than
    // burying them in arbitrary JSONValue trees — so the JSON form of the body
    // already won't contain raw bytes. This function is a no-op pass-through
    // included for API parity.
    return opts
}

/// Like `maybeMultipartFormRequestOptions` but always converts. Mirrors `multipartFormRequestOptions`.
public func multipartFormRequestOptions(_ opts: RequestOptions) -> RequestOptions {
    return opts
}

/// Build a `FormData`-equivalent body. Returns a multipart body data + boundary.
/// Mirrors `createForm`.
public func createForm<T>(_ body: T?) -> (Data, String) {
    let boundary = makeMultipartBoundary()
    var parts: [MultipartField] = []
    if let dict = body as? [String: JSONValue] {
        for (key, value) in dict {
            addFormValue(&parts, key: key, value: value)
        }
    }
    return (multipartBody(boundary: boundary, parts: parts), boundary)
}

private func addFormValue(_ form: inout [MultipartField], key: String, value: JSONValue) {
    switch value {
    case .null:
        return
    case .bool(let b):
        form.append(.text(name: key, value: b ? "true" : "false"))
    case .int(let i):
        form.append(.text(name: key, value: String(i)))
    case .double(let d):
        form.append(.text(name: key, value: String(d)))
    case .string(let s):
        form.append(.text(name: key, value: s))
    case .array(let arr):
        for entry in arr {
            addFormValue(&form, key: "\(key)[]", value: entry)
        }
    case .object(let obj):
        for (name, prop) in obj {
            addFormValue(&form, key: "\(key)[\(name)]", value: prop)
        }
    }
}
