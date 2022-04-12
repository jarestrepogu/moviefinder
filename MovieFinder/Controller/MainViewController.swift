//
//  MainViewController.swift
//  MovieFinder
//
//  Created by Lina on 31/03/22.
//

import UIKit
import Kingfisher

class MainViewController: UITableViewController {
    
    @IBOutlet weak var backbutton: UIBarButtonItem!
    @IBOutlet weak var searchMovieBar: UISearchBar!
    
    private let facade = FacadeMovieFinder()
    
    private var trendingMovies = [Movie]()
    private var foundMovies = [Movie]()
    private var cachedMovies = [Movie]()
    private var isTrending = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showSpinner()
        
        isTrending = true
        
        title = "Trending movies"
        
        tableView.dataSource = self
        tableView.register(UINib.init(nibName: "MovieCell", bundle: nil), forCellReuseIdentifier: "ReusableCell")
        tableView.rowHeight = 175
        
        facade.fetchMovies(isTrending: isTrending, movieTitle: nil, completionHandler: { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let resultMovies):
                    self.trendingMovies = resultMovies
                    self.tableView.reloadData()
                    self.removeSpinner()
                    
                case .failure(let error):
                    print(error)
                }
            }
        })
    }
    
    //MARK: - Back to Trending Button
    
    func showBackButton (){
        if navigationItem.leftBarButtonItem == nil {
            self.navigationItem.leftBarButtonItem = createBackButton()
        } else {
            self.navigationItem.setLeftBarButton(nil, animated:     true)
        }
    }
    
    @objc func trendingButtonPressed(_ sender: UIButton) {
        isTrending = true
        trendingMovies = cachedMovies
        showBackButton()
        title = "Trending movies"
        tableView.reloadData()
        
    }
    
    func createBackButton() -> UIBarButtonItem {
        let leftButton = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.left"), style: .plain, target: self, action: #selector(trendingButtonPressed(_ :)))
        leftButton.tintColor = UIColor.white
        return leftButton
    }
    
    //MARK: - Search Button Pressed
    @IBAction func searchButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Search for a movie", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Search", style: .default) { (action) in
            
            if textField.text != "" {
                if let movie = textField.text {
                    self.cachedMovies = self.trendingMovies
                    self.isTrending = false
                    self.showSpinner()
                    self.facade.fetchMovies(isTrending: self.isTrending, movieTitle: movie, completionHandler: { [weak self] result in
                        
                        DispatchQueue.main.async {
                            guard let self = self else { return }
                            switch result {
                            case .success(let resultMovies):
                                self.foundMovies = resultMovies
                                self.tableView.reloadData()
                                self.removeSpinner()
                                
                            case .failure(let error):
                                print(error)
                            }
                        }
                    })
                    self.title = movie
                    self.showBackButton()
                }
            } else {
                print("Nothing added")
            }
        }
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Search for a movie"
            textField = alertTextField
        }
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)        
    }
    
    // MARK: - TableView Data Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isTrending {
            return trendingMovies.count
        } else {
            return foundMovies.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var movie: Movie
        
        if isTrending {
            movie = trendingMovies[indexPath.row]
        } else {
            movie = foundMovies[indexPath.row]
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReusableCell", for: indexPath) as! MovieCell
        cell.movieTitle.text = movie.title
        cell.movieOverview.text = movie.overview
        cell.movieVotes.text = String(movie.voteAverage)
        if let poster = movie.posterPath {
            let posterURL = URL(string: "https://image.tmdb.org/t/p/w500\(poster)")
            cell.posterImage.kf.setImage(with: posterURL)
        }
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToDetails", sender: self)
    }
    
    //MARK: - Prepare for segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! DetailsViewController
        destinationVC.loadViewIfNeeded()
        
        var movie: [Movie]
        
        if isTrending {
            movie = trendingMovies
        } else {
            movie = foundMovies
        }
        
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.movieTitle.text = movie[indexPath.row].title
            destinationVC.movieVotes.text = String(movie[indexPath.row].voteAverage)
            destinationVC.movieOverview.text = movie[indexPath.row].overview
            destinationVC.setMovieId(id: movie[indexPath.row].id)
            
            if let poster = movie[indexPath.row].posterPath {
                let posterURL = URL(string: "https://image.tmdb.org/t/p/w500\(poster)")
                destinationVC.posterImage.kf.setImage(with: posterURL)
            }
        }
    }
}

