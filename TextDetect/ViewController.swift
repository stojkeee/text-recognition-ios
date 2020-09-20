//
//  ViewController.swift
//
//  Created by Mate Stojić on 20/09/20.
//  Copyright © 2020 Assignment. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var detectedText: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    lazy var vision = Vision.vision()
    var textDetector: VisionTextDetector?
}

// MARK: - BorderRadius opcije

extension UIView {
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
}

// MARK: - Učitavanje slike

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        dismiss(animated: true, completion: nil)
        
        guard let image = info[convertFromUIImagePickerControllerInfoKey(.originalImage)] as? UIImage else {
            showOkAlert(title: "Greška", message: "Nije moguće učitati sliku.")
            return
        }
        
        imageView.image = image
        detectText(image: image)
    }
}

// MARK: - Kamera i galerija

extension ViewController {
    
    @IBAction func cameraButtonTapped(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera)  else {
            showOkAlert(title: "Nema kamere", message: "Ovaj uređaj nema podržanu kameru.")
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func photosButtonTapped(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary)  else {
            showOkAlert(title:  "Nema fotografija", message: "Ovaj uređaj nema podržane fotografije.")
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
}

// MARK: - Metode

extension ViewController {
    func detectText (image: UIImage) {
        textDetector = vision.textDetector()
        let rotatedImage = image.fixImageOrientation()
        let visionImage = VisionImage(image: rotatedImage)
        textDetector?.detect(in: visionImage) { [weak self] (features, error) in
            // Self checker
            guard let self = self else { return }
            
            // Error handling
            if let error = error {
                self.showOkAlert(title: "Greška", message: error.localizedDescription)
                return
            }
            
            // Features checking
            guard let features = features, !features.isEmpty else {
                self.showOkAlert(title: "Greška", message: "Tekst nije pronadjen. Molimo pokušajte ponovno.")
                return
            }
            
            // Text exporting
            var text = ""
            for feature in features {
                let value = feature.text
                text.append("\n\(value)\n")
            }
            
            // Present final result
            self.showCopyAlert(title: "Skenirani tekst:", message: text, copyText: text)
        }
    }
}

fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
    Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
    input.rawValue
}

// MARK: - Extensions

extension UIImage {
    func fixImageOrientation() -> UIImage {
        UIGraphicsBeginImageContext(self.size)
        self.draw(at: .zero)
        let fixedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return fixedImage ?? self
    }
}

extension UIViewController {
    func showOkAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "U redu", style: .cancel, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    func showCopyAlert(title: String, message: String, copyText: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Kopiraj tekst", style: .default, handler: { action in
            UIPasteboard.general.string = copyText
        })
        alert.addAction(ok)
        let cancel = UIAlertAction (title: "Odustani", style: .destructive, handler: nil)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
}
