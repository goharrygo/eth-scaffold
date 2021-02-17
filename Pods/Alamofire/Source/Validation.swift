//
//  Validation.swift
//
//  Copyright (c) 2014-2018 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension Request {

    // MARK: Helper Types

    fileprivate typealias ErrorReason = AFError.ResponseValidationFailureReason

    /// Used to represent whether validation was successful or encountered an error resulting in a failure.
    ///
    /// - success: The validation was successful.
    /// - failure: The validation failed encountering the provided error.
    public enum ValidationResult {
        case success
        case failure(Error)
    }

    fileprivate struct MIMEType {
        let type: String
        let subtype: String

        var isWildcard: Bool { return type == "*" && subtype == "*" }

        init?(_ string: String) {
            let components: [String] = {
                let stripped = string.trimmingCharacters(in: .whitespacesAndNewlines)

            #if swift(>=3.2)
                let split = stripped[..<(stripped.range(of: ";")?.lowerBound ?? stripped.endIndex)]
            #else
                let split = stripped.substring(to: stripped.range(of: ";")?.lowerBound ?? stripped.endIndex)
            #endif

                return split.components(separatedBy: "/")
            }()

            if let type = components.first, let subtype = components.last {
                self.type = type
                self.subtype = subtype
            } else {
                return nil
            }
        }

        func matches(_ mime: MIMEType) -> Bool {
            switch (type, subtype) {
            case (mime.type, mime.subtype), (mime.type, "*"), ("*", mime.subtype), ("*", "*"):
                return true
            default:
                return false
            }
        }
    }

    // MARK: Properties

    fileprivate var acceptableStatusCodes: [Int] { return Array(200..<300) }

    fileprivate var acceptableContentTypes: [String] {
        if let accept = request?.value(forHTTPHeaderField: "Accept") {
            return accept.components(separatedBy: ",")
        }

        return ["*/*"]
    }

    // MARK: Status Code

    fileprivate func validate<S: Sequence>(
        statusCode acceptableStatusCodes: S,
        response: HTTPURLResponse)
        -> ValidationResult
        where S.Iterator.Element == Int
    {
        if acceptableStatusCodes.contains(response.statusCode) {
            return .success
        } else {
            let reason: ErrorReason = .unacceptableStatusCode(code: response.statusCode)
            return .failure(AFError.responseValidationFailed(reason: reason))
        }
    }

    // MARK: Content Type

    fileprivate func validate<S: Sequence>(
        contentType acceptableContentTypes: S,
        response: HTTPURLResponse,
        data: Data?)
        -> ValidationResult
        where S.Iterator.Element == String
    {
        guard let data = data, data.count > 0 else { return .success }

        guard
            let responseContentType = response.mimeType,
            let responseMIMEType = MIMEType(responseContentType)
        else {
            for contentType in acceptableContentTypes {
                if let mimeType = MIMEType(contentType), mimeType.isWildcard {
                    return .success
                }
            }

            let error: AFError = {
                let reason: ErrorReason = .missingContentType(acceptableContentTypes: Array(acceptableContentTypes))
                return AFError.responseValidationFailed(reason: reason)
            }()

            return .failure(error)
        }

        for contentType in acceptableContentTypes {
            if let acceptableMIMEType = MIMEType(contentType), acceptableMIMEType.matches(responseMIMEType) {
                return .success
            }
        }

        let error: AFError = {
            let reason: ErrorReason = .unacceptableContentType(
                a