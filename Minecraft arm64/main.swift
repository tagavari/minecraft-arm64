//
//  main.swift
//  Minecraft arm64
//
//  Created by Cole Feuer on 2021-12-25.
//

import Foundation

//Constants
let lwjglVersion = "3.3.0"

//Validate arguments
guard CommandLine.arguments.count > 1 else {
	print("Please provide the path to the profile directory")
	exit(EXIT_FAILURE)
}

let profileDirRaw = CommandLine.arguments[1]

//Parse the profile directory
let profileDir = URL(fileURLWithPath: NSString(string: profileDirRaw).expandingTildeInPath)
guard (try! profileDir.resourceValues(forKeys: [.isDirectoryKey])).isDirectory! else {
	print("\(profileDirRaw) is not a valid path")
	exit(EXIT_FAILURE)
}
let profileName = profileDir.lastPathComponent

//Make sure the profile directory is actually a profile directory
let profileFileJSON = profileDir.appendingPathComponent("\(profileName).json")
let profileFileJar = profileDir.appendingPathComponent("\(profileName).jar")
guard FileManager.default.fileExists(atPath: profileFileJSON.path),
	  FileManager.default.fileExists(atPath: profileFileJar.path) else {
		  print("\(profileDirRaw) is not a valid Minecraft profile directory")
		  exit(EXIT_FAILURE)
	  }

print("Adapting Minecraft profile \(profileName) for arm")

//Read the profile file
var jsonData = try! JSONSerialization.jsonObject(with: Data(contentsOf: profileFileJSON), options: .mutableContainers) as! [String: Any]

//Iterate over libraries
for (i, var library) in (jsonData["libraries"] as! [[String: Any]]).enumerated() {
	//Match library rules
	if let ruleArray = library["rules"] as? [[String: Any]] {
		guard checkRules(ruleArray) else { continue }
	}
	
	//Parse the library name
	let libraryInfo = JavaLibrary(string: library["name"] as! String)
	
	//Only replace LWJGL libraries
	guard libraryInfo.group == "org.lwjgl" else { continue }
	
	print("Checking library \(libraryInfo.id)...")
	
	let downloads = library["downloads"] as! [String: Any]
	
	do {
		//Get the official LWJGL file info
		let lwjglFileURL = "https://build.lwjgl.org/release/\(lwjglVersion)/bin/\(libraryInfo.id)/\(libraryInfo.id).jar"
		let (lwjglFileHash, lwjglFileSize) = analyzeURL(url: URL(string: lwjglFileURL)!)
		
		//Upgrade the common artifact
		var libraryArtifact = (downloads["artifact"] as! [String: Any])
		libraryArtifact["sha1"] = lwjglFileHash
		libraryArtifact["size"] = lwjglFileSize
		libraryArtifact["url"] = lwjglFileURL
		
		update(dictionary: &library, at: ["downloads", "artifact"], with: libraryArtifact)
	}
	
	//Check for natives
	if let nativesID = (library["natives"] as? [String: String])?[launcherOSID] {
		print("Checking library \(libraryInfo.id) natives...")
		
		//Get the official LWJGL file info
		let lwjglFileURL = "https://build.lwjgl.org/release/\(lwjglVersion)/bin/\(libraryInfo.id)/\(libraryInfo.id)-natives-\(lwjglOSID)-arm64.jar"
		let (lwjglFileHash, lwjglFileSize) = analyzeURL(url: URL(string: lwjglFileURL)!)
		
		//Update the library classifier
		var libraryClassifier = (downloads["classifiers"] as! [String: [String: Any]])[nativesID]!
		//let libraryPath = URL(fileURLWithPath: libraryClassifier["path"] as! String, isDirectory: false)
		//libraryClassifier["path"] = libraryPath.deletingLastPathComponent().appendingPathComponent(libraryPath.deletingPathExtension().lastPathComponent + "-arm" + "." + libraryPath.pathExtension).relativePath
		libraryClassifier["sha1"] = lwjglFileHash
		libraryClassifier["size"] = lwjglFileSize
		libraryClassifier["url"] = lwjglFileURL
		
		update(dictionary: &library, at: ["downloads", "classifiers", nativesID], with: libraryClassifier)
	}
	
	//Copy back to jsonData
	var jsonDataLibraries = jsonData["libraries"] as! [[String: Any]]
	jsonDataLibraries[i] = library
	jsonData["libraries"] = jsonDataLibraries
}

//Update profile ID
jsonData["id"] = (jsonData["id"] as! String) + "-arm"

//Create the new the profile directory
let updatedProfileName = "\(profileName)-arm"
let updatedProfileDir = profileDir.deletingLastPathComponent().appendingPathComponent(updatedProfileName)
let updatedProfileFileJSON = updatedProfileDir.appendingPathComponent("\(updatedProfileName).json")
let updatedProfileFileJar = updatedProfileDir.appendingPathComponent("\(updatedProfileName).jar")

if !FileManager.default.fileExists(atPath: updatedProfileDir.path) {
	try! FileManager.default.createDirectory(at: updatedProfileDir, withIntermediateDirectories: false, attributes: .none)
	try! FileManager.default.copyItem(at: profileFileJar, to: updatedProfileFileJar)
}

let outputStream = OutputStream(url: updatedProfileFileJSON, append: false)!
outputStream.open()
defer { outputStream.close() }
var error: NSError?
JSONSerialization.writeJSONObject(jsonData, to: outputStream, options: [.withoutEscapingSlashes, .prettyPrinted], error: &error)

if let error = error {
	throw error
}

print("Successfully created Minecraft profile \(updatedProfileName)")
