//
//  ViewController.swift
//  CoreData_Fetch
//
//  Created by 蔡松樺 on 18/12/2017.
//  Copyright © 2017 蔡松樺. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {

    @IBOutlet weak var tableView: UITableView!
    var products : [ProductMO] = []
    var product : ProductMO!
    var fetchResultController: NSFetchedResultsController<ProductMO>!
    
    //UISearchController
    var searchController : UISearchController!
    var searchResults : [ProductMO] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //在同一視圖顯示給 nil
        searchController = UISearchController(searchResultsController: nil)
        tableView.tableHeaderView = searchController.searchBar
        
        searchController.searchResultsUpdater = self
        //搜尋時周遭要不要暗下來
        searchController.dimsBackgroundDuringPresentation = false
        
        self.fetchAPILoad()

    }
    @IBAction func addBtnPressed(_ sender: Any) {
        self.addContext()
    }
    
    //Create & Save to CoreData context
    func addContext(){
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            product = ProductMO(context: appDelegate.persistentContainer.viewContext)
            product.productName = "New Name"
            product.productPrice = 100
            
            print("Saving data to context...")
            appDelegate.saveContext()
        }
    }
    
    //Load by NSFetchResultController API
    func fetchAPILoad(){
        //從資料區讀取資料
        let fetchRequest : NSFetchRequest<ProductMO> = ProductMO.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "productName", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultController.delegate = self
        }
        
        do{
            try fetchResultController.performFetch()
            if let fetchedObjects = fetchResultController.fetchedObjects {
                products = fetchedObjects
            }
        }
        catch{
            print(error)
        }
    }
    
    //Load CoreData all context
    func fetchContext(){
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let request : NSFetchRequest<ProductMO> = ProductMO.fetchRequest()
            let context = appDelegate.persistentContainer.viewContext
            do{
                products = try context.fetch(request)
            }
            catch{
                print(error)
            }
        }
    }
}

//MARK: - UITableViewDataSource
extension ViewController {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if searchController.isActive {
            return searchResults.count
        }
        else{
            return products.count
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let product = searchController.isActive ? searchResults[indexPath.row] : products[indexPath.row]
        
        cell.textLabel?.text = product.productName
        cell.detailTextLabel?.text = String(product.productPrice)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Data delete")
            
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                let context = appDelegate.persistentContainer.viewContext
                let productToDelete = self.fetchResultController.object(at: indexPath)
                context.delete(productToDelete)
                
                appDelegate.saveContext()
            }
        }
    }
    
 
}

//MARK: - NSFetchResultControllerDelegate
extension ViewController {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .fade)
            }
        default:
            tableView.reloadData()
        }
        
        if let fetchedObjects = controller.fetchedObjects {
                products = fetchedObjects as! [ProductMO]
        }

    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
//MARK: - UISearchController
extension ViewController{
    //filter 用來過濾陣內中所擁有的字元
    func filterContent(for searchText: String){
        searchResults = products.filter({ (product) -> Bool in
            if let name = product.productName {
                let isMatch = name.localizedCaseInsensitiveContains(searchText)
                return isMatch
            }
            
            return false
        })
    }
    
    //UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContent(for: searchText)
            tableView.reloadData()
        }
    }
    
}

