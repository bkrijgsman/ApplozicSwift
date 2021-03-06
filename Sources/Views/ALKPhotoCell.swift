//
//  ALKPhotoCell.swift
//  
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import Applozic

// MARK: - ALKPhotoCell
class ALKPhotoCell: ALKChatBaseCell<ALKMessageViewModel> {

    var photoView: UIImageView = {
        let mv = UIImageView()
        mv.backgroundColor = .clear
        mv.contentMode = .scaleAspectFill
        mv.clipsToBounds = true
        mv.layer.cornerRadius = 12
        return mv
    }()

    var timeLabel: UILabel = {
        let lb = UILabel()
        return lb
    }()

    var fileSizeLabel: UILabel = {
        let lb = UILabel()
        return lb
    }()

    fileprivate var actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        return button
    }()

    var bubbleView: UIView = {
        let bv = UIView()
        bv.backgroundColor = .gray
        bv.layer.cornerRadius = 12
        bv.isUserInteractionEnabled = false
        return bv
    }()

    fileprivate var downloadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "DownloadiOS", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.black
        return button
    }()

    var uploadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "UploadiOS2", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.black
        return button
    }()

    fileprivate let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)

    var url: URL? = nil
    enum state {
        case upload(filePath: String)
        case uploading(filePath: String)
        case uploaded
        case download
        case downloading
        case downloaded(filePath: String)
    }

    var currentState: state? = nil
    var uploadTapped:((Bool) ->())?
    var uploadCompleted: ((_ responseDict: Any?) ->())?

    class func topPadding() -> CGFloat {
        return 12
    }

    class func bottomPadding() -> CGFloat {
        return 16
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {

        let heigh: CGFloat

        if viewModel.ratio < 1 {
            heigh = viewModel.ratio == 0 ? (width*0.48) : ceil((width*0.48)/viewModel.ratio)
        } else {
            heigh = ceil((width*0.64)/viewModel.ratio)
        }

        return topPadding()+heigh+bottomPadding()
    }

    override func update(viewModel: ALKMessageViewModel) {

        self.viewModel = viewModel
        activityIndicator.color = .black
//        self.photoView.addSubview(uploadButton)
//        self.photoView.addSubview(activityIndicator)
//        self.photoView.image = UIImage()
//        if let filePath = viewModel.filePath {
//            let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            url = docDir.appendingPathComponent(filePath)
//        } else {
//            if let imageURL = viewModel.imageURL {
//                url = imageURL
//            } else if let imageUrl = viewModel.thumbnailURL {
//                url = imageUrl
//            }
//        }
//        print("file url: ", url)
//        photoView.kf.indicatorType = .activity
//        photoView.kf.setImage(with: url)
//        uploadButton.isHidden = true
        if viewModel.isMyMessage {
            if viewModel.isSent || viewModel.isAllRead || viewModel.isAllReceived {
                if let filePath = viewModel.filePath, !filePath.isEmpty {
                    updateView(for: state.downloaded(filePath: filePath))
                } else {
                    updateView(for: state.download)
                }
            } else {
                if let filePath = viewModel.filePath, !filePath.isEmpty {
                    if let state = currentState {
                        updateView(for: currentState!)
                    } else {
                        updateView(for: .upload(filePath: filePath))
                    }

                }
            }
        } else {
            if let filePath = viewModel.filePath, !filePath.isEmpty {
                updateView(for: state.downloaded(filePath: filePath))
            } else {
                updateView(for: state.download)
            }
        }

//        let fileString = ByteCountFormatter.string(fromByteCount: viewModel.size, countStyle: .file)

        timeLabel.text   = viewModel.time
        //                        fileSizeLabel.text = "Downloaded"
        //        if !viewModel.isMyMessage {
        //            if let originalMessagePart = viewModel.messagePart, originalMessagePart.data != nil {
        //                fileSizeLabel.text = "Downloaded"
        //            } else {
        //                fileSizeLabel.text = "File size: \(fileString)"
        //            }
        //        }

    }

    func actionTapped(button: UIButton) {
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.mediaViewer, bundle: Bundle.applozic)

        let nav = storyboard.instantiateInitialViewController() as? UINavigationController
        let vc = nav?.viewControllers.first as? ALKMediaViewerViewController
        let dbService = ALMessageDBService()
        guard let messages = dbService.getAllMessagesWithAttachment(forContact: viewModel?.contactId, andChannelKey: viewModel?.channelKey, onlyDownloadedAttachments: true) as? [ALMessage] else { return }

        let messageModels = messages.map { $0.messageModel }
        NSLog("Messages with attachment: ", messages )

        guard let viewModel = viewModel as? ALKMessageModel,
            let currentIndex = messageModels.index(of: viewModel) else { return }
        vc?.viewModel = ALKMediaViewerViewModel(messages: messageModels, currentIndex: currentIndex)
        UIViewController.topViewController()?.present(nav!, animated: true, completion: {
            button.isEnabled = true
        })

    }

    override func setupStyle() {
        super.setupStyle()

        timeLabel.setStyle(style: ALKMessageStyle.time)
        fileSizeLabel.setStyle(style: ALKMessageStyle.time)
    }

    override func setupViews() {
        super.setupViews()
        uploadButton.isHidden = true
        uploadButton.addTarget(self, action: #selector(ALKPhotoCell.uploadButtonAction(_:)), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(ALKPhotoCell.downloadButtonAction(_:)), for: .touchUpInside)
        contentView.addViewsForAutolayout(views: [photoView,bubbleView,actionButton,timeLabel,fileSizeLabel,uploadButton, downloadButton, activityIndicator])
        contentView.bringSubview(toFront: photoView)
//        contentView.bringSubview(toFront: actionButton)
        contentView.bringSubview(toFront: uploadButton)
        contentView.bringSubview(toFront: activityIndicator)

        bubbleView.topAnchor.constraint(equalTo: photoView.topAnchor).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: photoView.bottomAnchor).isActive = true
        bubbleView.leftAnchor.constraint(equalTo: photoView.leftAnchor).isActive = true
        bubbleView.rightAnchor.constraint(equalTo: photoView.rightAnchor).isActive = true

        actionButton.topAnchor.constraint(equalTo: photoView.topAnchor).isActive = true
        actionButton.bottomAnchor.constraint(equalTo: photoView.bottomAnchor).isActive = true
        actionButton.leftAnchor.constraint(equalTo: photoView.leftAnchor).isActive = true
        actionButton.rightAnchor.constraint(equalTo: photoView.rightAnchor).isActive = true
        
        fileSizeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 40).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true

        uploadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        uploadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        uploadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        uploadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        downloadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        downloadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        downloadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

    }
    
    deinit {
        actionButton.removeTarget(self, action: #selector(actionTapped), for: .touchUpInside)
    }

    @objc private func downloadButtonAction(_ selector: UIButton) {
        guard ALDataNetworkConnection.checkDataNetworkAvailable(), let viewModel = self.viewModel else {
            let notificationView = ALNotificationView()
            notificationView.noDataConnectionNotificationView()
            return
        }
        let downloadManager = ALKDownloadManager()
        downloadManager.delegate = self
        downloadManager.downloadVideo(message: viewModel)

    }


    func updateView(for state: state) {
        DispatchQueue.main.async {
            self.updateView(state: state)
        }
    }

    private func updateView(state: state) {
        switch state {
        case .upload(let filePath):
            currentState = .upload(filePath: filePath)
            actionButton.isEnabled = false
            uploadButton.isHidden = false
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(filePath)
            photoView.kf.setImage(with: path)
        case .uploaded:
            currentState = .uploaded
            if activityIndicator.isAnimating{
                activityIndicator.stopAnimating()
            }
            actionButton.isEnabled = true
            uploadButton.isHidden = true
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
        case .uploading(let filePath):
            if let state = currentState, case .uploading = state {
                // empty
            } else {
                let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let path = docDirPath.appendingPathComponent(filePath)
                photoView.kf.setImage(with: path, options: [.forceRefresh])
            }
            currentState = .uploading(filePath: filePath)
            uploadButton.isHidden = true
            actionButton.isEnabled = false
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating{
                activityIndicator.startAnimating()
            }
            downloadButton.isHidden = true
        case .download:
            currentState = .download
            downloadButton.isHidden = false
            actionButton.isEnabled = false
            activityIndicator.isHidden = true
            uploadButton.isHidden = true
            photoView.image = nil
        case .downloading:
            currentState = .downloading
            uploadButton.isHidden = true
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating{
                activityIndicator.startAnimating()
            }
            downloadButton.isHidden = true
            actionButton.isEnabled = false
            photoView.image = nil
        case .downloaded(let filePath):
            currentState = .downloaded(filePath: filePath)
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating{
                activityIndicator.startAnimating()
            }
            if activityIndicator.isAnimating{
                activityIndicator.stopAnimating()
            }
            viewModel?.filePath = filePath
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(filePath)
            photoView.kf.setImage(with: path)
            actionButton.isEnabled = true
            uploadButton.isHidden = true
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
        }
    }

    func setImage(imageView: UIImageView, name: String) {
        DispatchQueue.global(qos: .background).async {
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(name)
            do {
                let data = try Data(contentsOf: path)
                DispatchQueue.main.async {
                    imageView.image = UIImage(data: data)
                }
            } catch {
                DispatchQueue.main.async {
                    imageView.image = nil
                }
            }
        }
    }

    @objc private func uploadButtonAction(_ selector: UIButton) {
        uploadTapped?(true)
    }

    fileprivate func updateDbMessageWith(key: String, value: String, filePath: String) {
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        let dbMessage: DB_Message = messageService.getMessageByKey(key, value: value) as! DB_Message
        dbMessage.filePath = filePath
        do {
            try alHandler?.managedObjectContext.save()
        } catch {
            NSLog("Not saved due to error")
        }
    }

}

extension ALKPhotoCell: ALKDownloadManagerDelegate {
    func dataUpdated(countCompletion: Int64) {
        NSLog("VIDEO CELL DATA UPDATED AND FILEPATH IS: %@", viewModel?.filePath ?? "")
        DispatchQueue.main.async {
            self.updateView(for: .downloading)
        }
    }

    func dataFinished(path: String) {
        guard !path.isEmpty, let viewModel = self.viewModel else {
            updateView(for: .download)
            return
        }
        self.updateDbMessageWith(key: "key", value: viewModel.identifier, filePath: path)
        DispatchQueue.main.async {
            self.updateView(for: .downloaded(filePath: path))
        }
    }

    func dataUploaded(responseDictionary: Any?) {
        NSLog("VIDEO CELL DATA UPLOADED FOR PATH: %@ AND DICT: %@", viewModel?.filePath ?? "", responseDictionary.debugDescription)
        if responseDictionary == nil {
            DispatchQueue.main.async {
                self.updateView(for: .upload(filePath: self.viewModel?.filePath ?? ""))
            }
        } else if let filePath = viewModel?.filePath {
            DispatchQueue.main.async {
                self.updateView(for: state.downloaded(filePath: filePath))
            }
        }
        uploadCompleted?(responseDictionary)
    }
}

