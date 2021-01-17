import UIKit

class HeartRateTableViewController: UITableViewController {
    let healthKitManager = HealthKitManager.shared
    
    var heartRateData: [HeartRate]? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        healthKitManager.authorizeHeartRateData { (success, error) in
            guard success else { print("HealthKit: Authorization failed."); return }
        }
        refreshHeartRateData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setRefreshControl()
        setNavigationBar()
        findGlitchHeartRate()
    }
    
    private func refreshHeartRateData() {
        healthKitManager.getHeartRateData() { [weak self] in
            self?.heartRateData = $0
        }
    }
    
    private func setRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
    }
    
    @objc private func refreshTable() {
        refreshHeartRateData()
        refreshControl?.endRefreshing()
    }
    
    private func setNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "HeartRate"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(findGlitchHeartRate))
    }
    
    @objc private func findGlitchHeartRate() {
        let glitchesTableViewController = GlitchesTableViewController()
        healthKitManager.findGlitches(level: .high) {
            glitchesTableViewController.glitchSamples = $0
        }
        navigationController?.pushViewController(glitchesTableViewController, animated: true)
    }
    
    let cellIdentifier = "DataCell"
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (heartRateData?.count.description ?? "0") + " Samples"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return heartRateData?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataCell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        
        if let samples = heartRateData {
            let heartRate = samples[indexPath.row].heartRate
            let startDate = samples[indexPath.row].startDate
            let endDate = samples[indexPath.row].endDate
            
            dataCell.textLabel?.text = heartRate.description
            dataCell.detailTextLabel?.text = (startDate == endDate) ? endDate.description : (startDate.description + " ~ " + endDate.description)
        }
        
        return dataCell
    }
}
