// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Security

/// Represents a Google Cloud service-account keyfile and provides OAuth2 access tokens
/// via JWT signing. Ports the functionality of `google-auth-library`'s `GoogleAuth` class
/// that the JS SDK delegates to for Vertex AI ADC (Application Default Credentials).
final class ServiceAccountCredential: @unchecked Sendable {
    private let clientEmail: String
    private let privateKeyPEM: String
    private let tokenURI: String
    private let scopes: [String]

    private let lock = NSLock()
    private var cachedToken: CachedAccessToken?

    private struct CachedAccessToken {
        let token: String
        let expiryDate: Date
    }

    private struct Keyfile: Decodable {
        let clientEmail: String
        let privateKey: String
        let tokenURI: String
        let projectID: String?

        enum CodingKeys: String, CodingKey {
            case clientEmail = "client_email"
            case privateKey = "private_key"
            case tokenURI = "token_uri"
            case projectID = "project_id"
        }
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let expiresIn: Int
        let tokenType: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case tokenType = "token_type"
        }
    }

    init(credentialsJSON: Data, scopes: [String]) throws {
        let keyfile = try JSONDecoder().decode(Keyfile.self, from: credentialsJSON)
        self.clientEmail = keyfile.clientEmail
        self.privateKeyPEM = keyfile.privateKey
        self.tokenURI = keyfile.tokenURI
        self.scopes = scopes
    }

    convenience init(keyFilePath: String, scopes: [String]) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: keyFilePath))
        try self.init(credentialsJSON: data, scopes: scopes)
    }

    /// Retrieves a valid OAuth2 access token, refreshing if the cached token is within
    /// 5 minutes of expiry or absent.
    func getAccessToken() async throws -> String {
        if let cached = getCachedToken() { return cached }

        let jwt = try buildAndSignJWT()
        let tokenResponse = try await exchangeJWTForToken(jwt)

        setCachedToken(tokenResponse.accessToken, expiresIn: tokenResponse.expiresIn)
        return tokenResponse.accessToken
    }

    private func getCachedToken() -> String? {
        lock.lock(); defer { lock.unlock() }
        if let cached = cachedToken, cached.expiryDate > Date().addingTimeInterval(300) {
            return cached.token
        }
        return nil
    }

    private func setCachedToken(_ token: String, expiresIn: Int) {
        lock.lock(); defer { lock.unlock() }
        cachedToken = CachedAccessToken(
            token: token,
            expiryDate: Date().addingTimeInterval(Double(expiresIn - 60))
        )
    }

    // MARK: - JWT Construction & Signing

    private func buildAndSignJWT() throws -> String {
        let now = Int(Date().timeIntervalSince1970)

        let headerJSON = "{\"alg\":\"RS256\",\"typ\":\"JWT\"}"
        let payloadJSON =
            "{\"iss\":\"\(clientEmail)\",\"sub\":\"\(clientEmail)\"," +
            "\"aud\":\"\(tokenURI)\"," +
            "\"scope\":\"\(scopes.joined(separator: " "))\"," +
            "\"iat\":\(now),\"exp\":\(now + 3600)}"

        let headerB64 = base64URLEncode(Data(headerJSON.utf8))
        let payloadB64 = base64URLEncode(Data(payloadJSON.utf8))
        let signingInput = "\(headerB64).\(payloadB64)"

        let signature = try rsaSign(data: Data(signingInput.utf8), pemKey: privateKeyPEM)
        let signatureB64 = base64URLEncode(signature)

        return "\(signingInput).\(signatureB64)"
    }

    // MARK: - RSA-SHA256 Signing via Security.framework

    private func rsaSign(data: Data, pemKey: String) throws -> Data {
        let isPKCS8 = pemKey.contains("BEGIN PRIVATE KEY")
        let derData = try pemToDER(pemKey)

        let keyData: Data
        if isPKCS8 {
            guard let extracted = extractPKCS1FromPKCS8(derData) else {
                throw GenAIError.invalidArgument("Failed to extract RSA key from PKCS#8 wrapper")
            }
            keyData = extracted
        } else {
            keyData = derData
        }

        let keySizeBits = rsaKeySizeBits(fromPKCS1DER: keyData)
        let secKey = try createSecKey(fromPKCS1DER: keyData, keySizeBits: keySizeBits)

        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            secKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            &error
        ) else {
            let err = error?.takeRetainedValue() as Error?
                ?? GenAIError.runtime("RSA-SHA256 signing failed")
            throw err
        }
        return signature as Data
    }

    private func pemToDER(_ pem: String) throws -> Data {
        let lines = pem.split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.hasPrefix("-----BEGIN") && !$0.hasPrefix("-----END") && !$0.isEmpty }
        let base64Str = lines.joined()
        guard let derData = Data(base64Encoded: base64Str) else {
            throw GenAIError.invalidArgument("Failed to decode PEM private key as base64")
        }
        return derData
    }

    private func createSecKey(fromPKCS1DER derData: Data, keySizeBits: Int) throws -> SecKey {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: keySizeBits,
        ]
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(
            derData as CFData,
            attributes as CFDictionary,
            &error
        ) else {
            let err = error?.takeRetainedValue() as Error?
                ?? GenAIError.runtime("Failed to create SecKey from DER data")
            throw err
        }
        return secKey
    }

    // MARK: - PKCS#8 → PKCS#1 extraction

    /// Strips the PKCS#8 PrivateKeyInfo wrapper to get the inner PKCS#1 RSAPrivateKey DER.
    private func extractPKCS1FromPKCS8(_ derData: Data) -> Data? {
        var idx = 0

        guard derData[idx] == 0x30 else { return nil }
        idx += 1
        _ = readDERLength(derData, from: &idx)

        guard derData[idx] == 0x02 else { return nil }
        idx += 1
        let versionLen = readDERLength(derData, from: &idx)
        idx += versionLen

        guard derData[idx] == 0x30 else { return nil }
        idx += 1
        let algIdLen = readDERLength(derData, from: &idx)
        idx += algIdLen

        guard derData[idx] == 0x04 else { return nil }
        idx += 1
        let contentLen = readDERLength(derData, from: &idx)

        guard idx + contentLen <= derData.count else { return nil }
        return derData.subdata(in: idx..<(idx + contentLen))
    }

    // MARK: - DER length parsing

    private func readDERLength(_ data: Data, from idx: inout Int) -> Int {
        let firstByte = Int(data[idx])
        idx += 1
        if firstByte < 0x80 {
            return firstByte
        }
        let numBytes = firstByte & 0x7F
        var length = 0
        for _ in 0..<numBytes {
            length = (length << 8) | Int(data[idx])
            idx += 1
        }
        return length
    }

    // MARK: - RSA key size from PKCS#1 DER

    private func rsaKeySizeBits(fromPKCS1DER data: Data) -> Int {
        var idx = 0

        guard data[idx] == 0x30 else { return 2048 }
        idx += 1
        _ = readDERLength(data, from: &idx)

        guard data[idx] == 0x02 else { return 2048 }
        idx += 1
        let versionLen = readDERLength(data, from: &idx)
        idx += versionLen

        guard data[idx] == 0x02 else { return 2048 }
        idx += 1
        let modulusLen = readDERLength(data, from: &idx)

        let actualBytes = (idx < data.count && data[idx] == 0) ? modulusLen - 1 : modulusLen
        return max(actualBytes * 8, 2048)
    }

    // MARK: - OAuth2 Token Exchange

    private func exchangeJWTForToken(_ jwt: String) async throws -> TokenResponse {
        guard let url = URL(string: tokenURI) else {
            throw GenAIError.invalidArgument("Invalid token_uri: \(tokenURI)")
        }

        let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)&timeout=10000"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(body.utf8)

        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        guard let httpResp = httpResponse as? HTTPURLResponse else {
            throw GenAIError.runtime("Token exchange response was not HTTPURLResponse")
        }
        guard (200..<300).contains(httpResp.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw GenAIError.runtime(
                "Token exchange failed with status \(httpResp.statusCode): \(bodyText)"
            )
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    // MARK: - Base64URL Encoding

    private func base64URLEncode(_ data: Data) -> String {
        var result = data.base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }
}
