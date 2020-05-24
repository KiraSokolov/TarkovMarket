//
//  ViewController.swift
//  TarkovMarket
//
//  Created by Will Chew on 2020-03-08.
//  Copyright © 2020 Will Chew. All rights reserved.
//

// app-id ca-app-pub-4857948317177675~9672993935
// add unit-id ca-app-pub-4857948317177675/1514947091


import UIKit
import Speech
import GoogleMobileAds


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
    let traderPrice : Int
    let traderName : String
    
    
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
        case traderPrice
        case traderName
        
    }
}

class ViewController: UIViewController, SFSpeechRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIGestureRecognizerDelegate {
    
    
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private let apiKey = ""
    
    var itemArray = [Item]()
    var height : CGFloat = 0.0
    
    
    let languageArray = ["en", "ru", "de", "fr", "es", "cn"]
    var languageSelected = UserDefaults.standard.string(forKey: "Language")
    var blurEffectView : UIVisualEffectView!
    var dismissLangTapGesture : UITapGestureRecognizer!
    
    
    var favouriteSet : Set<String> = []
    var favouritesArray : [String] = []
    
    
    //    var savedLanguage = UserDefaults.standard.string(forKey: "Language")
    
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    var timer : Timer?
    let green = UIColor(red: 49.0 / 255.0, green: 120.0 / 255.0, blue: 79.0 / 255.0, alpha: 1)
    
    
    
    @IBOutlet var languagePickerView: UIView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var submitLangButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        bannerView.delegate = self
        searchTextField.delegate = self
        tableView.delegate = self
        speechRecognizer.delegate = self
        tableView.dataSource = self
        
        
        bannerView.adUnitID = "ca-app-pub-4857948317177675/1514947091"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        
        tableView.tableFooterView = UIView()
        spinner.isHidden = true
        
        if traitCollection.userInterfaceStyle == .dark {
            microphoneButton.setTitleColor(.green, for: .normal)
            
        }
        
        
        searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        
        configureMicButton()
        self.requestSpeechRecognition()
        
        
        
        if languageSelected == nil {
            UserDefaults.standard.set("en", forKey: "Language")
        }
        
        
        
        guard let favouriteArr = UserDefaults.standard.array(forKey: "Favourites") as? [String] else { return }
        favouriteSet = Set(favouriteArr)
        favouritesArray = favouriteArr
        
        
    }
    
    
    func getPrice(of item: String, completion: @escaping () -> ()) {
        
        // IF THERE IS NO API KEY INSERTED.
        if self.apiKey == "" {
            if let path = Bundle.main.url(forResource: "items", withExtension: "json") {
                do {
                    let sampleData = try Data(contentsOf: path)
                    let jsonData = try JSONDecoder().decode([Item].self, from: sampleData)
                    for item in jsonData {
                        self.itemArray.insert(item, at: 0)
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                } catch {
                    print(error)
                }
            }
            
        } else {
            
            // REGULAR FUNCTION WITH API KEY PROVIDED.
            let itemName = "q"
            
            print(#line, item)
            self.spinner.isHidden = false
            self.spinner.startAnimating()
            
            var components = URLComponents()
            components.scheme = "https"
            components.host = "tarkov-market.com"
            components.path = "/api/v1/item"
            let queryItemName = URLQueryItem(name: itemName, value: item)
            let queryLanguage = URLQueryItem(name: "lang", value: languageSelected)
            components.queryItems = [queryItemName, queryLanguage]
            
            
            let session = URLSession.shared
            guard let url = components.url else { return }
            var request = URLRequest(url: url)
            request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
            //        request.addValue("btc", forHTTPHeaderField: "q")
            
            session.dataTask(with: request) { (data, response, error) in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                    
                    DispatchQueue.main.async {
                        
                        let errorAlert = UIAlertController(title: "Error has occured", message: "Please try again.", preferredStyle: .alert)
                        
                        self.present(errorAlert, animated: true, completion: nil)
                        let dismissTimer = DispatchTime.now() + 1.5
                        DispatchQueue.main.asyncAfter(deadline: dismissTimer) {
                            
                            errorAlert.dismiss(animated: true, completion: nil)
                            self.spinner.isHidden = true
                            self.spinner.stopAnimating()
                        }
                    }
                    
                    return }
                
                
                do {
                    
                    let item = try JSONDecoder().decode([Item].self, from: data)
                    for item in item {
                        self.itemArray.insert(item, at: 0)
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } catch {
                    print(error.localizedDescription)
                }
                completion()
            }.resume()
            
        }
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
    
    
    
    func compareItemArrays(before: Int, after: Int) {
        
        
        DispatchQueue.main.async {
            
            self.spinner.isHidden = true
            self.spinner.stopAnimating()
            if before == after {
                
                
                let alert = UIAlertController(title: "No item found", message: "Please try again", preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
                
                let dismissTimer = DispatchTime.now() + 1.5
                DispatchQueue.main.asyncAfter(deadline: dismissTimer) {
                    
                    alert.dismiss(animated: true, completion: nil)
                    
                }
            }
        }
        
    }
    
    
    @objc func favourited(sender: UIButton) {
        let buttonTag = sender.tag
        
        
        
        if favouriteSet.count < 5 {
            if !favouriteSet.contains(itemArray[buttonTag].name) {
                favouriteSet.insert(itemArray[buttonTag].name)
            } else {
                favouriteSet.remove(itemArray[buttonTag].name)
            }
            favouritesArray = Array(favouriteSet)
            
            UserDefaults.standard.set(favouritesArray, forKey: "Favourites")
        }
        
        let indexPosition = IndexPath(row: buttonTag, section: 0)
        tableView.reloadRows(at: [indexPosition], with: .none)
        
        
    }
    
    func configureMicButton() {
        microphoneButton.translatesAutoresizingMaskIntoConstraints = false
        microphoneButton.heightAnchor.constraint(equalToConstant: self.view.bounds.height / 20).isActive = true
        microphoneButton.contentMode = .scaleAspectFit
        microphoneButton.setTitle("Tap Here for Voice Activation", for: .normal)
        microphoneButton.isEnabled = false
        
        microphoneButton.layer.borderWidth = 1.5
        microphoneButton.layer.borderColor = green.cgColor
        microphoneButton.layer.cornerRadius = 20
        microphoneButton.layer.shadowColor = UIColor.black.cgColor
        microphoneButton.layer.shadowOffset = CGSize(width: 5, height: 5)
        microphoneButton.layer.shadowRadius = 5
        microphoneButton.layer.shadowOpacity = 0.5
        
        submitLangButton.layer.cornerRadius = 5
        submitLangButton.layer.borderWidth = 1
        submitLangButton.layer.borderColor = UIColor.black.cgColor
    }
    
    //#PRAGMA MARK: LANGUAGE VIEW FUNCTIONS
    func animateViewIn() {
        
        if !UIAccessibility.isReduceTransparencyEnabled {
            languagePickerView.layer.cornerRadius = 10
            blurEffectView = UIVisualEffectView(effect: nil)
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(blurEffectView)
            
        } else {
            view.backgroundColor = .black
        }
        self.view.addSubview(languagePickerView)
        languagePickerView.center = self.view.center
        languagePickerView.backgroundColor = .gray
        languagePickerView.alpha = 0
        self.navigationController?.isNavigationBarHidden = true
        
        dismissLangTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissLanguage(_:)))
        self.view.addGestureRecognizer(dismissLangTapGesture)
        dismissLangTapGesture.delegate = self
        
        UIView.animate(withDuration: 0.3) {
            self.blurEffectView.effect = UIBlurEffect(style: .dark)
            self.languagePickerView.alpha = 1
        }
        
    }
    
    func animateViewOut() {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.languagePickerView.alpha = 0
            self.blurEffectView.effect = nil
            self.navigationController?.isNavigationBarHidden = false
        }) { (_) in
            self.languagePickerView.removeFromSuperview()
            self.blurEffectView.removeFromSuperview()
            self.view.removeGestureRecognizer(self.dismissLangTapGesture)
            
        }
        
    }
    
    @objc func dismissLanguage(_ sender: UITapGestureRecognizer) {
        animateViewOut()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languageArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languageArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        
        languageSelected = languageArray[row]
        
        
        
    }
    
    
    
    
    //#PRAGMA MARK: IBACTIONS
    
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
    
    @IBAction func languageButtonPressed(_ sender: Any) {
        
        animateViewIn()
        
    }
    
    
    @IBAction func favouriteButtonPressed(_ sender: Any) {
        itemArray.removeAll()
        
        if !favouritesArray.isEmpty {
            for favourite in favouritesArray {
                getPrice(of: favourite) {
                    self.compareItemArrays(before: 0, after: self.itemArray.count)
                }
            }
        } else {
            tableView.reloadData()
        }
    }
    
    
    @IBAction func submitLangButtonPressed(_ sender: Any) {
        
        UserDefaults.standard.set(languageSelected, forKey: "Language")
        animateViewOut()
        
    }
    
    
    @IBAction func commandsButtonPressed(_ sender: UIButton) {
        
        let commandsString = """
Say "search" after the item name to search
Say "reset" to start over
Say "cancel" to end voice recognition

Try to be more specific or speak clearly if you can't find what you are looking for.
Thank you for your support!
"""
        
        
        let alert = UIAlertController(title: "Info", message: commandsString, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    
}

// #PRAGMA MARK: TableView Functions

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
        
        let traderName = referenceItem.traderName
        
        
        let traderPrice = referenceItem.traderPrice
        
        guard let formattedPrice = numberFormatter.string(from: NSNumber(value: priceAsInt)),
            let formattedSlotPrice = numberFormatter.string(from: NSNumber(value: pricePerSlot))
            else { return cell }
        
        let currency = referenceItem.currency
        
        if traderName != "" {
            guard let formattedTraderPrice = numberFormatter.string(from: NSNumber(value: traderPrice)) else { return cell }
            
            cell.traderPriceLabel.text = "\(traderName) will buy for \(formattedTraderPrice)\(currency)"
            
        } else {
            cell.traderPriceLabel.text = ""
        }
        
        
        cell.priceLabel.text = "Price: \(formattedPrice)" + currency
        
        var slotString = ""
        if slots == 1 {
            slotString = "slot"
        } else {
            slotString = "slots"
        }
        cell.slotsLabel.text = "\(formattedSlotPrice)\(currency) per slot (\(slots) \(slotString))"
        
        
        
        let red = UIColor(red: 184.0 / 255.0, green: 48.0 / 255.0, blue: 48.0 / 255.0, alpha: 1)
        
        let redFontAttribute = [NSAttributedString.Key.foregroundColor : red]
        let greenFontAttribute = [NSAttributedString.Key.foregroundColor : green]
        let blackFontAttribute = [NSAttributedString.Key.foregroundColor : UIColor.darkGray]
        
        var dayAttributedString : NSMutableAttributedString
        var weekAttributedString : NSMutableAttributedString
        let dayLabel = NSMutableAttributedString(string: "Diff in 24h: ", attributes: blackFontAttribute)
        let weekLabel = NSMutableAttributedString(string: "Diff in 7d: ", attributes: blackFontAttribute)
        
        
        if referenceItem.diff24h < 0 {
            dayAttributedString = NSMutableAttributedString(string: "\(referenceItem.diff24h)%", attributes: redFontAttribute)
        } else if referenceItem.diff24h > 0 {
            dayAttributedString = NSMutableAttributedString(string: "+\(referenceItem.diff24h)%", attributes: greenFontAttribute)
        } else {
            dayAttributedString = NSMutableAttributedString(string: "\(referenceItem.diff24h)%", attributes: blackFontAttribute)
        }
        
        dayLabel.append(dayAttributedString)
        cell.dayDiffLabel.attributedText = dayLabel
        
        if referenceItem.diff7days < 0 {
            weekAttributedString = NSMutableAttributedString(string: "\(referenceItem.diff7days)%", attributes: redFontAttribute)
        } else if referenceItem.diff7days > 0 {
            weekAttributedString = NSMutableAttributedString(string: "+\(referenceItem.diff7days)%", attributes: greenFontAttribute)
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
        
        
        
        cell.favouriteButton.addTarget(self, action: #selector(favourited(sender:)), for: .touchUpInside)
        cell.favouriteButton.tag = indexPath.row
        
        
        if favouriteSet.contains(referenceItem.name) {
            cell.favouriteButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
            cell.favouriteButton.setTitle("Favorited", for: .normal)
        } else {
            cell.favouriteButton.setImage(UIImage(systemName: "star"), for: .normal)
            cell.favouriteButton.setTitle("Add to Favorites", for: .normal)
        }
        
        if traitCollection.userInterfaceStyle == .dark {
            cell.favouriteButton.setTitleColor(.white, for: .normal)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        
        if view.frame.height > view.frame.width {
            height = tableView.bounds.height / 2.5
            
        } else {
            height = tableView.bounds.width / 3.5
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
            
            if searchText != "" && searchText.count > 2 {
                getPrice(of: searchText) {
                    self.compareItemArrays(before: count, after: self.itemArray.count)
                    
                    
                }
                searchTextField.resignFirstResponder()
            }
            
        }
    }
}

// #PRAGMA MARK: AD Functions

extension ViewController: GADBannerViewDelegate {
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("Received ad")
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error)
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
            var lastString : String = ""
            var firstString : String = ""
            self.spinner.isHidden = false
            self.spinner.startAnimating()
            var restart : Bool = false
            var shouldSearch : Bool = false
            
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
                    toggleButton()
                }
                
                
                
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
                    
                    stopRecording()
                    
                    restart = true
                    shouldSearch = true
                    
                    DispatchQueue.main.async {
                        toggleButton()
                        
                    }
                    
                    
                }
                    
                else if bestString == "Cancel" || lastString == "cancel" {
                    stopRecording()
                    self.searchTextField.text = nil
                    restart = false
                    
                    toggleButton()
                }
                    
                else if bestString == "Reset" || lastString == "reset" {
                    
                    stopRecording()
                    restart = true
                    self.searchTextField.text = nil
                    toggleButton()
                    
                    
                }
                
            } else if result == nil {
                stopRecording()
                toggleButton()
                
            }
            
            if error != nil || isFinal {
                
                stopRecording()
                
                if !firstString.isEmpty {
                    var searchTerm = firstString
                    
                    if firstString.lowercased().contains("dash") {
                        searchTerm = firstString.replacingOccurrences(of: "Dash", with: "test")
                        
                        
                    }
                    
                    if searchTerm.contains(" – ") {
                        searchTerm = searchTerm.replacingOccurrences(of: " – ", with: "-")
                    }
                    
                    self.searchTextField.text = searchTerm
                    let count = self.itemArray.count
                    
                    if restart {
                        self.microphoneTapped(self)
                        toggleButton()
                        if shouldSearch {
                            self.getPrice(of: searchTerm) {
                                self.compareItemArrays(before: count, after: self.itemArray.count)
                            }
                        }
                        
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
        
        
        
    }
    
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
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



