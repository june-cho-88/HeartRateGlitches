import UIKit

class GlitchesTableViewController: UITableViewController {
    let healthKitManager = HealthKitManager.shared
    
    var glitchSamples: [HeartRate]? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.navigationItem.title = self.glitchSamples!.count.description + " Glitches"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
    }
    
    private func setNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "Loading Glitches ..."
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportGlitchHeartRate))
    }
    
    @objc private func exportGlitchHeartRate() {
        healthKitManager.findGlitches(level: .high) { [weak self] in
            guard let my = self else { fatalError() }
            my.healthKitManager.exportData($0, fileName: "HeartRateGlitches", as: .csv, completion: {
                let exportViewController = UIActivityViewController(activityItems: [$0], applicationActivities: nil)
                my.present(exportViewController, animated: true, completion: nil)
            })
        }
    }
    
    let cellIdentifier = "GlitchCell"
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Hello"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return glitchSamples?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let glitchCell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        
        if let samples = glitchSamples {
            let heartRate = samples[indexPath.row].heartRate
            let startDate = samples[indexPath.row].startDate
            let endDate = samples[indexPath.row].endDate
            
            glitchCell.textLabel?.text = heartRate.description
            glitchCell.detailTextLabel?.text = (startDate == endDate) ? endDate.description : (startDate.description + " ~ " + endDate.description)
        }
        
        return glitchCell
    }
}
