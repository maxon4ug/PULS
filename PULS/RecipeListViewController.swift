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

class RecipeListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var recipeListTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var errorLabel: UILabel!
    var searchActive = false
    let realm = try! Realm()
    lazy var localRecipes: Results<Recipe> = { self.realm.objects(Recipe.self) }()
    var searchedRecipes = Array<Recipe>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeListTableView.rowHeight = UITableViewAutomaticDimension
        recipeListTableView.estimatedRowHeight = 104
        recipeListTableView.tableFooterView = UIView(frame: CGRect.zero)
        errorLabel.font = UIFont(name: "Iowan Old Style", size: 17.0)
        //        recipeListTableView.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(self.hideSearchBarKeyboard(_:))))
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
            guard recipes.count != self.localRecipes.count else { return }
            for recipe in recipes {
                let newRecipe = Recipe()
                newRecipe.title = recipe["title"]!.trimmingCharacters(in: .whitespacesAndNewlines)
                newRecipe.ingredients = recipe["ingredients"]!
                newRecipe.href = recipe["href"]!
                Alamofire.request(recipe["thumbnail"]!).responseData { response in
                    newRecipe.thumbnailData = response.result.value ?? Data()
                    if self.realm.objects(Recipe.self).filter("href = '\(newRecipe.href)'").count == 0 {
                        try! self.realm.write {
                            self.realm.add(newRecipe)
                        }
                        self.localRecipes = self.realm.objects(Recipe.self)
                        self.recipeListTableView.reloadData()
                    }
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch searchActive {
        case true:
            if searchedRecipes.count == 0 {
                if isInternetAvailable() == false {
                    errorLabel.text = "Oops! Seems like there's no Internet connection :("
                } else {
                    errorLabel.text = "Oops! Seems like there's no recipes here :("
                }
                errorLabel.isHidden = false
            } else {
                errorLabel.isHidden = true
            }
            return searchedRecipes.count
        case false:
            if localRecipes.count == 0 {
                if isInternetAvailable() == false {
                    errorLabel.text = "Oops! Seems like there's no Internet connection and your local database is empty yet:("
                    errorLabel.isHidden = false
                }
            } else {
                errorLabel.isHidden = true
            }
            return localRecipes.count
        default: break
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recipeCell") as! RecipeTableViewCell
        let recipe: Recipe
        if searchActive == false {
            recipe = localRecipes[indexPath.row]
        } else {
            recipe = searchedRecipes[indexPath.row]
        }
        cell.titleLabel.text = recipe.title
        cell.ingredientsLabel.text = recipe.ingredients.capitalized
        if let image = UIImage(data: recipe.thumbnailData) {
            cell.thumbnailImageView.image = image
        } else {
            cell.thumbnailImageView.image = #imageLiteral(resourceName: "nophoto")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let urlString: String
        if searchActive == false {
            urlString = localRecipes[indexPath.row].href
        } else {
            urlString = searchedRecipes[indexPath.row].href
        }
        guard let url = URL(string: urlString), isInternetAvailable() == true else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        recipeListTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
        searchBar.text = ""
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        recipeListTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchActive = true
        self.recipeListTableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard isInternetAvailable() == true else {
            recipeListTableView.reloadData()
            return
        }
        Alamofire.request("http://www.recipepuppy.com/api/", parameters: ["q":searchText]).responseJSON(completionHandler: { response in
            self.searchedRecipes.removeAll()
            guard let json = response.result.value as? [String:Any], let recipes = json["results"] as? [[String:String]] else {
                print("Error: \(response.result.error?.localizedDescription ?? "Wrong casting")")
                return
            }
            guard recipes.count != 0 else {
                self.recipeListTableView.reloadData()
                return
            }
            for recipe in recipes {
                let newRecipe = Recipe()
                newRecipe.title = recipe["title"]!.trimmingCharacters(in: .whitespacesAndNewlines)
                newRecipe.ingredients = recipe["ingredients"]!
                newRecipe.href = recipe["href"]!
                Alamofire.request(recipe["thumbnail"]!).responseData { response in
                    newRecipe.thumbnailData = response.result.value ?? Data()
                    self.searchedRecipes.append(newRecipe)
                    self.recipeListTableView.reloadData()
                }
            }
        })
    }
    
    func hideSearchBarKeyboard(_ sender: Any?) {
        if searchActive == true {
            searchBar.resignFirstResponder()
        }
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

