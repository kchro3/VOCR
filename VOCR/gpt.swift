import Foundation
import Cocoa

let testJson = """
[
  {
	"label": "Menu Toolbar",
	"short_string": "Toolbar",
	"uid": 1,
	"description": "Toolbar containing various menu and tool icons for software functions",
	"content": "New project, Save, Open project, Undo, Redo, Metronome, Settings",
	"boundingBox": [0, 0, 2048, 40]
  },
  {
	"label": "Track Area",
	"short_string": "Tracks",
	"uid": 2,
	"description": "Area where tracks are displayed and edited",
	"content": "Multiple tracks with timestamps and edit controls",
	"boundingBox": [220, 40, 1700, 800]
  },
  {
	"label": "Transport Controls",
	"short_string": "Transport",
	"uid": 3,
	"description": "Controls for playback and recording",
	"content": "Play, Stop, Record, Repeat",
	"boundingBox": [10, 850, 200, 40]
  },
  {
	"label": "Master Track",
	"short_string": "Master",
	"uid": 4,
	"description": "Master track controls for the entire project",
	"content": "Volume fader, Mute, Solo, Pan, FX, Routing",
	"boundingBox": [10, 890, 200, 320]
  },
  {
	"label": "Transport Bar",
	"short_string": "TransportInfo",
	"uid": 5,
	"description": "Displays the current position, tempo, and playback status",
	"content": "Current position, Project sample rate, Beats per minute, Playback status",
	"boundingBox": [220, 840, 1700, 60]
  },
  {
	"label": "Vertical Scrollbar",
	"short_string": "VScroll",
	"uid": 6,
	"description": "Vertical scrollbar for navigating through tracks",
	"content": "Scrollbar with up and down arrows",
	"boundingBox": [1920, 40, 40, 860]
  },
  {
	"label": "Mixer Area",
	"short_string": "Mixer",
	"uid": 7,
	"description": "Mixer section for adjusting the balance of all tracks",
	"content": "Controls for volume, pan, inserts, sends for each track",
	"boundingBox": [10, 1210, 2030, 326]
  },
  {
	"label": "Licensing Information",
	"short_string": "LicenseInfo",
	"uid": 8,
	"description": "Displays the software registration status to a user",
	"content": "Software version and user registration note",
	"boundingBox": [650, 0, 750, 40]
  }
]
"""

struct GPTObservation: Decodable {
	let label: String
	let uid: Int
	let description: String
	let content: String
	let boundingBox: [Int]
	
	// Coding keys to match the JSON property names
	enum CodingKeys: String, CodingKey {
		case label
		case uid
		case description
		case content
		case boundingBox
	}
}


enum GPT {

	struct Response: Decodable {
		struct Choice: Decodable {
			struct Message: Decodable {
				let content: String
			}
			
			let message: Message
		}
		let choices: [Choice]
	}
	
	
	static func decode(message:String) -> [GPTObservation]? {
		let jsonData = message.data(using: .utf8)!
		do {
			let elements = try JSONDecoder().decode([GPTObservation].self, from: jsonData)
			for element in elements {
				print("Label: \(element.label), UID: \(element.uid), Bounding Box: \(element.boundingBox)")
			}
			return elements
		} catch {
			print("Error decoding JSON: \(error)")
		}
		return nil
	}

	static func extractString(text: String, startDelimiter: String, endDelimiter: String) -> String? {
		guard let startRange = text.range(of: startDelimiter) else {
			return nil // No start delimiter found
		}
		
		// Define the search start for the next delimiter to be right after the first delimiter
		let searchStartIndex = startRange.upperBound
		
		// Find the range of the next delimiter after the first delimiter
		guard let endRange = text.range(of: endDelimiter, range: searchStartIndex..<text.endIndex) else {
			return nil // No end delimiter found
		}
		
		// Extract the substring between the delimiters
		let startIndex = startRange.upperBound
		let endIndex = endRange.lowerBound
		return String(text[startIndex..<endIndex])
	}
	
	static func describe(_ image: CGImage, _ prompt: String, completion: @escaping (String) -> Void) {
//		completion(testJson)
//		return
		let bitmapRep = NSBitmapImageRep(cgImage: image)
		guard let imageData = bitmapRep.representation(using: .jpeg, properties: [:]) else {
			fatalError("Could not convert image to JPEG.")
			return
		}
		
		let base64_image = imageData.base64EncodedString(options: [])
		
		let jsonBody: [String: Any] = [
			"model": "gpt-4-vision-preview",
			"messages": [
				[
					"role": "system",
					"content": "You are a helpful assistant. Your response should be in JSON format."
				],
				[
					"role": "user",
					"content": [
						[
							"type": "text",
							"text": prompt
						],
						[
							"type": "image_url",
							"image_url": [
								"url": "data:image/jpeg;base64,\(base64_image)"
							]
						]
					]
				]
			],
			"max_tokens": 1000
		]
		
		let jsonData = try! JSONSerialization.data(withJSONObject: jsonBody, options: [])
		
		
		let url = URL(string: "https://api.openai.com/v1/chat/completions")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("Bearer \(Settings.GPTAPIKEY)", forHTTPHeaderField: "Authorization")
		request.httpBody = jsonData
		let session = URLSession.shared
		let task = session.dataTask(with: request) { data, response, error in
			guard let data = data, error == nil else {
				print("Request failed with error: \(error?.localizedDescription ?? "No data")")
				completion("Error: \(error?.localizedDescription ?? "No data")")
				return
			}
			do {
				let response = try JSONDecoder().decode(Response.self, from: data)
				if let firstChoice = response.choices.first {
					if let messageContent = extractString(text: firstChoice.message.content, startDelimiter: "```json\n", endDelimiter: "\n```") {
						completion(messageContent)
					}
				}
			} catch {
				print("Error decoding JSON: \(error)")
				completion("Error: Could not parse JSON.")
			}
			
			
		}
		task.resume()
	}
}
