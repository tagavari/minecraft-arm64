//
//  hash.swift
//  Minecraft arm64
//
//  Created by Cole Feuer on 2021-12-27.
//

import Foundation
import CryptoKit

private let bufferSize = 1024 * 1024

///Calculates the size and hash of a URL
func analyzeURL(url: URL) -> (hash: String, count: Int) {
	let urlSessionDelegate = URLInfoSessionDelegate()
	let urlSession = URLSession(configuration: .default, delegate: urlSessionDelegate, delegateQueue: nil)
	
	//Open the URL for reading
	let task = urlSession.dataTask(with: url)
	task.resume()
	
	return try! urlSessionDelegate.getSync()
}

private class URLInfoSessionDelegate: NSObject, URLSessionDataDelegate {
	private var fileHash = Insecure.SHA1()
	private var fileLength = 0
	private var completionError: Error?
	private let completionSemaphore = DispatchSemaphore(value: 0)
	
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		fileHash.update(data: data)
		fileLength += data.count
	}
	
	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		//Record the error
		completionError = error
		
		//Notify completion listeners
		completionSemaphore.signal()
	}
	
	func getSync() throws -> (hash: String, count: Int) {
		//Wait for the task to complete
		completionSemaphore.wait()
		
		//Throw any errors
		if let error = completionError {
			throw error
		}
		
		//Return the hash as a hex value
		let md5Hash = fileHash.finalize().map { String(format: "%02hhx", $0) }.joined()
		return (md5Hash, fileLength)
	}
}
