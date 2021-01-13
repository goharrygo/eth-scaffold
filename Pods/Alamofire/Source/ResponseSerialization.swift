
//
//  ResponseSerialization.swift
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

/// The type in which all data response serializers must conform to in order to serialize a response.
public protocol DataResponseSerializerProtocol {
    /// The type of serialized object to be created by this `DataResponseSerializerType`.
    associatedtype SerializedObject

    /// A closure used by response handlers that takes a request, response, data and error and returns a result.
    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<SerializedObject> { get }
}

// MARK: -

/// A generic `DataResponseSerializerType` used to serialize a request, response, and data into a serialized object.
public struct DataResponseSerializer<Value>: DataResponseSerializerProtocol {
    /// The type of serialized object to be created by this `DataResponseSerializer`.
    public typealias SerializedObject = Value

    /// A closure used by response handlers that takes a request, response, data and error and returns a result.
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Value>

    /// Initializes the `ResponseSerializer` instance with the given serialize response closure.
    ///
    /// - parameter serializeResponse: The closure used to serialize the response.
    ///
    /// - returns: The new generic response serializer instance.
    public init(serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Value>) {
        self.serializeResponse = serializeResponse
    }
}

// MARK: -

/// The type in which all download response serializers must conform to in order to serialize a response.
public protocol DownloadResponseSerializerProtocol {
    /// The type of serialized object to be created by this `DownloadResponseSerializerType`.
    associatedtype SerializedObject

    /// A closure used by response handlers that takes a request, response, url and error and returns a result.
    var serializeResponse: (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Result<SerializedObject> { get }
}

// MARK: -

/// A generic `DownloadResponseSerializerType` used to serialize a request, response, and data into a serialized object.
public struct DownloadResponseSerializer<Value>: DownloadResponseSerializerProtocol {
    /// The type of serialized object to be created by this `DownloadResponseSerializer`.
    public typealias SerializedObject = Value

    /// A closure used by response handlers that takes a request, response, url and error and returns a result.
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Result<Value>

    /// Initializes the `ResponseSerializer` instance with the given serialize response closure.
    ///
    /// - parameter serializeResponse: The closure used to serialize the response.
    ///
    /// - returns: The new generic response serializer instance.
    public init(serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Result<Value>) {
        self.serializeResponse = serializeResponse
    }
}

// MARK: - Timeline

extension Request {
    var timeline: Timeline {
        let requestStartTime = self.startTime ?? CFAbsoluteTimeGetCurrent()
        let requestCompletedTime = self.endTime ?? CFAbsoluteTimeGetCurrent()
        let initialResponseTime = self.delegate.initialResponseTime ?? requestCompletedTime

        return Timeline(
            requestStartTime: requestStartTime,
            initialResponseTime: initialResponseTime,
            requestCompletedTime: requestCompletedTime,
            serializationCompletedTime: CFAbsoluteTimeGetCurrent()
        )
    }
}

// MARK: - Default

extension DataRequest {
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:             The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    @discardableResult
    public func response(queue: DispatchQueue? = nil, completionHandler: @escaping (DefaultDataResponse) -> Void) -> Self {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                var dataResponse = DefaultDataResponse(
                    request: self.request,
                    response: self.response,
                    data: self.delegate.data,
                    error: self.delegate.error,
                    timeline: self.timeline
                )

                dataResponse.add(self.delegate.metrics)

                completionHandler(dataResponse)
            }
        }

        return self
    }

    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:              The queue on which the completion handler is dispatched.
    /// - parameter responseSerializer: The response serializer responsible for serializing the request, response,
    ///                                 and data.
    /// - parameter completionHandler:  The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    @discardableResult
    public func response<T: DataResponseSerializerProtocol>(
        queue: DispatchQueue? = nil,
        responseSerializer: T,
        completionHandler: @escaping (DataResponse<T.SerializedObject>) -> Void)
        -> Self
    {
        delegate.queue.addOperation {
            let result = responseSerializer.serializeResponse(
                self.request,
                self.response,
                self.delegate.data,
                self.delegate.error
            )

            var dataResponse = DataResponse<T.SerializedObject>(
                request: self.request,
                response: self.response,
                data: self.delegate.data,
                result: result,
                timeline: self.timeline
            )

            dataResponse.add(self.delegate.metrics)

            (queue ?? DispatchQueue.main).async { completionHandler(dataResponse) }
        }

        return self
    }
}

extension DownloadRequest {
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:             The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    @discardableResult
    public func response(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DefaultDownloadResponse) -> Void)
        -> Self
    {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                var downloadResponse = DefaultDownloadResponse(
                    request: self.request,
                    response: self.response,
                    temporaryURL: self.downloadDelegate.temporaryURL,
                    destinationURL: self.downloadDelegate.destinationURL,
                    resumeData: self.downloadDelegate.resumeData,
                    error: self.downloadDelegate.error,
                    timeline: self.timeline
                )

                downloadResponse.add(self.delegate.metrics)

                completionHandler(downloadResponse)
            }
        }

        return self
    }

    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:              The queue on which the completion handler is dispatched.
    /// - parameter responseSerializer: The response serializer responsible for serializing the request, response,
    ///                                 and data contained in the destination url.
    /// - parameter completionHandler:  The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    @discardableResult
    public func response<T: DownloadResponseSerializerProtocol>(
        queue: DispatchQueue? = nil,
        responseSerializer: T,
        completionHandler: @escaping (DownloadResponse<T.SerializedObject>) -> Void)
        -> Self
    {
        delegate.queue.addOperation {
            let result = responseSerializer.serializeResponse(
                self.request,
                self.response,
                self.downloadDelegate.fileURL,
                self.downloadDelegate.error
            )

            var downloadResponse = DownloadResponse<T.SerializedObject>(
                request: self.request,
                response: self.response,
                temporaryURL: self.downloadDelegate.temporaryURL,
                destinationURL: self.downloadDelegate.destinationURL,
                resumeData: self.downloadDelegate.resumeData,
                result: result,
                timeline: self.timeline
            )

            downloadResponse.add(self.delegate.metrics)

            (queue ?? DispatchQueue.main).async { completionHandler(downloadResponse) }
        }

        return self
    }
}

// MARK: - Data

extension Request {
    /// Returns a result data type that contains the response data as-is.
    ///
    /// - parameter response: The response from the server.
    /// - parameter data:     The data returned from the server.
    /// - parameter error:    The error already encountered if it exists.
    ///
    /// - returns: The result data type.
    public static func serializeResponseData(response: HTTPURLResponse?, data: Data?, error: Error?) -> Result<Data> {
        guard error == nil else { return .failure(error!) }

        if let response = response, emptyDataStatusCodes.contains(response.statusCode) { return .success(Data()) }

        guard let validData = data else {
            return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
        }

        return .success(validData)
    }
}

extension DataRequest {
    /// Creates a response serializer that returns the associated data as-is.
    ///
    /// - returns: A data response serializer.
    public static func dataResponseSerializer() -> DataResponseSerializer<Data> {
        return DataResponseSerializer { _, response, data, error in
            return Request.serializeResponseData(response: response, data: data, error: error)
        }
    }

    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    @discardableResult
    public func responseData(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<Data>) -> Void)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: DataRequest.dataResponseSerializer(),
            completionHandler: completionHandler
        )
    }
}

extension DownloadRequest {
    /// Creates a response serializer that returns the associated data as-is.
    ///
    /// - returns: A data response serializer.
    public static func dataResponseSerializer() -> DownloadResponseSerializer<Data> {
        return DownloadResponseSerializer { _, response, fileURL, error in
            guard error == nil else { return .failure(error!) }

            guard let fileURL = fileURL else {
                return .failure(AFError.responseSerializationFailed(reason: .inputFileNil))
            }

            do {
                let data = try Data(contentsOf: fileURL)
                return Request.serializeResponseData(response: response, data: data, error: error)
            } catch {
                return .failure(AFError.responseSerializationFailed(reason: .inputFileReadFailed(at: fileURL)))
            }
        }
    }

    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    @discardableResult
    public func responseData(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DownloadResponse<Data>) -> Void)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: DownloadRequest.dataResponseSerializer(),
            completionHandler: completionHandler
        )
    }
}
