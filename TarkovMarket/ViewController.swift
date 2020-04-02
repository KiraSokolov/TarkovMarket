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
    let diff24h : Double
    let diff7days : Double
    
    
    enum CodingKeys : String, CodingKey {
        case name 
        case uid
        case price
        case updated
        case imgBig 
        case currency = "traderPriceCur"
        case slots
        case diff24h
        case diff7days
        
    }
}

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private let apiKey = ""
    
    var itemArray = [Item]()
    var listening: Bool = false
    var height : CGFloat = 0.0
    
    
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    var timer : Timer?
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
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

        
        let tableHeight : CGFloat = tableView.bounds.height
        let tableWidth : CGFloat = tableView.bounds.width
        
        print(#line, tableHeight, tableWidth)
        
        if tableHeight > tableWidth {
            height = tableView.frame.height / 2
        } else if tableWidth > tableHeight {
            height = tableView.frame.height
        }
        
        //SPINNER
        
        spinner.isHidden = true
        
        if traitCollection.userInterfaceStyle == .dark {
            microphoneButton.setTitleColor(.white, for: .normal)
        }
        
        
        searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        microphoneButton.translatesAutoresizingMaskIntoConstraints = false
        let height = self.view.bounds.height / 10
        microphoneButton.heightAnchor.constraint(equalToConstant: height).isActive = true
        
        microphoneButton.titleLabel?.textAlignment = .center
        microphoneButton.setTitle("Tap Here for Voice Activation", for: .normal)
        microphoneButton.isEnabled = false
        speechRecognizer.delegate = self
        
        self.requestSpeechRecognition()
        

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
    
    
    
    
    
    //    func getAllItems() {
    //
    //        guard let url = URL(string: "https://tarkov-market.com/api/v1/items/all") else { return }
    //        let session = URLSession.shared
    //
    //        var request = URLRequest(url: url)
    //        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
    //        //        request.addValue("btc", forHTTPHeaderField: "q")
    //
    //        session.dataTask(with: request) { (data, response, error) in
    //            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else { return }
    //
    //            do {
    //                let item = try JSONDecoder().decode([Item].self, from: data)
    //
    //                for item in item {
    //                    self.itemArray.append(item)
    //                }
    //                DispatchQueue.main.async {
    //                    self.tableView.reloadData()
    //                }
    //            } catch {
    //                print("ERROR")
    //            }
    //        }.resume()
    //
    //    }
    
    func getPrice(of item: String, completion: @escaping () -> ()) {
        
        let itemName = "q"
        
        print(#line, item)
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "tarkov-market.com"
        components.path = "/api/v1/item"
        let queryItemKey = URLQueryItem(name: itemName, value: item)
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
            completion()
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
    
//    @IBAction func searchButtonPressed(_ sender: Any) {
//
//        if searchTextField.text != "Say the item name followed by 'search'" || searchTextField.text != "" {
//
//
//            guard let item = searchTextField.text, item != "" else { return }
//            print(itemArray.count)
//            let count = itemArray.count
//            getPrice(of: item) {
//                self.compareItemArrays(before: count, after: self.itemArray.count)
//            }
//            //            print(#line, itemArray.count)
//            //            compareItemArrays(before: count, after: itemArray.count)
//
//            tableView.reloadData()
//            self.view.endEditing(true)
//
//        }
//    }
    
    
    func compareItemArrays(before: Int, after: Int) {
        

        DispatchQueue.main.async {

                self.spinner.isHidden = true
                self.spinner.stopAnimating()
        if before == after {
            
                
                let alert = UIAlertController(title: "No item found", message: "Please try again", preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                
                let timer = DispatchTime.now() + 1.5
                DispatchQueue.main.asyncAfter(deadline: timer) {
                    
                    alert.dismiss(animated: true, completion: nil)
                }
            }
        }
       
    }
    
    @IBAction func microphoneTapped(_ sender: Any?) {
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setImage(UIImage(systemName: "mic.circle"), for: .normal)
            searchTextField.text = ""
            
          
            
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
        
        
        let referenceItem = itemArray[indexPath.row]
        
        
        cell.nameLabel.text = referenceItem.name
        
        
        
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let priceAsInt = Int(referenceItem.price)
        
        
        
        let slots = referenceItem.slots
        let pricePerSlot = priceAsInt / slots
        
        guard let formattedPrice = numberFormatter.string(from: NSNumber(value: priceAsInt)), let formattedSlotPrice = numberFormatter.string(from: NSNumber(value: pricePerSlot)) else { return cell }
        let currency = referenceItem.currency
        
        
        
        
        cell.priceLabel.text = "Price: \(formattedPrice)" + currency
        
        var slotString = ""
        if slots == 1 {
            slotString = "slot"
        } else {
            slotString = "slots"
        }
        cell.slotsLabel.text = "\(formattedSlotPrice)\(currency) per slot (\(slots) \(slotString))"
        
        
        
        let red = UIColor(red: 184.0 / 255.0, green: 48.0 / 255.0, blue: 48.0 / 255.0, alpha: 1)
        let green = UIColor(red: 49.0 / 255.0, green: 120.0 / 255.0, blue: 79.0 / 255.0, alpha: 1)
        let redFontAttribute = [NSAttributedString.Key.foregroundColor : red]
        let greenFontAttribute = [NSAttributedString.Key.foregroundColor : green]
        let blackFontAttribute = [NSAttributedString.Key.foregroundColor : UIColor.black]
//        string: "\(referenceItem.diff24h)%", attributes: redFontAttribute)
        var dayAttributedString : NSMutableAttributedString
        var weekAttributedString : NSMutableAttributedString
        let dayLabel = NSMutableAttributedString(string: "Diff in 24h: ", attributes: blackFontAttribute)
         let weekLabel = NSMutableAttributedString(string: "Diff in 7d: ", attributes: blackFontAttribute)
        
        
//        dayLabel.append(attributedString)
        
        if referenceItem.diff24h < 0 {
            dayAttributedString = NSMutableAttributedString(string: "\(referenceItem.diff24h)%", attributes: redFontAttribute)
        } else if referenceItem.diff24h > 0 {
            dayAttributedString = NSMutableAttributedString(string: "\(referenceItem.diff24h)%", attributes: greenFontAttribute)
        } else {
            dayAttributedString = NSMutableAttributedString(string: "\(referenceItem.diff24h)%", attributes: blackFontAttribute)
        }
        
        dayLabel.append(dayAttributedString)
        cell.dayDiffLabel.attributedText = dayLabel

        if referenceItem.diff7days < 0 {
            weekAttributedString = NSMutableAttributedString(string: "\(referenceItem.diff7days)%", attributes: redFontAttribute)
        } else if referenceItem.diff7days > 0 {
            weekAttributedString = NSMutableAttributedString(string: "\(referenceItem.diff7days)%", attributes: greenFontAttribute)
        } else {
            weekAttributedString = NSMutableAttributedString(string: "\(referenceItem.diff7days)%", attributes: blackFontAttribute)
        }
        
        weekLabel.append(weekAttributedString)
        cell.weekDiffLabel.attributedText = weekLabel
            

        
        
        
        let date = referenceItem.updated
        let dateStringWithoutT = date.replacingOccurrences(of: "T", with: " ")
        let date2 = dateStringWithoutT.prefix(upTo: dateStringWithoutT.firstIndex(of: ".")!)
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var showDate = inputFormatter.date(from: String(date2))
        showDate?.addTimeInterval(-14400) // Time according to API is +4hrs from EST
        guard let displayDate = showDate else { return cell }
        cell.updatedLabel.text = calculateUpdated(last: displayDate)
        
        
        
        
        guard let url = URL(string: referenceItem.imgBig) else { return cell }
        cell.itemImageView?.load(url: url) {
         
            tableView.reloadData()
        }
        
        if cell.itemImageView.frame.width > cell.itemImageView.frame.height {
            cell.itemImageView.contentMode = .scaleAspectFit
        } else {
            cell.itemImageView.contentMode = .scaleAspectFill
        }
        
        print("picture height", cell.itemImageView.bounds.size.height)
                print("picture width", cell.itemImageView.bounds.size.width)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight:
            return height
        case .portrait, .portraitUpsideDown:
            return height
        default:
            break
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // #PRAGMA MARK: Textfield functions
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
//        searchButtonPressed(self) ************* IF I WANT TO RE-ENABLE SEARCH BUTTON ************
        return true
    }
    
    @objc func textFieldDidChange(_ textfield: UITextField) {
        if let timer = timer {
            timer.invalidate()
        }
        
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(search(_:)), userInfo: textfield.text, repeats: false)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode(rawValue: "NSDefaultRunLoopMode"))
        
        
    }
        
    @objc func search(_ timer: Timer) {
        if let searchText = timer.userInfo as? String {
            let count = itemArray.count
            
            if searchText != "" && searchText.count > 3 {
            getPrice(of: searchText) {
                self.compareItemArrays(before: count, after: self.itemArray.count)
               
                
            }
                searchTextField.resignFirstResponder()
            }
            
        }
    }
}

// #PRAGMA MARK : Speech functions
extension ViewController {
    func requestSpeechRecognition() {
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
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            @unknown default:
                return
            }
            
            OperationQueue.main.addOperation {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
            searchTextField.text = ""
            
            
//
            

        }
        
        var isRecording : Bool = false
        
     
        
        func toggleButton() {
            isRecording.toggle()
            
            if !isRecording {
                microphoneButton.setTitle("Tap Here for Voice Activation", for: .normal)
                microphoneButton.setImage(UIImage(systemName: "mic.circle"), for: .normal)
                searchTextField.placeholder = "Search item name"
             
                
            } else {
                microphoneButton.setTitle("Go ahead I'm listening", for: .normal)
                microphoneButton.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
                searchTextField.placeholder = "Say the item name followed by 'search'"
            }
        }
        
        
        //        self.microphoneButton.isEnabled = false
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record)
            try audioSession.setMode(.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            toggleButton()
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
            self.spinner.isHidden = false
            self.spinner.startAnimating()
            
            func stopRecording() {
                self.audioEngine.stop()
                self.recognitionRequest?.endAudio()
                
                
                self.recognitionTask?.finish()
                
                self.audioEngine.inputNode.removeTap(onBus: 0);
                self.audioEngine.inputNode.reset()
                self.microphoneButton.isEnabled = true
                DispatchQueue.main.async {
                              self.spinner.isHidden = true
                              self.spinner.stopAnimating()
                          }
                
                toggleButton()
                
            }
            
            
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
                    
                    
                    //                    self.recognitionTask?.finish()
                    //                    self.recognitionTask = nil
                    //
                    //                    // stop audio
                    //                    recognitionRequest.endAudio()
                    //                    self.audioEngine.stop()
                    //                    self.audioEngine.inputNode.removeTap(onBus: 0)
                    stopRecording()
                    
                    DispatchQueue.main.async {
                        toggleButton()
                        
                    }
                }
                
            } else if result == nil {
                stopRecording()
                toggleButton()
                
            }
            
            if error != nil || isFinal {
                //                self.audioEngine.stop()
                //                inputNode.removeTap(onBus: 0)
                //                self.recognitionRequest = nil
                //                self.recognitionTask = nil
                //                self.microphoneButton.isEnabled = true
                //
                stopRecording()
                
                if !firstString.isEmpty {
                    var searchTerm = firstString
                    
                    if firstString.lowercased().contains("dash") {
                        searchTerm = firstString.replacingOccurrences(of: "dash", with: "test")
                        
                        
                    }
                    
                    if searchTerm.contains(" – ") {
                        searchTerm = searchTerm.replacingOccurrences(of: " – ", with: "-")
                    }
                    
                    self.searchTextField.text = searchTerm
                    let count = self.itemArray.count
                    self.getPrice(of: searchTerm) {
                        self.compareItemArrays(before: count, after: self.itemArray.count)
                    }
                    
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
        

        searchTextField.placeholder = "Say the item name followed by 'search'"
        print(#line, isRecording)
     
        
    }
    
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
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

