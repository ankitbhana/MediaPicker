//
//  MediaPicker.swift
//  MediaPicker
//
//  Created by Ankit Bhana on 09/06/20.
//  Copyright © 2020 Ankit Bhana. All rights reserved.
//

import UIKit

class MediaPicker: NSObject {
    
    // MARK: - Instance properties
    
    var completionMediaSelection: ((Media) -> Void)?
    
    // MARK: - Private Instance properties
    
    private static var imagePicker: MediaPicker?
    private var presentationContext: UIViewController?
    
    /// Generates a random string using UUID
    private var randomNameForImage: String {
        UUID().uuidString
    }
    
    // MARK: - Type methods
    
    static func present(
        on viewController: UIViewController,
        for sources: [Source],
        completion: @escaping ((Media) -> Void)) {
        
        for source in sources {
            
            switch source {
            case .camera:
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    print("MediaPicker Error: Camera is not available")
                    return
                }
            case .gallary:
                guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                    print("MediaPicker Error: Gallery is not available")
                    return
                }
            default:
                break
            }
        }
        
        imagePicker = MediaPicker()
        imagePicker!.completionMediaSelection = completion
        imagePicker!.presentationContext = viewController
        imagePicker!.configureAndPresentActionSheet(for: sources)
    }
    
    // MARK: - Private helper methods
    
    private func configureAndPresentActionSheet(for sources: [Source]) {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        var actions = [UIAlertAction]()
        
        if sources.contains(.gallary) {
            let galleryAction = UIAlertAction(title: "Choose Photo", style: .default) { _ in
                self.openImagePickerController(for: .photoLibrary)
            }
            actions.append(galleryAction)
        }
        
        if sources.contains(.camera) {
            let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { _ in
                self.openImagePickerController(for: .camera)
            }
            actions.append(cameraAction)
        }
        
        if sources.contains(.document) {
            let documentAction = UIAlertAction(title: "Browse...", style: .default) { _ in
                self.openDocumentPicker()
            }
            actions.append(documentAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actions.append(cancelAction)
        
        actions.forEach { actionSheet.addAction($0) }
        pruneNegativeWidthConstraints(for: actionSheet)
        
        MediaPicker
            .imagePicker?
            .presentationContext?
            .present(
                actionSheet,
                animated: true,
                completion: nil)
    }
    
    private func openImagePickerController(for source: UIImagePickerController.SourceType) {
        /*guard let mediaTypes = UIImagePickerController.availableMediaTypes(for: source) else {
         print("ImagePicker Error: No Media type is available for provider source")
         return
         }*/
        guard let imagePicker = MediaPicker.imagePicker,
            let onVC = imagePicker.presentationContext else {
                return
        }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = imagePicker
        imagePickerController.sourceType = source
        
        // Use 'mediaTypes' if video and image both required. [public.image] is only for images.
        imagePickerController.mediaTypes = ["public.image"]
        imagePickerController.allowsEditing = true
        //imagePickerController.modalPresentationStyle = .overCurrentContext
        onVC.present(imagePickerController, animated: true)
    }
    
    private func openDocumentPicker() {
        
        let documentPickerController = UIDocumentPickerViewController(
            documentTypes: ["public.data"],
            in: .import)
        documentPickerController.delegate = self
        documentPickerController.modalPresentationStyle = .overCurrentContext
        
        guard let imagePicker = MediaPicker.imagePicker,
            let onVC = imagePicker.presentationContext else {
                return
        }
        onVC.present(documentPickerController, animated: true)
    }
    
    private func dismiss(_ picker: UIViewController) {
        picker.dismiss(animated: true) {
            MediaPicker.imagePicker = nil
        }
    }
    
    private func pruneNegativeWidthConstraints(for alert: UIAlertController) {
        for subView in alert.view.subviews {
            for constraint in subView.constraints where constraint.debugDescription.contains("width == - 16") {
                subView.removeConstraint(constraint)
            }
        }
    }
}

// MARK: - Nested type declaration

extension MediaPicker {
    ///
    enum Source {
        case camera, gallary, document
    }
}

// MARK: - ImagePickerController delegate methods

extension MediaPicker: UIImagePickerControllerDelegate {
    ///
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        guard let editedImage = info[.editedImage] as? UIImage else {
            print("MediaPicker Error: Edited image not found")
            return
        }
        
        guard let editedImageData = editedImage.jpegData(compressionQuality: 0.5) else {
            print("MediaPicker Error: Unable to convert image into jpeg data")
            return
        }
        
        let editedImageSize = Double(editedImageData.count) / 1000.0
        
        let media = Media()
        media.image = editedImage
        media.name = randomNameForImage
        media.ext = "jpeg"
        media.data = editedImageData
        media.size = editedImageSize
        
        completionMediaSelection?(media)
        dismiss(picker)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(picker)
    }
}

// MARK: - NavigationController delegate methods

extension MediaPicker: UINavigationControllerDelegate {
    ///
}

// MARK: - DocumentPickerController delegate methods

extension MediaPicker: UIDocumentPickerDelegate {
    ///
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]) {
        
        guard let documentURL = urls.first else {
            print("MediaPicker Error: No url received from document picker")
            return
        }
        
        let media = Media()
        
        let mediaNameWithExtension: NSString = documentURL.lastPathComponent as NSString
        media.name = mediaNameWithExtension.deletingPathExtension
        media.ext = mediaNameWithExtension.pathExtension
        
        guard let mediaData = try? Data(contentsOf: documentURL) else {
            print("MediaPicker Error: Unable to convert file into data")
            return
        }
        
        /// Convert into kb
        let mediaSize = Double(mediaData.count) / 1000.0
        media.data = mediaData
        media.size = mediaSize
        
        completionMediaSelection?(media)
        dismiss(controller)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(controller)
    }
}

// MARK: - Nested type declaration

extension MediaPicker {
    ///
    class Media {
        var name: String!
        var ext: String!
        var data: Data!
        /// Size is in kb
        var size: Double!
        var image: UIImage?
    }
}

extension MediaPicker.Media: CustomStringConvertible {
    var description: String {
        """
        name: \(name!)
        ext: \(ext!)
        size: \(size!)
        data: \(data!)
        image: \(String(describing: image))
        """
    }
}
