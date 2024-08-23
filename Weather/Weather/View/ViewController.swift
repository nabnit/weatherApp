//
//  ViewController.swift
//  Weather
//
//  Created by Nabnit Patnaik on 8/20/24.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, WeatherDetailsProtocol {
    var weatherViewModel = WeatherViewModel()
    lazy var searchBar = UISearchBar()
    var locationManager: CLLocationManager?
    var activityIndicator = UIActivityIndicatorView()
    
    // CAN BE DONE: Duplicate codes can be avoided by creating common method to create labels
    var lblCity: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: WeatherConstants.MediumFontSize, weight: .bold)
        lbl.isHidden = true
        return lbl
    }()
    var lblMinTemp: UILabel = {
        let lbl = UILabel()
        lbl.isHidden = true
        lbl.font = .systemFont(ofSize: WeatherConstants.fontSize)
        
        return lbl
    }()
    var lblMaxTemp: UILabel = {
        let lbl = UILabel()
        lbl.isHidden = true
        lbl.font = .systemFont(ofSize: WeatherConstants.fontSize)
        
        return lbl
    }()
    var lblTemp: UILabel = {
        let lbl = UILabel()
        lbl.isHidden = true
        lbl.font = .systemFont(ofSize: WeatherConstants.largeFontSize)
        
        return lbl
    }()
    
    var lblDescription: UILabel = {
        let lbl = UILabel()
        lbl.isHidden = true
        lbl.font = .systemFont(ofSize: WeatherConstants.fontSize)
        
        return lbl
    }()
    var lblFeelsLike: UILabel = {
        let lbl = UILabel()
        lbl.isHidden = true
        lbl.font = .systemFont(ofSize: WeatherConstants.fontSize)
        
        return lbl
    }()
    
    var weatherIcon: UIImageView = {
        let img = UIImageView()
        img.isHidden = true
        return img
    }()
    var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = WeatherConstants.spacing
        stack.isHidden = true
        return stack
    }()
    var searchStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = WeatherConstants.spacing
        return stack
    }()
    var searchBtn: UIButton = {
        let btn = UIButton()
        return btn
    }()
    
    // MARK: View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupStyle()
        setupLocation()
        weatherViewModel.vmDelegate = self
        setupLoadingIndicator()
        
        // Adding this gesture to dismiss keyboard on tap of the screen
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    // MARK: Setup methods
    func setupUI() {
        view.addSubview(searchStackView)
        view.addSubview(stackView)
        searchStackView.addArrangedSubview(searchBar)
        searchStackView.addArrangedSubview(searchBtn)
        stackView.addArrangedSubview(weatherIcon)
        stackView.addArrangedSubview(lblCity)
        stackView.addArrangedSubview(lblTemp)
        stackView.addArrangedSubview(lblDescription)
        stackView.addArrangedSubview(lblMinTemp)
        stackView.addArrangedSubview(lblMaxTemp)
        stackView.addArrangedSubview(lblFeelsLike)
        
        // We can add a scroll view inside the stackview as well, so that the content scrolls if it exceeds the screen space
    }
    
    func setupStyle() {
        searchBar.searchBarStyle = UISearchBar.Style.default
        searchBar.placeholder = WeatherConstants.searchPlaceHolderText
        searchBar.sizeToFit()
        searchBar.isTranslucent = true
        searchBar.delegate = self
        
        searchBtn.setTitle(WeatherConstants.searchButtonTitle, for: .normal)
        searchBtn.addTarget(self, action: #selector(onClickSearch), for: .touchUpInside)
        searchBtn.translatesAutoresizingMaskIntoConstraints = false
        searchBtn.setTitleColor(.black, for: .normal)
        
        stackView.backgroundColor = .cyan
    }
    
    func setupConstraints() {
        searchStackView.translatesAutoresizingMaskIntoConstraints = false
        searchStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        searchStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: WeatherConstants.spacing).isActive = true
        searchStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -WeatherConstants.spacing).isActive = true
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: searchStackView.bottomAnchor, constant: WeatherConstants.spacing).isActive = true
        stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: WeatherConstants.spacing).isActive = true
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: WeatherConstants.spacing, right: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        weatherIcon.contentMode = .scaleAspectFit
        
        stackView.setCustomSpacing(50.0, after: lblDescription)
    }
    
    // Show/Hide loading indicator
    func setupLoadingIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.center = view.center
        activityIndicator.style = .large
        activityIndicator.hidesWhenStopped = true
        
        activityIndicator.startAnimating()
    }
    
    // MARK: Location permission setup
    func setupLocation() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        // Check for the location permission status
        switch locationManager?.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
        default:
            // if rejected, show an alert to enable location
            DispatchQueue.main.async { [weak self] in
                self?.stackView.isHidden = true
                self?.showAlert(msg: "Location needs to be enabled to view weather details")
            }
        }
    }
    
    // MARK: UI update methods
    func updateUI(_ model: WeatherModelProtocol) {
        fetchImage(imgName: model.getIconImageName() ?? "")
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.activityIndicator.stopAnimating()
            
            strongSelf.stackView.isHidden = false
            strongSelf.lblCity.isHidden = false
            
            strongSelf.lblCity.text = model.getCityName()
            let temp = model.getTemp()
            if let curr = temp.current {
                strongSelf.lblTemp.text = String(format: "%.2f °F", curr)
                strongSelf.lblTemp.isHidden = false
            }
            if let min = temp.min {
                strongSelf.lblMinTemp.text = String(format: "Low: %.2f °F", min)
                strongSelf.lblMinTemp.isHidden = false
            }
            if let max = temp.max {
                strongSelf.lblMaxTemp.text = String(format: "High: %.2f °F", max)
                strongSelf.lblMaxTemp.isHidden = false
            }
            if let feelslike = temp.feelsLike {
                strongSelf.lblFeelsLike.text = String(format: "Feels like: %.2f °F", feelslike)
                strongSelf.lblFeelsLike.isHidden = false
            }
            if let desc = model.getDescription() {
                strongSelf.lblDescription.text = desc.capitalized
                strongSelf.lblDescription.isHidden = false
            }
        }
    }
    
    // Update icon image
    func updateIconImage(_ image: UIImage?) {
        if let image = image {
            DispatchQueue.main.async {[weak self] in
                guard let strongSelf = self else {return}
                strongSelf.weatherIcon.image = image
                strongSelf.weatherIcon.isHidden = false
            }
        }
    }
    
    // MARK: API service calls to fetch data and image
    func fetchData(_ city: String) {
        let cityName = validateCityName(city: city)
        guard !cityName.isEmpty else {
            activityIndicator.stopAnimating()
            return
        }
        weatherViewModel.fetchWeatherData(city: cityName)
    }
    
    func fetchImage(imgName: String) {
        weatherViewModel.fetchImage(name: imgName)
    }
    
    // MARK: Search button action
    @objc func onClickSearch() {
        if searchBar.text?.isEmpty == true {
            showAlert(msg: WeatherConstants.message_emptyCity)
        } else {
            fetchData(searchBar.text ?? "")
        }
        searchBar.resignFirstResponder()
    }
    
    // MARK: WeatherDetailProtocol methods
    func weatherDetailsFetchSuccess(model: WeatherModelProtocol) {
        updateUI(model)
    }
    func weatherIconDownloadSuccess(image: UIImage) {
        updateIconImage(image)
    }
    /// On Api failure
    func onFailure(error: WeatherError?) {
        showError(error: error)
    }
    
}

extension ViewController {
    func showAlert(msg: String) {
        let alert = UIAlertController(title: WeatherConstants.alert_title, message: msg, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showError(error: WeatherError?) {
        guard let error = error else {
            return
        }
        DispatchQueue.main.async {[weak self] in
            guard let strongSelf = self else { return }
            switch error {
            case .invalidCity:
                strongSelf.showAlert(msg: WeatherConstants.message_invalidCity)
            case .networkError:
                strongSelf.showAlert(msg: WeatherConstants.message_networkError)
            case .others:
                strongSelf.showAlert(msg: WeatherConstants.message_otherError)
            }
        }
    }
    
    func validateCityName(city: String?) -> String {
        guard let city = city else {
            return ""
        }
        // Checks for leading and trailing whitespaces
        let cityName = city.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        do {
            // only allow one space after comma to accept - city, state
            let regex = try NSRegularExpression(pattern: ".*[^A-Za-z0-9, ].*", options: [])
            if regex.firstMatch(in: cityName, options: [], range: NSMakeRange(0, cityName.count)) != nil {
                self.showAlert(msg: WeatherConstants.message_invalidCity)
            }
        }
        catch {
            self.showAlert(msg: WeatherConstants.message_invalidCity)
        }
        
        searchBar.text = ""
        return cityName.replacingOccurrences(of: " ", with: "")
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}
// MARK: Search bar delegate
extension ViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String)
    {
        // CAN BE DONE: Can be used for predictive search when we have a list of items that we can fed to the search bar and start typing characters to intiate the search from the list
    }
}

// MARK: Location manager delegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // if authorized, fetch the weather details of the previously searched city
            fetchData(LocalStorage.shared.fetchCity())
        }
    }
}
