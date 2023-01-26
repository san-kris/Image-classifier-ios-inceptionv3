//
//  ViewController.swift
//  SeaFood
//
//  Created by Santosh Krishnamurthy on 1/26/23.
//

import UIKit
import CoreML
import Vision
import PhotosUI

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate{
    
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        // We have to use PHPicker framework to pick images from library
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
        } else{
            print("camera not available on this device")
            pickImageFromPhotoLibrary()
        }
        
        
        imagePicker.allowsEditing = false
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // in the info dict, we can find original image and edited image and info on all the edits performed
        // use KEY UIImagePickerController.InfoKey.originalImage to get original image
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            
            imageView.image = userPickedImage
        }
        
        imagePicker.dismiss(animated: true)
        
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func pickImageFromPhotoLibrary() -> Void {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = PHPickerFilter.images
        
        let pickerViewController = PHPickerViewController(configuration: config)
        pickerViewController.delegate = self
        self.present(pickerViewController, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
                 if let image = object as? UIImage {
                    DispatchQueue.main.async {
                       // Use UIImage
                        self.imageView.image = image
                       print("Selected image: \(image)")
                        self.detect(image: image)
                    }
                 }
            })
        }
        picker.dismiss(animated: true)
    }
    
    func detect(image: UIImage) -> Void {
        // Create a CIImage object from the user selected image
        guard let ciImage = CIImage(image: image) else{
            print("unable to creaate CI Image")
            return
        }
        // create an instance of Inceptionv3 ML Model
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else{
            print("unable to load Inceptionv3 moodel in ML Container")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let result = request.results as? [VNClassificationObservation] else{
                print("Model failed to process image")
                return
            }
            // print(result)
            if let firstResult = result.first{
                self.navigationItem.title = firstResult.identifier
                print(firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        do{
            try handler.perform([request])
        } catch {
            print("Error performing ML \(error)")
        }
        
    }
    
}

