//
//  ViewController.swift
//  PULS
//
//  Created by Max Surgai on 29.07.17.
//  Copyright © 2017 Max Surgai. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import SystemConfiguration

class RecipeListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var recipeListTableView: UITableView!
    let realm = try! Realm()
    lazy var recipes: Results<Recipe> = { self.realm.objects(Recipe.self) }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeListTableView.rowHeight = UITableViewAutomaticDimension
        recipeListTableView.estimatedRowHeight = 100
        recipeListTableView.tableFooterView = UIView(frame: CGRect.zero)
        fetchData()
    }
    
    func fetchData() {
        guard isInternetAvailable() == true else { return }
        let urlString = "http://www.recipepuppy.com/api/?i=onions,garlic&q=omelet&p=3"
        Alamofire.request(urlString).responseJSON(completionHandler: { response in
            guard let json = response.result.value as? [String:Any], let recipes = json["results"] as? [[String:String]] else {
                print("Error: \(response.result.error?.localizedDescription ?? "Wrong casting")")
                return
            }
            guard recipes.count != self.recipes.count else { return }
            for recipe in recipes {
                let newRecipe = Recipe()
                newRecipe.title = recipe["title"]!.trimmingCharacters(in: .whitespacesAndNewlines)
                newRecipe.ingredients = recipe["ingredients"]!
                newRecipe.href = recipe["href"]!
                newRecipe.thumbnail = recipe["thumbnail"] ?? ""
                if self.realm.objects(Recipe.self).filter("href = '\(newRecipe.href)'").count == 0 {
                    try! self.realm.write {
                        self.realm.add(newRecipe)
                    }
                }
            }
        })
        recipes = realm.objects(Recipe.self)
        recipeListTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recipeCell") as! RecipeTableViewCell
        let recipe = recipes[indexPath.row]
        cell.titleLabel.text = recipe.title
        cell.ingredientsLabel.text = recipe.ingredients
        Alamofire.request(recipe.thumbnail).responseData { response in
            guard let data = response.result.value, let image = UIImage(data: data) else {
                cell.thumbnailImageView.image = #imageLiteral(resourceName: "nophoto")
                return
            }
            cell.thumbnailImageView.image = image
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let urlString = recipes[indexPath.row].href
        guard let url = URL(string: urlString), isInternetAvailable() == true else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
}

