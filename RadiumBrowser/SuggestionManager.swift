//
//  SuggestionManager.swift
//  RadiumBrowser
//
//  Created by Bradley Slayter on 11/1/17.
//  Copyright © 2017 bslayter. All rights reserved.
//

import Foundation
import RealmSwift

struct URLEntry: Hashable {
    var hashValue: Int {
        return urlString.hashValue
    }
    
    static func ==(lhs: URLEntry, rhs: URLEntry) -> Bool {
        return lhs.urlString == rhs.urlString
    }
    
    var urlString: String
}

class SuggestionManager {
    static let shared = SuggestionManager()
    
    lazy var domainSet = Set<URLEntry>()
    
    var topdomains: [URLEntry]?
    var historyResults: Results<HistoryEntry>?
    
    @objc var notificationToken: NotificationToken!
    var realm: Realm!
    
    init() {
        guard let path = Bundle.main.path(forResource: "topdomains", ofType: "txt") else {
            return
        }
        
        do {
            self.realm = try Realm()
            self.historyResults = realm.objects(HistoryEntry.self)
            self.notificationToken = historyResults?.addNotificationBlock { [weak self] _ in
                self?.reupdateList()
            }
        } catch let error as NSError {
            print("Error occured opening realm: \(error.localizedDescription)")
        }
        
        do {
            let domainConent = try String(contentsOfFile: path, encoding: .utf8)
            let domainList = domainConent.components(separatedBy: "\n")
            
           topdomains = domainList.map { URLEntry(urlString: $0) }
            
            topdomains?.forEach {
                domainSet.insert($0)
            }
        } catch {
            return
        }
        
    }
    
    func reupdateList() {
        domainSet.removeAll()
        
        topdomains?.forEach { domainSet.insert($0) }
        historyResults?.forEach { domainSet.insert(URLEntry(urlString: $0.pageURL)) }
    }
    
    func queryDomains(forText text: String) -> [URLEntry] {
        var queryText = text.replacingOccurrences(of: "http://", with: "")
        queryText = text.replacingOccurrences(of: "https://", with: "")
        
        let results: [URLEntry] = domainSet.filter { $0.urlString.contains(queryText) }
        
        return results
    }
}
