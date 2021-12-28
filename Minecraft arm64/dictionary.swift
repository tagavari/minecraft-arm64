//
//  dictionary.swift
//  Minecraft arm64
//
//  Created by Cole Feuer on 2021-12-27.
//

import Foundation

func update(dictionary dict: inout [String: Any], at keys: [String], with value: Any) {

	if keys.count < 2 {
		for key in keys { dict[key] = value }
		return
	}

	var levels: [[String: Any]] = []

	for key in keys.dropLast() {
		if let lastLevel = levels.last {
			if let currentLevel = lastLevel[key] as? [String: Any] {
				levels.append(currentLevel)
			}
			else if lastLevel[key] != nil, levels.count + 1 != keys.count {
				break
			} else { return }
		} else {
			if let firstLevel = dict[keys[0]] as? [String : Any] {
				levels.append(firstLevel )
			}
			else { return }
		}
	}

	if levels[levels.indices.last!][keys.last!] != nil {
		levels[levels.indices.last!][keys.last!] = value
	} else { return }

	for index in levels.indices.dropLast().reversed() {
		levels[index][keys[index + 1]] = levels[index + 1]
	}

	dict[keys[0]] = levels[0]
}
