// Version 0.030

//  FootballTableViewController.swift
//  NBPS Sports
//
//  Created by Evan Von Oehsen on 3/5/17.
//  Copyright © 2017 NBPS Athletics. All rights reserved.
//

import UIKit
import Firebase
import Timepiece
import Social


class FootballTableViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var editField: UITextField!
    @IBOutlet weak var editorLabel: UILabel!
    @IBOutlet var editorView: UIView!
    @IBOutlet weak var picker: UIPickerView!
    
    @IBOutlet weak var homeLabel: UILabel!
    @IBOutlet weak var awayLabel: UILabel!
    @IBOutlet weak var homeScoreLabel: UILabel!
    @IBOutlet weak var awayScoreLabel: UILabel!
    
    @IBOutlet weak var homeScoreStepper: UIStepper!
    @IBOutlet weak var awayScoreStepper: UIStepper!
    
    @IBOutlet weak var gameDatePicker: UIDatePicker!
    @IBOutlet weak var headerView: UIView!
    
    var homeScoreVal: Int!
    var awayScoreVal: Int!
    var gameDateVal: Date!
    
    var selectedPath = [Int]()
    
    var blurEffect: UIBlurEffect!
    var blurEffectView: UIVisualEffectView!
    
    var currentGame: String!
    
    var ref: FIRDatabaseReference!
    fileprivate var _refHandle: FIRDatabaseHandle?
    
    var pastGame = true
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var editorOpen:Bool!
    
    var pickerComponents = [Dictionary<String,String>]()
    
    var pickerSelection = 0
    
    
 //   var games: [[Dictionary<String,String>]]?
    var gamesArray = [FIRDataSnapshot]()
    var games = [[Dictionary<String, Any>]]()
    
    //var games = [[["Game":0, "Year":2016,"Month":3,"Day":12]],[["Game":1, "Year":2017,"Month":3,"Day":18]]]
    
    var gamesCount = 0
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.hideKeyboardWhenTappedAround()

        
        ref = FIRDatabase.database().reference()
        
        
        
        editorView.layer.cornerRadius = 10
        
        
        editorOpen = false
        
        fillPicker()
        
        picker.reloadComponent(0)
        
        navigationController?.hidesBarsOnSwipe = true
        
        
        
        if self.revealViewController() != nil {
            print("not nil")
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            
            
        }
        
        homeScoreStepper.minimumValue = 0
        awayScoreStepper.minimumValue = 0
        homeScoreStepper.maximumValue = 200
        awayScoreStepper.maximumValue = 200
        
        
        
        getNewData()
        
        getChangedData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(FootballTableViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FootballTableViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    deinit {
        
        
        if let refHandle = _refHandle {
            
            
            self.ref.child("Sports").removeObserver(withHandle: refHandle)
            
            print("removed _refHandle")
            
        }
    }
    
    func fillPicker(){
        
        pickerComponents.append(["Title":"Home Team", "Value":"homeTeam"])
        pickerComponents.append(["Title":"Away Team", "Value":"awayTeam"])
        
        //pickerComponents.append(["Title":"Date", "Value":"date"])
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    
    
    
    func keyboardWillShow(_ notification: NSNotification){
        
        print("keyboard is here")
        
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        
        if editorOpen == false {
            
            self.editorView.transform = CGAffineTransform( translationX: 0.0, y: -keyboardHeight)
            
            editorOpen = true
            
        }
        
    }
    
    func keyboardWillHide(_ notification: NSNotification){
        
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        
        if editorOpen == true {
            
            self.editorView.transform = CGAffineTransform( translationX: 0.0, y: 0.0)
            
            editorOpen = false
        }
        
        
        print("keyboard gone")
    }

    
    func animateIn(){
        
        self.navigationController?.navigationBar.isHidden = true
        
        navigationController?.hidesBarsOnSwipe = false
        //blurView.
        
        
        editorView.frame = CGRect(x: self.view.bounds.width/2 , y: self.view.bounds.height/2+60, width: self.view.bounds.width-30, height: self.view.bounds.height-300)
        
        self.view.addSubview(editorView)
        editorView.center = CGPoint(x: self.view.center.x, y: self.view.center.y - 20)
            
            //self.view.center
        
        
        editorView.transform = CGAffineTransform.init(scaleX: 0.6, y:0.6)
        
       // NSLayoutConstraint(item: editorView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .topMargin, multiplier: 1.0, constant: 20.0).isActive = true
        
        //NSLayoutConstraint(item: editorView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottomMargin, multiplier: 1.0, constant: 20.0).isActive = true
        
        
        
        editorView.alpha = 0
        
        self.blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        self.blurEffectView = UIVisualEffectView(effect: self.blurEffect)
        self.blurEffectView.frame = self.view.bounds
        self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.insertSubview(self.blurEffectView, at: self.view.subviews.count - 2)
        
        self.tableView.isScrollEnabled = false

        self.blurEffectView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.4) {
            
            
            
            
            self.editorView.alpha = 1
            self.editorView.transform = CGAffineTransform.identity
            
            
        }
        
    }
    func animateOut(){
        
        self.blurEffectView.isUserInteractionEnabled = false
        
        self.navigationController?.navigationBar.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            
            self.editorView.transform = CGAffineTransform.init(scaleX: 1.3, y:1.3)
            
            self.editorView.alpha = 0
            
            self.blurEffectView.effect = nil
            
            
            
            self.tableView.isScrollEnabled = true
            
        }) { (success:Bool) in
            
            self.editorView.removeFromSuperview()
            self.blurEffectView.removeFromSuperview()

            self.editorView.transform = CGAffineTransform.init(scaleX: 1, y:1)
        
        }
        navigationController?.hidesBarsOnSwipe = true
    }
    
    
    
    func getNewData(){
        
        ref = FIRDatabase.database().reference()
        
        _refHandle = self.ref.child("Sports").child("Football").observe(FIRDataEventType.childAdded, with: { (snapshot) in
            
            self.spinner.startAnimating()
            
            print("there's another game")
            /*
            
            let homeName = snapshot.childSnapshot(forPath: "homeTeam").value as! String
            let awayName = snapshot.childSnapshot(forPath: "awayTeam").value as! String
            let homeScore = snapshot.childSnapshot(forPath: "homeScore").value as! String
            let awayScore = snapshot.childSnapshot(forPath: "awayScore").value as! String
            
            */
            
            //self.games.append([["homeTeam":homeName,"awayTeam":awayName,"homeScore":homeScore,"awayScore":awayScore]])
            
            
            //getting date of new snapshot we added, and adding a dictionary for the game into the array, in the correct place
            
            let gameIdentifier = snapshot.childSnapshot(forPath: "game").value as! String
            
            
            let dateInt = snapshot.childSnapshot(forPath: "date").value as! Int
            
            
            let year = 2000 + Int(dateInt/10000)
            
            let month = Int((dateInt/100)%100)
            
            let day = Int(dateInt%100)
            
            print("Game on \(month)/\(day)/\(year)")
            
            let gameDate = Date(year: year, month: month, day: day)
            
            
            
            var inserted = false
            
            
            if (self.games.count == 0){
                inserted = true
                self.games.append([self.gameForm(gameDate: gameDate, snapshot: snapshot)])
             
            } else {
                
                
                
                if gameDate > Date.today() {
                    
                    //section with latest dated games
                    var lastSec = self.games[self.games.count-1]
                    
                    let lastGameDate = lastSec[lastSec.count-1]["Date"] as! Date
                    
                    if lastGameDate >= Date.today(){
                        
                        var last = true
                        
                        for i in (0...lastSec.count-1){
                            
                            if lastSec[i]["Date"] as! Date > gameDate {
                                
                                if inserted == false {
                                    
                                    lastSec.insert(self.gameForm(gameDate: gameDate, snapshot: snapshot), at: i)
                                    inserted = true
                                    last = false
                                    print("inserting \(gameIdentifier) at point A")
                                    
                                }
                                
                                
                            }
                        }
                        
                        if inserted == false && last == true {
                            lastSec.append(self.gameForm(gameDate: gameDate, snapshot: snapshot))
                            inserted = true
                            print("inserting \(gameIdentifier) at point B")
                        }
                        
                    } else if lastGameDate < Date.today() {
                        
                        
                        if inserted == false {
                            
                            self.games.append([self.gameForm(gameDate: gameDate, snapshot: snapshot)])
                            inserted = true
                            print("inserting \(gameIdentifier) at point C")
                            
                        }
                    }
                } else if gameDate == Date.today() {
                    
                    
                    var lastSec = self.games[self.games.count-1]
                    
                    let lastGameDate = lastSec[lastSec.count-1]["Date"] as! Date
                    
                    if lastGameDate >= Date.today(){
                        
                        if inserted == false {
                            
                            lastSec.insert(self.gameForm(gameDate: gameDate, snapshot: snapshot), at: 0)
                            inserted = true
                            print("inserting \(gameIdentifier) at point D")
                        }
                        
                    }
                    
                    
                } else if gameDate < Date.today() {
                    
                    
                    for i in (0...self.games.count-1){
                        
                        let date = self.games[i][0]["Date"] as! Date
                        
                        if gameDate < date {
                            
                            if inserted == false {
                                
                                self.games.insert([self.gameForm(gameDate: gameDate, snapshot: snapshot)], at: i)
                                inserted = true
                                print("inserting \(gameIdentifier) at point E")

                            }
                            
                            
                        } else if gameDate == date {
                            if inserted == false{
                                
                                self.games[i].append(self.gameForm(gameDate: gameDate, snapshot: snapshot))
                                inserted = true
                                print("inserting \(gameIdentifier) at point F")
                                
                            }
                            
                            
                        }
                        
                        
                        
                    }
                    
                    
                }
                
                
               inserted = false
            }
            
            //print(self.games)
           
            self.tableView.reloadData()
            self.spinner.stopAnimating()
            
            //print("Home Team " + homeName + "\nAwayTeam " + awayName + "\nHome Score " + homeScore + "\nAway Score "
            //+ awayScore)
            
            
            
        })
        
    }
    
    func dateComparison(dat: Date, secDate: Date) -> String {
        
        
        print(dat.compare(Date.today()))
        
        
        return "sup"
        
    }
    
    func gameForm(gameDate: Date, snapshot: FIRDataSnapshot) -> Dictionary<String,Any>{
        
        return ["Date":gameDate, "Snapshot":snapshot]
    }
    
    func getChangedData(){
        
        
        ref = FIRDatabase.database().reference()
        
        _refHandle = self.ref.child("Sports").child("Football").observe(FIRDataEventType.childChanged, with: { (snapshot) in
            
            var section: Int!
            var row: Int!
            
            
            for i in 0...self.games.count-1 {
                
                for j in 0...self.games[i].count-1 {
                    
                    if (self.games[i][j]["Snapshot"] as! FIRDataSnapshot).childSnapshot(forPath: "game").value as! String == snapshot.childSnapshot(forPath: "game").value as! String {
                        
                        section = i
                        row = j
                        
                        
                        self.games[section][row]["snapshot"] = snapshot
                    }

                    
                }
                
                
            }
        
        
            let cell = self.tableView.cellForRow(at: IndexPath(row: row, section: section))
            
            let homeTeam = snapshot.childSnapshot(forPath: "homeTeam").value as! String
            
            let awayTeam = snapshot.childSnapshot(forPath: "awayTeam").value as! String
            
            let homeScore = snapshot.childSnapshot(forPath: "homeScore").value as! String
            
            let awayScore = snapshot.childSnapshot(forPath: "awayScore").value as! String
            
            
            (cell?.contentView.viewWithTag(3) as! UILabel).text = homeTeam
            
            (cell?.contentView.viewWithTag(4) as! UILabel).text = awayTeam
            
            (cell?.contentView.viewWithTag(1) as! UILabel).text = homeScore
            (cell?.contentView.viewWithTag(2) as! UILabel).text = awayScore
            
            
            
            
        })
        
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        //var sections = 0
        
        print("The amount of games: \(games.count)")
        //sections = games.count
        
            
        
        
        //return sections
        //return games.count
        
        return games.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        print("games in section: \(games[section].count)")
        
        return games[section].count
            
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let height:CGFloat = 61
        
        return height
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "scoreCell", for: indexPath)
        
        
        
        let section = indexPath.section
        let row = indexPath.row
        
        let snapshot = games[section][row]["Snapshot"] as! FIRDataSnapshot
        
        
        
        
        let homeTeam = snapshot.childSnapshot(forPath: "homeTeam").value as? String
        
        let awayTeam = snapshot.childSnapshot(forPath: "awayTeam").value as? String
        
        let homeScore = snapshot.childSnapshot(forPath: "homeScore").value as? String
        
        let awayScore = snapshot.childSnapshot(forPath: "awayScore").value as? String
        
        
        (cell.contentView.viewWithTag(3) as! UILabel).text = homeTeam
        
        (cell.contentView.viewWithTag(4) as! UILabel).text = awayTeam
        
        (cell.contentView.viewWithTag(1) as! UILabel).text = homeScore
        (cell.contentView.viewWithTag(2) as! UILabel).text = awayScore
        
        
        (cell.contentView.viewWithTag(7) as! UILabel).text = "Final"
        
        if (Int(homeScore!)! > Int(awayScore!)!){
            
            (cell.contentView.viewWithTag(5) as! UIImageView).image = UIImage(named: "triangleLeft")
            
            (cell.contentView.viewWithTag(4) as! UILabel).textColor = UIColor.lightGray
            
            (cell.contentView.viewWithTag(2) as! UILabel).textColor = UIColor.lightGray

            
        } else if (Int(awayScore!)! > Int(homeScore!)!){
            
            (cell.contentView.viewWithTag(6) as! UIImageView).image = UIImage(named: "triangleLeft")
            (cell.contentView.viewWithTag(3) as! UILabel).textColor = UIColor.lightGray
            
            (cell.contentView.viewWithTag(1) as! UILabel).textColor = UIColor.lightGray
        }
        
        
        print(homeTeam! + "\n" + awayTeam! + "\n")
        /*(cell.contentView.viewWithTag(3) as! UILabel).text = games?[section][row]["homeTeam"]
        
        (cell.contentView.viewWithTag(4) as! UILabel).text = games?[section][row]["awayTeam"]*/
        /*
        print(games?[section][row]["homeTeam"])
        print(games?[section][row]["awayTeam"])
        
        
        */

        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        //let dateHeader = tableView.dequeueReusableCell(withIdentifier: "header")! as UIView
        
        
       // let headerView = tableView.viewWithTag(2)
      /*
        headerView = dequeueReusableHeaderFooterView(withIdentifier: "Hi")
     */
        /*
        let view = UIView()
        view.backgroundColor = UIColor.lightText
        
        let label = UILabel()
        label.textAlignment = NSTextAlignment.center
        
        
        label.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0))
        
        label.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
            
        label.adjustsFontSizeToFitWidth = true
        
        let textSnap = games[section][0]["Date"] as! Date
        
        let text = textSnap.dateString(in: .medium)
        
        print("adding section \(section)")
        
        label.text = text
        
        view.addSubview(label)
        */
        
        
        
        //(dateHeader.viewWithTag(1) as! UILabel).text = "Friday mar \(section)"
        
        let headerView = self.headerView
        return headerView
    }
    
    
    /*
    func dequeueReusableHeaderFooterView(withIdentifier identifier: String) -> UITableViewHeaderFooterView? {
        
        let headerView = tableView.viewWithTag(2) as! UITableViewHeaderFooterView
        
        (headerView.viewWithTag(1) as! UILabel).text = "Thu mar 1"
        
        return headerView
    }*/
    
    @IBAction func tweetTapped(_ sender: UIBarButtonItem) {
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter) {
            
            let tweetComposer = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            tweetComposer?.setInitialText("@NBPSAthletics #NBPSportsApp")
            
            //tweetComposer.addImage(UIImage(named:""))
            
            self.present(tweetComposer!, animated: true, completion: nil)
        } else {
            
            let alertMessage = UIAlertController(title: "Twitter not available", message: "There is no twitter account set up on this phone", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertMessage, animated: true, completion: nil)
        }

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
      /*  ref.child("Football").child(games[indexPath.section][indexPath.row]["Snapshot"]).observe(.value, with: { (snapshot) in
            
            
        })*/
        
        selectedPath = [indexPath.section, indexPath.row]
        
        editorLabel.text = games[indexPath.section][indexPath.row]["Date"] as? String
        
        let snapshot = games[indexPath.section][indexPath.row]["Snapshot"] as? FIRDataSnapshot
        
        let game = snapshot?.childSnapshot(forPath: "game").value as? String
        
        currentGame = game
        
        homeScoreVal = Int((snapshot?.childSnapshot(forPath: "homeScore").value as? String)!)
        
        awayScoreVal = Int((snapshot?.childSnapshot(forPath: "awayScore").value as? String)!)

            
        let homeTeamStr = snapshot?.childSnapshot(forPath: "homeTeam").value as! String
        
        homeLabel.text = "Home"
            
        let awayTeamStr = snapshot?.childSnapshot(forPath: "awayTeam").value as! String
        
        awayLabel.text = "Away"
        
        let homeVal = snapshot?.childSnapshot(forPath: "homeScore").value as? String
        
        let awayVal = snapshot?.childSnapshot(forPath: "awayScore").value as? String
        
        homeScoreLabel.text = homeVal
        awayScoreLabel.text = awayVal
        
        

        homeScoreStepper.value = Double(Int(homeVal!)!)
        
        
        
        awayScoreStepper.value = Double(Int(awayVal!)!)
        
        editorLabel.text = "\(homeTeamStr) vs \(awayTeamStr)"
        if AppState.sharedInstance.signedIn {
            
            animateIn()

        } else {
            
            animateIn()
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
        
    }
    @IBAction func doneTapped(_ sender: Any) {
        
        animateOut()
        
    }
    
    @IBAction func changeTapped(_ sender: Any) {
        
        if editField.text != ""{
            
            let path = pickerComponents[pickerSelection]["Value"]
            
            
            ref = FIRDatabase.database().reference()
            let gameDirec = ref.child("Sports").child("Football").child(currentGame)
            gameDirec.child(path!).setValue(editField.text)
            
            gameDirec.child(path!).setValue(editField.text, withCompletionBlock: { (error, ref) in
                
                if error != nil {
                    
                    print(error?.localizedDescription ?? "Sorry, your connection didn't work")
                } else {
                    
                    print("success in posting")
                }
                
            })
            
            var homeTeam = ""
            var awayTeam = ""
            
            
            _refHandle = self.ref.child("Sports").child("Football").child(currentGame).observe(FIRDataEventType.value, with: { (snapshot) in
                
                let newVal = snapshot.childSnapshot(forPath: path!).value as! String
                
                print("Edited the value to \(newVal)")
                
                homeTeam = snapshot.childSnapshot(forPath: "homeTeam").value as! String
                awayTeam = snapshot.childSnapshot(forPath: "awayTeam").value as! String
                
                self.editorLabel.text = "\(homeTeam) vs \(awayTeam)"
                
                
                
                let homeScore = Double(snapshot.childSnapshot(forPath: "homeScore").value as! String)
                let awayScore = Double(snapshot.childSnapshot(forPath: "awayScore").value as! String)
                /*
                if self.homeScoreStepper.value != homeScore {
                    
                    let gameDirec = self.ref.child("Sports").child("Football").child(self.currentGame)
                    gameDirec.child("homeScore").setValue(String(self.homeScoreStepper.value))
                    
                    self.homeScoreVal = Int(self.homeScoreStepper.value)
                    

                    
                    
                }
                if self.awayScoreStepper.value != awayScore{
                    
                    let gameDirec = self.ref.child("Sports").child("Football").child(self.currentGame)
                    gameDirec.child("awayScore").setValue(String(self.awayScoreStepper.value))
                    
                    self.awayScoreVal = Int(self.awayScoreStepper.value)
                    
                    
                }
                */
                
            })
            
            
        
            editField.text = ""
            
            
        }
        if Double(homeScoreVal) != homeScoreStepper.value {
            
            ref = FIRDatabase.database().reference()
            let gameDirec = ref.child("Sports").child("Football").child(currentGame)
            gameDirec.child("homeScore").setValue(String(Int(homeScoreStepper.value)))
            
            homeScoreVal = Int(homeScoreStepper.value)
            homeScoreLabel.text = String(Int(homeScoreStepper.value))
            
        }
        if Double(awayScoreVal) != awayScoreStepper.value {
            
            ref = FIRDatabase.database().reference()
            let gameDirec = ref.child("Sports").child("Football").child(currentGame)
            gameDirec.child("awayScore").setValue(String(Int(awayScoreStepper.value)))
            
            awayScoreVal = Int(awayScoreStepper.value)
            
            awayScoreLabel.text = String(Int(awayScoreStepper.value))
        }
        
      /*  if (Date(year: year, month: month, day: day) != games[selectedPath[0]][selectedPath[1]]["Date"] as! Date) {
            
            print("new date")
            
        }
        */
        
        
        
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
        
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        
        return pickerComponents.count
    }
    
    // Delegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        var title = ""
        
        if pickerComponents.count != 0 {
            
            
                
            title = pickerComponents[row]["Title"]!
                
            
            
            
        }
        
        return title
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        pickerSelection = row
        
    }
    
    @IBAction func awayStepperChanged(_ sender: UIStepper) {
        awayScoreLabel.text = Int(sender.value).description
        
        
    }
    
    @IBAction func homeStepperChanged(_ sender: UIStepper) {
        homeScoreLabel.text = Int(sender.value).description
        
        
        
    }
    
    func greenText(label: UILabel){
        
        label.textColor = UIColor.green
        
        
    }
    /*open func headerView(forSection section: Int) -> UITableViewHeaderFooterView? {
        
        let header = tableView.dequeueReusableCell(withIdentifier: "header") as! UITableViewHeaderFooterView
        //let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
        
        (header.contentView.viewWithTag(1) as! UILabel).text = "Thu Mar 2"
        
        return header
    }*/
    
    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        
        print("hid nav bar")
    }

}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
