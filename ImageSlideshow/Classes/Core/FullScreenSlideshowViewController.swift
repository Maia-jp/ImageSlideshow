//
//  FullScreenSlideshowViewController.swift
//  ImageSlideshow
//
//  Created by Petr Zvoníček on 31.08.15.
//

import UIKit

@objcMembers
open class FullScreenSlideshowViewController: UIViewController {

    open var slideshow: ImageSlideshow = {
        let slideshow = ImageSlideshow()
        slideshow.zoomEnabled = true
        slideshow.contentScaleMode = UIViewContentMode.scaleAspectFit
        slideshow.pageIndicatorPosition = PageIndicatorPosition(horizontal: .center, vertical: .bottom)
        // turns off the timer
        slideshow.slideshowInterval = 0
        slideshow.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]

        return slideshow
    }()

    /// Close button 
    open var closeButton = UIButton()
    
    /// Share button
    open var shareButton = UIButton()

    /// Close button frame
    open var closeButtonFrame: CGRect?
    
    /// Share button frame
    open var shareButtonFrame: CGRect?

    /// Closure called on page selection
    open var pageSelected: ((_ page: Int) -> Void)?

    /// Index of initial image
    open var initialPage: Int = 0

    /// Input sources to 
    open var inputs: [InputSource]?

    /// Background color
    open var backgroundColor = UIColor.black

    /// Enables/disable zoom
    open var zoomEnabled = true {
        didSet {
            slideshow.zoomEnabled = zoomEnabled
        }
    }

    fileprivate var isInit = true

    convenience init() {
        self.init(nibName: nil, bundle: nil)

        self.modalPresentationStyle = .custom
        if #available(iOS 13.0, *) {
            // Use KVC to set the value to preserve backwards compatiblity with Xcode < 11
            self.setValue(true, forKey: "modalInPresentation")
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = backgroundColor
        slideshow.backgroundColor = backgroundColor

        if let inputs = inputs {
            slideshow.setImageInputs(inputs)
        }

        view.addSubview(slideshow)

        // close button configuration
        closeButton.setImage(UIImage(named: "ic_cross_white", in: .module, compatibleWith: nil), for: UIControlState())
        closeButton.addTarget(self, action: #selector(FullScreenSlideshowViewController.close), for: UIControlEvents.touchUpInside)
        view.addSubview(closeButton)
        
        // share button configuration
        if #available(iOS 13.0, *) {
            shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        } else {
            shareButton.setImage(UIImage(named: "ic_share", in: .module, compatibleWith: nil), for: .normal)
        }
        shareButton.tintColor = .white
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        view.addSubview(shareButton)
    }

    override open var prefersStatusBarHidden: Bool {
        return true
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isInit {
            isInit = false
            slideshow.setCurrentPage(initialPage, animated: false)
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        slideshow.slideshowItems.forEach { $0.cancelPendingLoad() }

        // Prevents broken dismiss transition when image is zoomed in
        slideshow.currentSlideshowItem?.zoomOut()
    }

    open override func viewDidLayoutSubviews() {
        if !isBeingDismissed {
            let safeAreaInsets: UIEdgeInsets
            if #available(iOS 11.0, *) {
                safeAreaInsets = view.safeAreaInsets
            } else {
                safeAreaInsets = UIEdgeInsets.zero
            }

            closeButton.frame = closeButtonFrame ?? CGRect(x: max(10, safeAreaInsets.left), y: max(10, safeAreaInsets.top), width: 40, height: 40)
            shareButton.frame = shareButtonFrame ?? CGRect(x: view.frame.width - 50 - max(10, safeAreaInsets.right), y: max(10, safeAreaInsets.top), width: 40, height: 40)
        }

        slideshow.frame = view.frame
    }

    func close() {
        // if pageSelected closure set, send call it with current page
        if let pageSelected = pageSelected {
            pageSelected(slideshow.currentPage)
        }

        dismiss(animated: true, completion: nil)
    }
    
    @objc func share() {
        guard let currentItem = slideshow.currentSlideshowItem,
              let image = currentItem.imageView.image else { return }
        
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = shareButton
        present(activityViewController, animated: true)
    }
}
