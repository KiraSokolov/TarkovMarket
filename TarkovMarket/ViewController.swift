//
//  ViewController.swift
//  TarkovMarket
//
//  Created by Will Chew on 2020-03-08.
//  Copyright © 2020 Will Chew. All rights reserved.
//

import UIKit
import Speech

struct Item : Codable {
    let name : String
    let uid : String
    let price : Int
    let updated : String
    let imgBig : String
    let currency : String
    let slots : Int
    
    
    enum CodingKeys : String, CodingKey {
        case name 
        case uid
        case price
        case updated
        case imgBig 
        case currency = "traderPriceCur"
        case slots
        
    }
}

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private let apiKey = ""
    var itemArray = [Item]()
    
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var microphoneButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        searchTextField.delegate = self
        tableView.tableFooterView = UIView()
        
        
        microphoneButton.isEnabled = false
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restrictd on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
            
            
            
            
            
            //        let dateString = "2020-03-15T01:38:01.380Z"
            
            
            //        getAllItems()
            //        let items = "Ammo, AK, btc"
            //        let favourites = items.wordList
            
            //        for favourite in favourites {
            //            getPrice(of: favourite)
            //        }
            //        getPrice(of: items)
            //        getPrice(of: "btc")
            
            // Do any additional setup after loading the view.
        }
    }
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record)
            try audioSession.setMode(.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            var lastString: String = ""
            var firstString: String = ""
            
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self.searchTextField.text = bestString
                isFinal = (result.isFinal)
                
                
                for segment in result.bestTranscription.segments {
                    let lastWordIndex = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)

                    
                    lastString = String(bestString.suffix(from: lastWordIndex))
                    firstString = String(bestString.prefix(upTo: lastWordIndex))
                    
                    
                    
                }
                if lastString == "search" {
                    
                    self.searchTextField.text = firstString
                    self.recognitionTask?.finish()
                    self.recognitionTask = nil
                    
                    // stop audio
                    recognitionRequest.endAudio()
                    self.audioEngine.stop()
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    
                    DispatchQueue.main.async {
                        self.microphoneButton.setImage(UIImage(systemName: "mic.circle"), for: .normal)
                        
                    }
                }
                
                if lastString == "reset" {
                    
                    print(result)
                    
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.microphoneButton.isEnabled = true
                
                
                if !firstString.isEmpty {
                    var searchTerm = ""
                    if firstString.lowercased().contains("dash") {
                        searchTerm = firstString.replacingOccurrences(of: "dash", with: "-")
                    }
                    searchTerm = firstString.replacingOccurrences(of: " - ", with: "-")
                    
                    self.getPrice(of: searchTerm)
                }
            }
            
            
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error")
        }
        
        searchTextField.text = "Say an item followed by the word 'search'"
    }
    
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    
    
    
    func getAllItems() {
        
        guard let url = URL(string: "https://tarkov-market.com/api/v1/items/all") else { return }
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        //        request.addValue("btc", forHTTPHeaderField: "q")
        
        session.dataTask(with: request) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else { return }
            
            do {
                let item = try JSONDecoder().decode([Item].self, from: data)
                
                for item in item {
                    self.itemArray.append(item)
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("ERROR")
            }
        }.resume()
        
    }
    
    func getPrice(of item: String) {
        
        print(item)
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tarkov-market.com"
        components.path = "/api/v1/item"
        let queryItemKey = URLQueryItem(name: "q", value: item)
        components.queryItems = [queryItemKey]
        
        
        let session = URLSession.shared
        guard let url = components.url else { return }
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        //        request.addValue("btc", forHTTPHeaderField: "q")
        
        session.dataTask(with: request) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else { return }
            
            do {
                let item = try JSONDecoder().decode([Item].self, from: data)
                
                for item in item {
                    
                    self.itemArray.insert(item, at: 0)
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("ERROR")
            }
        }.resume()
        
    }
    
    func calculateUpdated(last updated: Date) -> String {
        let timeUpdatedInHours = (updated.distance(to: Date()) / 3600)
        var measureOfTime = 0
        
        if timeUpdatedInHours / 24.0 > 1 {
            measureOfTime = Int((timeUpdatedInHours / 24.0).rounded())
            
            if measureOfTime == 1 {
                return "Updated 1 day ago"
            } else {
                return "Updated \(measureOfTime) days ago"
            }
            
            
        }
            
        else if timeUpdatedInHours > 1 {
            measureOfTime = Int(timeUpdatedInHours.rounded())
            
            if measureOfTime == 1 {
                return "Updated 1 hour ago"
            } else {
                return "Updated \(measureOfTime) hours ago"
            }
        }
            
        else if timeUpdatedInHours > 0 {
            measureOfTime = Int((timeUpdatedInHours * 60.0).rounded())
            
            if measureOfTime == 1 {
                return "Updated 1 minute ago"
            } else {
                return "Updated \(measureOfTime) minutes ago"
            }
        }
        else {
            return "Over a week ago"
        }
    }
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        guard let item = searchTextField.text else { return }
        getPrice(of: item)
        tableView.reloadData()
        self.view.endEditing(true)
    }
    
    @IBAction func microphoneTapped(_ sender: Any) {
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setImage(UIImage(systemName: "mic.circle"), for: .normal)
            searchTextField.text = nil
            
        } else {
            startRecording()
            microphoneButton.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
        }
        
    }
}

// #PRAGMA MARK: TableView functions

extension ViewController : UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell", for: indexPath) as! ItemTableViewCell
        
        
        
        cell.nameLabel.text = itemArray[indexPath.row].name
        
        
        
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let priceAsInt = Int(itemArray[indexPath.row].price)
        
        
        
        let slots = itemArray[indexPath.row].slots
        let pricePerSlot = priceAsInt / slots
        
        guard let formattedPrice = numberFormatter.string(from: NSNumber(value: priceAsInt)), let formattedSlotPrice = numberFormatter.string(from: NSNumber(value: pricePerSlot)) else { return cell }
        let currency = itemArray[indexPath.row].currency
        
        
        
        
        cell.priceLabel.text = "Price: \(formattedPrice)" + currency
        
        var slotString = ""
        if slots == 1 {
            slotString = "slot"
        } else {
            slotString = "slots"
        }
        cell.slotsLabel.text = "\(formattedSlotPrice)\(currency) per slot (\(slots) \(slotString))"
        
        
        
        
        
        
        let date = itemArray[indexPath.row].updated
        
        
        //        let dateString = date.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.").inverted)
        let dateStringWithoutT = date.replacingOccurrences(of: "T", with: " ")
        let date2 = dateStringWithoutT.prefix(upTo: dateStringWithoutT.firstIndex(of: ".")!)
        let inputFormatter = DateFormatter()
        
        
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var showDate = inputFormatter.date(from: String(date2))
        
        showDate?.addTimeInterval(-14400) // Time according to API is +4hrs from EST
        
        
        guard let displayDate = showDate else { return cell }
        
        
        
        cell.updatedLabel.text = calculateUpdated(last: displayDate)
        
        
        
        
        
        guard let url = URL(string: itemArray[indexPath.row].imgBig) else { return cell }
        cell.itemImageView?.load(url: url) {
            
            
            
            tableView.reloadData()
        }
        
        if cell.itemImageView.frame.width > cell.itemImageView.frame.height {
            cell.itemImageView.contentMode = .scaleAspectFit
        } else {
            cell.itemImageView.contentMode = .scaleAspectFill
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        
        return tableView.bounds.size.height / 2
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        searchButtonPressed(self)
        return true
    }
    
    
    
    
}

extension String {
    var wordList: [String] {
        return components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty
        }
    }
}

extension UIImageView {
    func load(url: URL, completion: @escaping() -> Void) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

