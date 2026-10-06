//
//  MainViewController.swift
//  FishCa
//
//  Created by Kirill Sysoev on 05.10.2026.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet weak var addParticipantButton: UIButton!
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var sorted: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        downloadParticipants()
        self.title = "Участники (\(participants.count))"
        sorted = downloadState()
        filterButton.setTitle(sorted ? "Кг" : "№", for: .normal)
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let headerNib = UINib(nibName: "TitleHeaderView", bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "TitleHeaderView")
        
        addParticipantButton.addTarget(self, action: #selector(addParticipantButtonTapped), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
    }
    
    @objc func addParticipantButtonTapped() {
        showAddParticipantAlert()
    }
    
    @objc func filterButtonTapped() {
        sorted = !sorted
        filterButton.setTitle(sorted ? "Кг" : "№", for: .normal)
        saveState(state: sorted)
        
        sortAndSave()
    }
    
    func sortAndSave() {
        if sorted {
            participants.sort(by: { $0.kilos > $1.kilos })
        } else {
            participants.sort(by: { $0.id < $1.id })
        }
        saveParticipants()
        tableView.reloadData()
    }
    
    func updateUIAfterScoreChange(at row: Int) {
        if sorted {
            sortAndSave()
        } else {
            saveParticipants()
            if participants.indices.contains(row) {
                let indexPath = IndexPath(row: row, section: 0)
                tableView.reloadRows(at: [indexPath], with: .automatic)
            } else {
                tableView.reloadData()
            }
        }
    }
    
    func showAddScoreAlert(_ participantID: Int) {
        let alert = UIAlertController(title: "Сколько словил?", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Введите килограммы"
            textField.keyboardType = .decimalPad
            textField.delegate = self
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Готово", style: .plain, target: self, action: #selector(self.textFieldDoneButtonTapped))
            toolbar.items = [doneButton]
            textField.inputAccessoryView = toolbar
        }

        let okAction = UIAlertAction(title: "Oк", style: .default) { [weak self] _ in
            guard let self = self,
                  let rawText = alert.textFields?.first?.text,
                  !rawText.isEmpty else { return }
            
            let value = Double(rawText.replacingOccurrences(of: ",", with: ".")) ?? 0

            var participant = participants[participantID]
            participant.scores.append(value)
            participant.kilos = participant.scores.countKilos()
            participants[participantID] = participant
            
            self.updateUIAfterScoreChange(at: participantID)
        }
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func showMinusScoreAlert(_ participantID: Int) {
        let alert = UIAlertController(title: "Сколько отнять?", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Введите килограммы"
            textField.keyboardType = .decimalPad
            textField.delegate = self
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Готово", style: .plain, target: self, action: #selector(self.textFieldDoneButtonTapped))
            toolbar.items = [doneButton]
            textField.inputAccessoryView = toolbar
        }

        let okAction = UIAlertAction(title: "Oк", style: .default) { [weak self] _ in
            guard let self = self,
                  let rawText = alert.textFields?.first?.text,
                  !rawText.isEmpty else { return }
            
            let value = Double(rawText.replacingOccurrences(of: ",", with: ".")) ?? 0

            var participant = participants[participantID]
            participant.scores.append(-value)
            participant.kilos = participant.scores.countKilos()
            participants[participantID] = participant
            
            self.updateUIAfterScoreChange(at: participantID)
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        
        let deleteLastAction = UIAlertAction(title: "- последний", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            var participant = participants[participantID]
            participant.scores = participant.scores.dropLast()
            participant.kilos = participant.scores.countKilos()
            participants[participantID] = participant
            
            self.updateUIAfterScoreChange(at: participantID)
        }
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        alert.addAction(deleteLastAction)
        present(alert, animated: true)
    }
    
    func showAddParticipantAlert() {
        let alert = UIAlertController(title: "Сколько участников добавить?", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Введите количество"
            textField.keyboardType = .numberPad
            textField.delegate = self
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let doneButton = UIBarButtonItem(title: "Готово", style: .plain, target: self, action: #selector(self.textFieldDoneButtonTapped))
            toolbar.items = [doneButton]
            textField.inputAccessoryView = toolbar
        }

        let okAction = UIAlertAction(title: "Oк", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let value = Int(alert.textFields?.first?.text ?? "") ?? 0
            for _ in 0..<value {
                addParticipant()
            }
            self.sortAndSave()
            self.title = "Участники (\(participants.count))"
        }
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func convertScore(_ scores: [Double]) -> String {
        var result: String = ""
        for index in 0..<scores.count {
            let score = scores[index]
            if index != 0 {
                if score < 0 {
                    result.append(" - ")
                    result.append(String(format: "%.2f", abs(score)))
                } else {
                    result.append(" + ")
                    result.append(String(format: "%.2f", score))
                }
            } else {
                result.append(String(format: "%.2f", score))
            }
        }
        result.append(" = \(String(format: "%.2f", scores.countKilos()))")
        
        return result
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showAddScoreAlert(indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { _, _, completion in
            participants.remove(at: indexPath.row)
            self.sorted ? self.sortAndSave() : tableView.deleteRows(at: [indexPath], with: .fade)
            self.title = "Участники (\(participants.count))"
            saveParticipants()
            completion(true)
        }
        let editAction = UIContextualAction(style: .normal, title: "Изменить") { _, _, completion in
            self.showMinusScoreAlert(indexPath.row)
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        deleteAction.image = UIImage(systemName: "trash.fill")
        editAction.backgroundColor = .systemPurple
        editAction.image = UIImage(systemName: "pencil.circle.fill")
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return participants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell", for: indexPath) as! TableViewCell
        let participant = participants[indexPath.row]
        
        if sorted {
            let rank = participants.filter { $0.kilos > participant.kilos }.count + 1
            
            switch rank {
            case 1:
                cell.backgroundColor = UIColor(red: 0.90, green: 0.69, blue: 0.22, alpha: 1.0)
            case 2:
                cell.backgroundColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0)
            case 3:
                cell.backgroundColor = UIColor(red: 0.80, green: 0.50, blue: 0.20, alpha: 1.0)
            default:
                cell.backgroundColor = .white
            }
            
            cell.numberLabel.text = "\(rank)"
        } else {
            cell.backgroundColor = .white
            cell.numberLabel.text = "\(indexPath.row + 1)"
        }
        
        cell.nameLabel.text = "\(participant.id)"
        cell.scoreLabel.text = convertScore(participant.scores)
        cell.clipsToBounds = true
        cell.layer.cornerRadius = 15
        
        return cell
    }
}

extension MainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let alert = self.presentedViewController as? UIAlertController {
            alert.dismiss(animated: true)
        }
        return true
    }
    
    @objc func textFieldDoneButtonTapped() {
        if let alert = self.presentedViewController as? UIAlertController,
           let textField = alert.textFields?.first {
            textField.resignFirstResponder()
        }
    }
}
