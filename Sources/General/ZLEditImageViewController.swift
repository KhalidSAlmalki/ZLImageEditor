//
//  ZLEditImageViewController.swift
//  ZLImageEditor
//
//  Created by long on 2020/8/26.
//
//  Copyright (c) 2020 Long Zhang <495181165@qq.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

public class ZLEditImageViewController: UIViewController {

    static let drawColViewH: CGFloat = 50
    
    static let filterColViewH: CGFloat = 80
    
    static let adjustColViewH: CGFloat = 60
    
    static let maxDrawLineImageWidth: CGFloat = 600
    
    static let ashbinNormalBgColor = zlRGB(40, 40, 40).withAlphaComponent(0.8)
    
    var activityView: UIActivityIndicatorView?

    var animateDismiss = true
    
    var originalImage: UIImage
    
    // The frame after first layout, used in dismiss animation.
    var originalFrame: CGRect = .zero
    
    var editRect: CGRect {
        return .init(origin: CGPoint(x: 0,
                                     y: 0),
                     size: backgroundimageSize)
    }
    
    let tools: [ZLImageEditorConfiguration.EditTool]
    
    let adjustTools: [ZLImageEditorConfiguration.AdjustTool]
    
    var selectRatio: ZLImageClipRatio?
    
    var editImage: UIImage
    
    var editImageWithoutAdjust: UIImage
    
    var editImageAdjustRef: UIImage?
    
    var cancelBtn: UIButton!
    var doneBtn: UIButton!

    var scrollView: UIScrollView!
    
    var containerView: UIView!
    
    lazy var dumyViewBorder = UIView()

    // Show image.
    var imageView: UIImageView!
    
    // Show draw lines.
    var drawingImageView: UIImageView!
    
    // Show text and image stickers.
    var stickersContainer: UIView!
    
    var mosaicImage: UIImage?
    
    // Show mosaic image
    var mosaicImageLayer: CALayer?
    
    // The mask layer of mosaicImageLayer
    var mosaicImageLayerMaskLayer: CAShapeLayer?
    
    var topShadowView: UIView!
    
    var topShadowLayer: CAGradientLayer!
     
    var bottomShadowView: UIView!
    
    var bottomShadowLayer: CAGradientLayer!
        
    var revokeBtn: UIButton!
    
    var selectedTool: ZLImageEditorConfiguration.EditTool?
    
    var selectedAdjustTool: ZLImageEditorConfiguration.AdjustTool?
    
    var editToolCollectionView: UICollectionView!
    
    var drawColorCollectionView: UICollectionView?
    
    var filterCollectionView: UICollectionView?
    
    var adjustCollectionView: UICollectionView?
    
    var textColorsCollectionView: UICollectionView!

    var adjustSlider: ZLAdjustSlider?
    
    var ashbinView: UIView!
    
    var ashbinImgView: UIImageView!
    
    //colors
    let drawColors: [UIColor]
    var backgroundColors: [UIColor] = ZLImageEditorConfiguration.default().imageBackgroundColors
    var currentBackgroundColor: UIColor = ZLImageEditorConfiguration.default().defaultBackgroundColor

    var currentDrawColor = ZLImageEditorConfiguration.default().defaultDrawColor
    
    var drawPaths: [ZLDrawPath]
    
    var drawLineWidth: CGFloat = 5
    
    var mosaicPaths: [ZLMosaicPath]
    
    var mosaicLineWidth: CGFloat = 25
    
    var thumbnailFilterImages: [UIImage] = []
    
    // Cache the filter image of original image
    var filterImages: [String: UIImage] = [:]
    
    var currentFilter: ZLFilter
    
    var stickers: [UIView] = []
    
    var isScrolling = false
    
    var shouldLayout = true
    
    var imageStickerContainerIsHidden = true
    
    var angle: CGFloat
    
    var brightness: Float
    
    var contrast: Float
    
    var saturation: Float
    
    var panGes: UIPanGestureRecognizer!
    
    var backgroundImage: UIImage?
    
    var backgroundimageSize: CGSize {
        return CGSize(width: 375,
                      height: 375)
    }
    
    var lodaingImageQueue: [String] = []
    
    var allowCustomColor: Bool = false
    
    @objc public var editFinishBlock: ( (UIImage, ZLEditImageModel) -> Void )?
    
    @objc public var didFinishSetupBlock: ( (UIImage) -> Void )?

    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    deinit {
        zl_debugPrint("ZLEditImageViewController deinit")
    }
    
    @objc public class func showEditImageVC(parentVC: UIViewController?,
                                            animate: Bool = true,
                                            image: UIImage,
                                            editModel: ZLEditImageModel? = nil,
                                            completion: ( (UIImage, ZLEditImageModel) -> Void )? ) {
        let tools = ZLImageEditorConfiguration.default().tools
        if ZLImageEditorConfiguration.default().showClipDirectlyIfOnlyHasClipTool, tools.count == 1, tools.contains(.clip) {
            let vc = ZLClipImageViewController(image: image, editRect: editModel?.editRect, angle: editModel?.angle ?? 0, selectRatio: editModel?.selectRatio)
            vc.clipDoneBlock = { (angle, editRect, ratio) in
                let m = ZLEditImageModel(drawPaths: [],
                                         mosaicPaths: [],
                                         editRect: editRect,
                                         angle: angle,
                                         brightness: 0,
                                         contrast: 0,
                                         saturation: 0,
                                         selectRatio: ratio,
                                         selectFilter: .normal,
                                         textStickers: nil,
                                         imageStickers: nil,
                                         customBackgroundImage: nil)
                m.allowCustomColor = editModel?.allowCustomColor ?? false
                completion?(image.clipImage(angle, editRect) ?? image, m)
            }
            vc.animateDismiss = animate
            vc.modalPresentationStyle = .fullScreen
            parentVC?.present(vc, animated: animate, completion: nil)
        } else {
            let vc = ZLEditImageViewController(image: image, editModel: editModel)
            vc.editFinishBlock = { (ei, editImageModel) in
                completion?(ei, editImageModel)
            }
            vc.animateDismiss = animate
            vc.modalPresentationStyle = .fullScreen
            parentVC?.present(vc, animated: animate, completion: nil)
        }
    }
    
    @objc public init(image: UIImage,
               editModel: ZLEditImageModel? = nil) {
        backgroundImage = editModel?.customBackgroundImage
        originalImage = editModel?.customBackgroundImage ?? .init()
        editImage = originalImage
        editImageWithoutAdjust = originalImage
        drawColors = ZLImageEditorConfiguration.default().drawColors
        allowCustomColor = editModel?.allowCustomColor ?? false
        currentFilter = editModel?.selectFilter ?? .normal
        drawPaths = editModel?.drawPaths ?? []
        mosaicPaths = editModel?.mosaicPaths ?? []
        angle = editModel?.angle ?? 0
        brightness = editModel?.brightness ?? 0
        contrast = editModel?.contrast ?? 0
        saturation = editModel?.saturation ?? 0
        selectRatio = editModel?.selectRatio
        
        
        var ts = ZLImageEditorConfiguration.default().tools
        if ts.contains(.imageSticker), ZLImageEditorConfiguration.default().imageStickerContainerView == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        tools = ts
        adjustTools = ZLImageEditorConfiguration.default().adjustTools
        selectedAdjustTool = adjustTools.first
        
        super.init(nibName: nil, bundle: nil)
        if !self.drawColors.contains(self.currentDrawColor) {
            self.currentDrawColor = self.drawColors.first!
        }

   //     self.currentBackgroundColor = self.backgroundColors.first!
        setStyleForImageBorder()

        let teStic = (editModel?.textStickers ?? []).sorted(by: { $0.sortOrder ?? 0 < $1.sortOrder ?? 1             })
        let imStic = (editModel?.imageStickers ?? []).sorted(by: { $0.sortOrder ?? 0 < $1.sortOrder ?? 1})
        
        var stickers: [UIView?] = []
        
        teStic.forEach { (cache) in
            let v = ZLTextStickerView(from: cache)
            stickers.append(v)
        }
        
        self.stickers = stickers.compactMap { $0 }

        imStic.forEach { (cache) in
            self.addTolodaingImageQueue(cache.imageName)
            let v = ZLImageStickerView(from: cache, imageStickerData: .init(image: .init(), name: cache.imageName))
                stickers.append(v)
            self.stickers = stickers.compactMap { $0 }

            DispatchQueue.main.async {
                self.showActivityIndicator()
                self.setupStickers()
            }
            if  ZLImageEditorConfiguration.default().imageStickerContainerView == nil {
                print("")
            }
            ZLImageEditorConfiguration.default().imageStickerContainerView?.getImage(imageName: cache.imageName, { data in
                if let index = self.stickers.firstIndex(where: { ($0 as? ZLImageStickerView)?.image.name == data.name}) {
                    if let state = (self.stickers[index] as? ZLImageStickerView)?.state {
                        self.stickers[index] = ZLImageStickerView(from: state, imageStickerData: data)
                    } else {
                        debugPrint("--did not find it---")
                    }
                } else {
                    debugPrint("--did not find it---")
                }
                self.removeTolodaingImageQueue(data.name)
            })
            
         
        }
        

        DispatchQueue.main.async {
            self.setupStickers()
        }
   

        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addTolodaingImageQueue(_ item: String) {
        self.lodaingImageQueue.append(item)
    }
    
    private func removeTolodaingImageQueue(_ item: String) {
        self.lodaingImageQueue.removeAll(where: {$0 == item})
        sendDidFinshSetupIfNeeded()
    }
    
    func sendDidFinshSetupIfNeeded() {
        if self.lodaingImageQueue.isEmpty {
            self.hideActivityIndicator()
            self.setupStickers()
            self.configColors()
            self.didFinishSetupBlock?(UIImage(view: self.containerView) ?? .init())
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        self.rotationImageView()
        if self.tools.contains(.filter) {
            self.generateFilterImages()
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard self.shouldLayout else {
            self.editToolCollectionView.center.x = bottomShadowView.center.x
            return
        }
        self.shouldLayout = false
        zl_debugPrint("edit image layout subviews")
        
        let insets = self.view.safeAreaInsets
      
        
        self.scrollView.frame = self.view.bounds
        self.resetContainerViewFrame()
        let bnY =  UIScreen.main.heightOfSafeArea()
        self.topShadowView.frame = CGRect(x: 0,
                                          y: 0,
                                          width: self.view.frame.width,
                                          height: 150)
        self.topShadowLayer.frame = self.topShadowView.bounds
        self.cancelBtn.frame = CGRect(x: 30, y: bnY, width: 60, height: 28)
        self.doneBtn.frame = CGRect(x: self.topShadowLayer.frame.width-70,
                                    y: bnY,
                                    width: 40,
                                    height: 28)

        self.bottomShadowView.frame = CGRect(x: 0,
                                             y: self.view.frame.height - 160 - insets.bottom,
                                             width: self.view.frame.width,
                                             height: 140 + insets.bottom)
        
        self.bottomShadowView.center.x = view.center.x
        self.bottomShadowLayer.frame = self.bottomShadowView.bounds
        
        self.drawColorCollectionView?.frame = CGRect(x: 20,
                                                     y: 20,
                                                     width: self.view.frame.width - 80,
                                                     height: ZLEditImageViewController.drawColViewH)
        
        self.textColorsCollectionView?.frame = CGRect(x: 0, y: 30, width: self.view.frame.width, height: 35)

        self.revokeBtn.frame = CGRect(x: self.view.frame.width - 15 - 35, y: 30, width: 35, height: 30)
        
        self.adjustCollectionView?.frame = CGRect(x: 20, y: 10, width: view.frame.width - 40, height: ZLEditImageViewController.adjustColViewH)
        self.adjustSlider?.frame = CGRect(x: view.frame.width - 60, y: view.frame.height / 2 - 100, width: 60, height: 200)
        
        self.filterCollectionView?.frame = CGRect(x: 20, y: 0, width: self.view.frame.width - 40, height: ZLEditImageViewController.filterColViewH)
        
        let toolY: CGFloat = 50
        
        
        self.editToolCollectionView.frame = CGRect(x: 0,
                                                   y: toolY,
                                                   width: CGFloat((self.tools.count*60)),
                                                   height: 50)

        self.editToolCollectionView.center.x = bottomShadowView.center.x
        
        if !self.drawPaths.isEmpty {
            self.drawLine()
        }
        if !self.mosaicPaths.isEmpty {
            self.generateNewMosaicImage()
        }
        
        if let index = self.drawColors.firstIndex(where: { $0 == self.currentDrawColor}) {
            self.drawColorCollectionView?.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    func generateFilterImages() {
        let size: CGSize
        let ratio = (self.originalImage.size.width / self.originalImage.size.height)
        let fixLength: CGFloat = 200
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        let thumbnailImage = self.originalImage.resize(size) ?? self.originalImage
        
        DispatchQueue.global().async {
            self.thumbnailFilterImages = ZLImageEditorConfiguration.default().filters.map { $0.applier?(thumbnailImage) ?? thumbnailImage }
            
            DispatchQueue.main.async {
                self.filterCollectionView?.reloadData()
                self.filterCollectionView?.performBatchUpdates {
                    
                } completion: { (_) in
                    if let index = ZLImageEditorConfiguration.default().filters.firstIndex(where: { $0 == self.currentFilter }) {
                        self.filterCollectionView?.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
                    }
                }
            }
        }
    }
    
    func resetContainerViewFrame() {
        guard self.scrollView != nil else {
            return
        }
        self.scrollView.setZoomScale(1, animated: true)
        self.imageView.image = self.editImage
        self.imageView.contentMode = .scaleAspectFill


        let editSize = self.editRect.size
        let scrollViewSize = self.scrollView.frame.size
//        let ratio = min(scrollViewSize.width / editSize.width, scrollViewSize.height / editSize.height)
        let ratio: CGFloat = 1

        let w = ratio * editSize.width * self.scrollView.zoomScale
        let h = ratio * editSize.height * self.scrollView.zoomScale
        self.containerView.frame = CGRect(x: max(0, (scrollViewSize.width-w)/2), y: max(0, (scrollViewSize.height-h)/2), width: w, height: h)
        self.dumyViewBorder.frame = self.containerView.frame
        self.dumyViewBorder.center = view.center
        
        let scaleImageOrigin = CGPoint(x: -self.editRect.origin.x*ratio, y: -self.editRect.origin.y*ratio)
        let scaleImageSize = CGSize(width: self.backgroundimageSize.width * ratio, height: self.backgroundimageSize.height * ratio)
        self.imageView.frame = CGRect(origin: scaleImageOrigin, size: scaleImageSize)
        self.mosaicImageLayer?.frame = self.imageView.bounds
        self.mosaicImageLayerMaskLayer?.frame = self.imageView.bounds
        self.drawingImageView.frame = self.imageView.frame
        self.stickersContainer.frame = self.imageView.frame
        self.dumyViewBorder.frame = self.stickersContainer.frame
        self.dumyViewBorder.center = view.center

        // Optimization for long pictures.
        if (self.editRect.height / self.editRect.width) > (self.view.frame.height / self.view.frame.width * 1.1) {
            let widthScale = self.view.frame.width / w
            self.scrollView.maximumZoomScale = widthScale
            self.scrollView.zoomScale = widthScale
            self.scrollView.contentOffset = .zero
        } else if self.editRect.width / self.editRect.height > 1 {
            self.scrollView.maximumZoomScale = max(3, self.view.frame.height / h)
        }
        
        self.originalFrame = self.view.convert(self.containerView.frame, from: self.scrollView)
        self.isScrolling = false
    }
    
    fileprivate func setupStickers() {
        resetContainerViewFrame()
        self.stickersContainer?.subviews.forEach({ $0.removeFromSuperview() })
        self.stickers.forEach { (view) in
            self.stickersContainer.addSubview(view)
            if let tv = view as? ZLTextStickerView {
                tv.frame = tv.originFrame
                let newSize = ZLTextStickerView.calculateSize(text: tv.label.text ?? "",
                                                              width: self.view.frame.width)
                tv.changeSize(to: newSize)
                self.configTextSticker(tv)
             
            } else if let iv = view as? ZLImageStickerView {
                iv.frame = iv.originFrame
                
                self.configImageSticker(iv)
            }
        }
    
        self.stickersContainer.subviews.forEach { (view) in
            
            if let tv = view as? ZLTextStickerView {
                tv.bringToFront()
            }
        }
        
    }
    
    func setupUI() {
        self.view.backgroundColor = .black
        
        self.scrollView = UIScrollView()
        self.scrollView.backgroundColor = .black
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 3
        self.scrollView.delegate = self
        self.view.addSubview(self.scrollView)
        
        self.containerView = UIView()
        self.containerView.clipsToBounds = true
        self.scrollView.addSubview(self.containerView)
        
        self.imageView = UIImageView(image: self.originalImage)
        self.imageView.contentMode = .redraw
        self.imageView.clipsToBounds = true
        self.imageView.backgroundColor = currentBackgroundColor
        self.containerView.addSubview(self.imageView)
        
        self.drawingImageView = UIImageView()
        self.drawingImageView.contentMode = .scaleAspectFit
        self.drawingImageView.isUserInteractionEnabled = true
        self.containerView.addSubview(self.drawingImageView)
        
        self.stickersContainer = UIView()
        self.containerView.addSubview(self.stickersContainer)

        

        self.view.addSubview(dumyViewBorder)
        dumyViewBorder.frame = self.stickersContainer.frame
   
        self.dumyViewBorder.layer.borderColor = UIColor.clear.cgColor
        self.dumyViewBorder.layer.borderWidth = 1
        self.dumyViewBorder.backgroundColor = .clear
        self.dumyViewBorder.isUserInteractionEnabled = false
        
        setStyleForImageBorder()

        let color1 = UIColor.black.withAlphaComponent(0.35).cgColor
        let color2 = UIColor.black.withAlphaComponent(0).cgColor
        self.topShadowView = UIView()
        self.view.addSubview(self.topShadowView)
        
        self.topShadowLayer = CAGradientLayer()
        self.topShadowLayer.colors = [color1, color2]
        self.topShadowLayer.locations = [0, 1]
        self.topShadowView.layer.addSublayer(self.topShadowLayer)
        
        self.cancelBtn = UIButton(type: .custom)
        self.cancelBtn.setTitle(localLanguageTextValue(.cancel), for: .normal)
        self.cancelBtn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        self.cancelBtn.adjustsImageWhenHighlighted = false
        self.cancelBtn.zl_enlargeValidTouchArea(inset: 30)
        self.topShadowView.addSubview(self.cancelBtn)
        
        self.doneBtn = UIButton(type: .custom)
        self.doneBtn.setTitle(localLanguageTextValue(.save), for: .normal)
        self.doneBtn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        self.doneBtn.zl_enlargeValidTouchArea(inset: 30)
        self.topShadowView.addSubview(self.doneBtn)
        
        self.bottomShadowView = UIView()
        self.view.addSubview(self.bottomShadowView)
        
        self.bottomShadowLayer = CAGradientLayer()
        self.bottomShadowLayer.colors = [color2, color1]
        self.bottomShadowLayer.locations = [0, 1]
        self.bottomShadowView.layer.addSublayer(self.bottomShadowLayer)
        
        let editToolLayout = UICollectionViewFlowLayout()
        editToolLayout.itemSize = CGSize(width: 42, height: 36)
        editToolLayout.minimumLineSpacing = 20
        editToolLayout.minimumInteritemSpacing = 20
        editToolLayout.scrollDirection = .horizontal
        self.editToolCollectionView = UICollectionView(frame: .zero, collectionViewLayout: editToolLayout)
        self.editToolCollectionView.backgroundColor = .clear
        self.editToolCollectionView.delegate = self
        self.editToolCollectionView.dataSource = self
        self.editToolCollectionView.showsHorizontalScrollIndicator = false
        self.bottomShadowView.addSubview(self.editToolCollectionView)
        
        let colorToolLayout = UICollectionViewFlowLayout()
            colorToolLayout.itemSize = CGSize(width: 35, height: 35)
            colorToolLayout.minimumLineSpacing = 10
            colorToolLayout.minimumInteritemSpacing = 10
            colorToolLayout.scrollDirection = .horizontal
        
        self.textColorsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: colorToolLayout)
        self.textColorsCollectionView.delegate = self
        self.textColorsCollectionView.dataSource = self
        self.textColorsCollectionView.showsHorizontalScrollIndicator = false
        self.textColorsCollectionView.backgroundColor = .clear
        self.textColorsCollectionView.isHidden = true
        self.bottomShadowView.addSubview(self.textColorsCollectionView)

        ZLEditToolCell.zl_register(self.editToolCollectionView)
        
        ZLDrawColorCell.zl_register(textColorsCollectionView)
        
        if tools.contains(.draw) {
            let drawColorLayout = UICollectionViewFlowLayout()
            let drawColorItemWidth: CGFloat = 30
            drawColorLayout.itemSize = CGSize(width: drawColorItemWidth, height: drawColorItemWidth)
            drawColorLayout.minimumLineSpacing = 15
            drawColorLayout.minimumInteritemSpacing = 15
            drawColorLayout.scrollDirection = .horizontal
            let drawColorTopBottomInset = (ZLEditImageViewController.drawColViewH - drawColorItemWidth) / 2
            drawColorLayout.sectionInset = UIEdgeInsets(top: drawColorTopBottomInset, left: 0, bottom: drawColorTopBottomInset, right: 0)
            
            let drawCV = UICollectionView(frame: .zero, collectionViewLayout: drawColorLayout)
            drawCV.backgroundColor = .clear
            drawCV.delegate = self
            drawCV.dataSource = self
            drawCV.isHidden = true
            drawCV.showsHorizontalScrollIndicator = false
            bottomShadowView.addSubview(drawCV)
            
            ZLDrawColorCell.zl_register(drawCV)
            drawColorCollectionView = drawCV
        }
        
        if tools.contains(.filter) {
            if let applier = currentFilter.applier {
                let image = applier(originalImage)
                editImage = image
                editImageWithoutAdjust = image
                filterImages[currentFilter.name] = image
            }
            
            let filterLayout = UICollectionViewFlowLayout()
            filterLayout.itemSize = CGSize(width: ZLEditImageViewController.filterColViewH - 20, height: ZLEditImageViewController.filterColViewH)
            filterLayout.minimumLineSpacing = 15
            filterLayout.minimumInteritemSpacing = 15
            filterLayout.scrollDirection = .horizontal
            
            let filterCV = UICollectionView(frame: .zero, collectionViewLayout: filterLayout)
            filterCV.backgroundColor = .clear
            filterCV.delegate = self
            filterCV.dataSource = self
            filterCV.isHidden = true
            filterCV.showsHorizontalScrollIndicator = false
            bottomShadowView.addSubview(filterCV)
            
            ZLFilterImageCell.zl_register(filterCV)
            filterCollectionView = filterCV
        }
        
        if tools.contains(.adjust) {
            editImage = editImage.adjust(brightness: brightness, contrast: contrast, saturation: saturation) ?? editImage
            
            let adjustLayout = UICollectionViewFlowLayout()
            adjustLayout.itemSize = CGSize(width: ZLEditImageViewController.adjustColViewH, height: ZLEditImageViewController.adjustColViewH)
            adjustLayout.minimumLineSpacing = 10
            adjustLayout.minimumInteritemSpacing = 10
            adjustLayout.scrollDirection = .horizontal
            
            let adjustCV = UICollectionView(frame: .zero, collectionViewLayout: adjustLayout)
            
            adjustCV.backgroundColor = .clear
            adjustCV.delegate = self
            adjustCV.dataSource = self
            adjustCV.isHidden = true
            adjustCV.showsHorizontalScrollIndicator = false
            bottomShadowView.addSubview(adjustCV)
            
            ZLAdjustToolCell.zl_register(adjustCV)
            adjustCollectionView = adjustCV
            
            adjustSlider = ZLAdjustSlider()
            if let selectedAdjustTool = selectedAdjustTool {
                changeAdjustTool(selectedAdjustTool)
            }
            adjustSlider?.beginAdjust = {
            }
            adjustSlider?.valueChanged = { [weak self] value in
                self?.adjustValueChanged(value)
            }
            adjustSlider?.endAdjust = { [weak self] in
                self?.endAdjust()
            }
            adjustSlider?.isHidden = true
            view.addSubview(adjustSlider!)
        }
        
        self.revokeBtn = UIButton(type: .custom)
        self.revokeBtn.setImage(getImage("zl_revoke_disable"), for: .disabled)
        self.revokeBtn.setImage(getImage("zl_revoke"), for: .normal)
        self.revokeBtn.adjustsImageWhenHighlighted = false
        self.revokeBtn.isEnabled = false
        self.revokeBtn.isHidden = true
        self.revokeBtn.addTarget(self, action: #selector(revokeBtnClick), for: .touchUpInside)
        self.bottomShadowView.addSubview(self.revokeBtn)
        
        let ashbinSize = CGSize(width: 160, height: 80)
        self.ashbinView = UIView(frame: CGRect(x: (self.view.frame.width-ashbinSize.width)/2, y: self.view.frame.height-ashbinSize.height-40, width: ashbinSize.width, height: ashbinSize.height))
        self.ashbinView.backgroundColor = ZLEditImageViewController.ashbinNormalBgColor
        self.ashbinView.layer.cornerRadius = 15
        self.ashbinView.layer.masksToBounds = true
        self.ashbinView.isHidden = true
        self.view.addSubview(self.ashbinView)
        
        self.ashbinImgView = UIImageView(image: getImage("zl_ashbin"), highlightedImage: getImage("zl_ashbin_open"))
        self.ashbinImgView.frame = CGRect(x: (ashbinSize.width-25)/2, y: 15, width: 25, height: 25)
        self.ashbinView.addSubview(self.ashbinImgView)
        
        let asbinTipLabel = UILabel(frame: CGRect(x: 0, y: ashbinSize.height-34, width: ashbinSize.width, height: 34))
        asbinTipLabel.font = UIFont.systemFont(ofSize: 12)
        asbinTipLabel.textAlignment = .center
        asbinTipLabel.textColor = .white
        asbinTipLabel.text = localLanguageTextValue(.textStickerRemoveTips)
        asbinTipLabel.numberOfLines = 2
        asbinTipLabel.lineBreakMode = .byCharWrapping
        self.ashbinView.addSubview(asbinTipLabel)
        
        if self.tools.contains(.mosaic) {
            mosaicImage = editImage.mosaicImage()
            
            self.mosaicImageLayer = CALayer()
            self.mosaicImageLayer?.contents = self.mosaicImage?.cgImage
            self.imageView.layer.addSublayer(self.mosaicImageLayer!)
            
            self.mosaicImageLayerMaskLayer = CAShapeLayer()
            self.mosaicImageLayerMaskLayer?.strokeColor = UIColor.blue.cgColor
            self.mosaicImageLayerMaskLayer?.fillColor = nil
            self.mosaicImageLayerMaskLayer?.lineCap = .round
            self.mosaicImageLayerMaskLayer?.lineJoin = .round
            self.imageView.layer.addSublayer(self.mosaicImageLayerMaskLayer!)
            
            self.mosaicImageLayer?.mask = self.mosaicImageLayerMaskLayer
        }
        
        if self.tools.contains(.imageSticker) {
            ZLImageEditorConfiguration.default().imageStickerContainerView?.hideBlock = { [weak self] in
                self?.setToolView(show: true)
                self?.imageStickerContainerIsHidden = true
            }
            
            ZLImageEditorConfiguration.default().imageStickerContainerView?.selectImageBlock = { [weak self] (image) in
                self?.addImageStickerView(image)
            }
        }
        
        
        
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapGes.delegate = self
        self.view.addGestureRecognizer(tapGes)
        
        self.panGes = UIPanGestureRecognizer(target: self, action: #selector(drawAction(_:)))
        self.panGes.maximumNumberOfTouches = 1
        self.panGes.delegate = self
        self.view.addGestureRecognizer(self.panGes)
        self.scrollView.panGestureRecognizer.require(toFail: self.panGes)
        
        setupStickers()
        
        self.imageView.contentMode = .scaleAspectFill

        configColors()
    }
    
    func rotationImageView() {
        let transform = CGAffineTransform(rotationAngle: self.angle.toPi)
        self.imageView.transform = transform
        self.drawingImageView.transform = transform
        self.stickersContainer.transform = transform
    }
    
    @objc func cancelBtnClick() {
        self.dismiss(animated: self.animateDismiss, completion: nil)
    }
    
    func drawBtnClick() {
        let isSelected = selectedTool != .draw
        if isSelected {
            selectedTool = .draw
        } else {
            selectedTool = nil
        }
        drawColorCollectionView?.isHidden = !isSelected
        revokeBtn.isHidden = !isSelected
        revokeBtn.isEnabled = drawPaths.count > 0
        filterCollectionView?.isHidden = true
        adjustCollectionView?.isHidden = true
        adjustSlider?.isHidden = true
    }
    
    func clipBtnClick() {
        let currentEditImage = buildImage()
        
        let vc = ZLClipImageViewController(image: currentEditImage, editRect: editRect, angle: angle, selectRatio: selectRatio)
        let rect = scrollView.convert(containerView.frame, to: view)
        vc.presentAnimateFrame = rect
        vc.presentAnimateImage = currentEditImage.clipImage(angle, editRect)
        vc.modalPresentationStyle = .fullScreen
        
        vc.clipDoneBlock = { [weak self] (angle, editFrame, selectRatio) in
            guard let `self` = self else { return }
            let oldAngle = self.angle
            let oldContainerSize = self.stickersContainer.frame.size
            if self.angle != angle {
                self.angle = angle
                self.rotationImageView()
            }
            self.selectRatio = selectRatio
            self.resetContainerViewFrame()
            self.reCalculateStickersFrame(oldContainerSize, oldAngle, angle)
        }
        
        vc.cancelClipBlock = { [weak self] () in
            self?.resetContainerViewFrame()
        }
        
        present(vc, animated: false) {
            self.scrollView.alpha = 0
            self.topShadowView.alpha = 0
            self.bottomShadowView.alpha = 0
            self.adjustSlider?.alpha = 0
        }
    }
    
    func imagePickerBtnClick() {
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        self.present(picker, animated: true)
    }
    
    func imageStickerBtnClick() {
        ZLImageEditorConfiguration.default().imageStickerContainerView?.show(in: view)
        setToolView(show: false)
        imageStickerContainerIsHidden = false
    }
    
    func textStickerBtnClick() {
        showInputTextVC { [weak self] (text, textColor, bgColor) in
            self?.addTextStickersView(text, textColor: textColor, bgColor: bgColor)
        }
    }
    
    func mosaicBtnClick() {
        let isSelected = selectedTool != .mosaic
        if isSelected {
            selectedTool = .mosaic
        } else {
            selectedTool = nil
        }
        
        drawColorCollectionView?.isHidden = true
        filterCollectionView?.isHidden = true
        adjustCollectionView?.isHidden = true
        adjustSlider?.isHidden = true
        revokeBtn.isHidden = !isSelected
        revokeBtn.isEnabled = mosaicPaths.count > 0
    }
    
    func filterBtnClick() {
        let isSelected = selectedTool != .filter
        if isSelected {
            selectedTool = .filter
        } else {
            selectedTool = nil
        }
        
        drawColorCollectionView?.isHidden = true
        revokeBtn.isHidden = true
        filterCollectionView?.isHidden = !isSelected
        adjustCollectionView?.isHidden = true
        adjustSlider?.isHidden = true
    }
    
    func adjustBtnClick() {
        let isSelected = selectedTool != .adjust
        if isSelected {
            selectedTool = .adjust
        } else {
            selectedTool = nil
        }
        
        drawColorCollectionView?.isHidden = true
        revokeBtn.isHidden = true
        filterCollectionView?.isHidden = true
        adjustCollectionView?.isHidden = !isSelected
        adjustSlider?.isHidden = !isSelected
        
        generateAdjustImageRef()
    }
    
    func changeAdjustTool(_ tool: ZLImageEditorConfiguration.AdjustTool) {
        selectedAdjustTool = tool
        
        switch tool {
        case .brightness:
            adjustSlider?.value = brightness
        case .contrast:
            adjustSlider?.value = contrast
        case .saturation:
            adjustSlider?.value = saturation
        }
        
        generateAdjustImageRef()
    }
    
    @objc public func doneBtnClick() {
        var textStickers: [ZLTextStickerState] = []
        var imageStickers: [ZLImageStickerState] = []
        for  (index, view) in stickersContainer.subviews.enumerated() {
            if let ts = view as? ZLTextStickerView, let _ = ts.label.text {
                ts.tag = index
                ts.originFrame = view.frame
                let ts_ = ts.state
                textStickers.append(ts_)
            } else if let ts = view as? ZLImageStickerView {
                ts.tag = index
              //  ts.originFrame = view.frame
                imageStickers.append(ts.state)
            }
        }
       
        if drawPaths.isEmpty,
           editRect.size == backgroundimageSize,
            angle == 0, mosaicPaths.isEmpty,
           imageStickers.isEmpty,
           textStickers.isEmpty,
           currentFilter.applier == nil,
            brightness == 0,
           contrast == 0,
           saturation == 0 {
        }
        
        let editModel = ZLEditImageModel(drawPaths: drawPaths,
                                         mosaicPaths: mosaicPaths,
                                         editRect: editRect,
                                         angle: angle,
                                         brightness: brightness,
                                         contrast: contrast,
                                         saturation: saturation,
                                         selectRatio: selectRatio,
                                         selectFilter: currentFilter,
                                         textStickers: textStickers,
                                         imageStickers: imageStickers,
                                         customBackgroundImage: backgroundImage)

        dismiss(animated: animateDismiss) {
            self.editFinishBlock?(UIImage(view: self.containerView)!, editModel)
        }
    }
    
    @objc func revokeBtnClick() {
        if self.selectedTool == .draw {
            guard !self.drawPaths.isEmpty else {
                return
            }
            self.drawPaths.removeLast()
            self.revokeBtn.isEnabled = self.drawPaths.count > 0
            self.drawLine()
        } else if self.selectedTool == .mosaic {
            guard !self.mosaicPaths.isEmpty else {
                return
            }
            self.mosaicPaths.removeLast()
            self.revokeBtn.isEnabled = self.mosaicPaths.count > 0
            self.generateNewMosaicImage()
        }
    }
    
    @objc func tapAction(_ tap: UITapGestureRecognizer) {
//        if self.bottomShadowView.alpha == 1 {
//            self.setToolView(show: false)
//        } else {
//            self.setToolView(show: true)
//        }
    }
    
    @objc func drawAction(_ pan: UIPanGestureRecognizer) {
        if self.selectedTool == .draw {
            let point = pan.location(in: self.drawingImageView)
            if pan.state == .began {
                self.setToolView(show: false)
                
                let originalRatio = min(self.scrollView.frame.width / self.originalImage.size.width, self.scrollView.frame.height / self.originalImage.size.height)
                let ratio = min(self.scrollView.frame.width / self.editRect.width, self.scrollView.frame.height / self.editRect.height)
                let scale = ratio / originalRatio
                // Zoom to original size
                var size = self.drawingImageView.frame.size
                size.width /= scale
                size.height /= scale
                if self.angle == -90 || self.angle == -270 {
                    swap(&size.width, &size.height)
                }
                
                var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
                if self.editImage.size.width / self.editImage.size.height > 1 {
                    toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
                }
                
                let path = ZLDrawPath(pathColor: self.currentDrawColor, pathWidth: self.drawLineWidth / self.scrollView.zoomScale, ratio: ratio / originalRatio / toImageScale, startPoint: point)
                self.drawPaths.append(path)
            } else if pan.state == .changed {
                let path = self.drawPaths.last
                path?.addLine(to: point)
                self.drawLine()
            } else if pan.state == .cancelled || pan.state == .ended {
                self.setToolView(show: true)
                self.revokeBtn.isEnabled = self.drawPaths.count > 0
            }
        } else if self.selectedTool == .mosaic {
            let point = pan.location(in: self.imageView)
            if pan.state == .began {
                self.setToolView(show: false)
                
                var actualSize = self.editRect.size
                if self.angle == -90 || self.angle == -270 {
                    swap(&actualSize.width, &actualSize.height)
                }
                let ratio = min(self.scrollView.frame.width / self.editRect.width, self.scrollView.frame.height / self.editRect.height)
                
                let pathW = self.mosaicLineWidth / self.scrollView.zoomScale
                let path = ZLMosaicPath(pathWidth: pathW, ratio: ratio, startPoint: point)
                
                self.mosaicImageLayerMaskLayer?.lineWidth = pathW
                self.mosaicImageLayerMaskLayer?.path = path.path.cgPath
                self.mosaicPaths.append(path)
            } else if pan.state == .changed {
                let path = self.mosaicPaths.last
                path?.addLine(to: point)
                self.mosaicImageLayerMaskLayer?.path = path?.path.cgPath
            } else if pan.state == .cancelled || pan.state == .ended {
                self.setToolView(show: true)
                self.revokeBtn.isEnabled = self.mosaicPaths.count > 0
                self.generateNewMosaicImage()
            }
        }
    }
    
    // 生成一个没有调整参数前的图片
    func generateAdjustImageRef() {
        editImageAdjustRef = generateNewMosaicImage(inputImage: editImageWithoutAdjust, inputMosaicImage: editImageWithoutAdjust.mosaicImage())
    }
    
    func adjustValueChanged(_ value: Float) {
        guard let selectedAdjustTool = selectedAdjustTool, let editImageAdjustRef = editImageAdjustRef else {
            return
        }
        var resultImage: UIImage? = nil
        
        switch selectedAdjustTool {
        case .brightness:
            if brightness == value {
                return
            }
            brightness = value
            resultImage = editImageAdjustRef.adjust(brightness: value, contrast: contrast, saturation: saturation)
        case .contrast:
            if contrast == value {
                return
            }
            contrast = value
            resultImage = editImageAdjustRef.adjust(brightness: brightness, contrast: value, saturation: saturation)
        case .saturation:
            if saturation == value {
                return
            }
            saturation = value
            resultImage = editImageAdjustRef.adjust(brightness: brightness, contrast: contrast, saturation: value)
        }
        
        guard let resultImage = resultImage else {
            return
        }
        editImage = resultImage
        imageView.image = editImage
    }
    
    func endAdjust() {
        if tools.contains(.mosaic) {
            generateNewMosaicImageLayer()
            
            if !mosaicPaths.isEmpty {
                generateNewMosaicImage()
            }
        }
    }
    
    func setToolView(show: Bool) {
        topShadowView.layer.removeAllAnimations()
        bottomShadowView.layer.removeAllAnimations()
        adjustSlider?.layer.removeAllAnimations()
        if show {
            UIView.animate(withDuration: 0.25) {
                self.topShadowView.alpha = 1
                self.bottomShadowView.alpha = 1
                self.adjustSlider?.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.topShadowView.alpha = 0
                self.bottomShadowView.alpha = 0
                self.adjustSlider?.alpha = 0
            }
        }
    }
    
    func showInputTextVC(_ text: String? = nil,
                         textColor: String? = nil,
                         bgColor: String? = nil,
                         completion: @escaping ( (String, String, String?) -> Void )) {
        // Calculate image displayed frame on the screen.
        var r = self.scrollView.convert(self.view.frame, to: self.containerView)
        r.origin.x += self.scrollView.contentOffset.x / self.scrollView.zoomScale
        r.origin.y += self.scrollView.contentOffset.y / self.scrollView.zoomScale
        let scale = self.backgroundimageSize.width / self.imageView.frame.width
        r.origin.x *= scale
        r.origin.y *= scale
        r.size.width *= scale
        r.size.height *= scale
     //   let bgImage = self.buildImage().clipImage(self.angle, self.editRect)?.clipImage(0, r)
        let vc = ZLInputTextViewController(image: nil,
                                           text: text,
                                           textColor: textColor,
                                           bgColor: bgColor,
                                           allowCustomColor: self.allowCustomColor)
        
        vc.endInput = { [weak self] (text, textColor, bgColor)  in
            completion(text, textColor, bgColor)
            self?.topShadowView.isHidden = false
            self?.configColors()
        }
        
        vc.modalPresentationStyle = .custom
        vc.modalTransitionStyle = .crossDissolve
        vc.view.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        topShadowView.isHidden = true
        
        self.present(vc, animated: true)
    }
    
    func getStickerOriginFrame(_ size: CGSize) -> CGRect {
        let scale = self.scrollView.zoomScale
        // Calculate the display rect of container view.
        let x = (self.scrollView.contentOffset.x - self.containerView.frame.minX) / scale
        let y = (self.scrollView.contentOffset.y - self.containerView.frame.minY) / scale
        let w = view.frame.width / scale
        let h = view.frame.height / scale
        // Convert to text stickers container view.
        let r = self.containerView.convert(CGRect(x: x, y: y, width: w, height: h), to: self.stickersContainer)
        let originFrame = CGRect(x: r.minX + (r.width - size.width) / 2, y: r.minY + (r.height - size.height) / 2, width: size.width, height: size.height)
        return originFrame
    }
    
    /// Add image sticker
    func addImageStickerView(_ data: ImageStickerData) {
        let scale = self.scrollView.zoomScale
        let size = ZLImageStickerView.calculateSize(image: data.image, width: self.view.frame.width)
        let originFrame = self.getStickerOriginFrame(size)
        
        let imageSticker = ZLImageStickerView(image: data, originScale: 1 / scale, originAngle: -self.angle, originFrame: originFrame)
        self.stickersContainer.addSubview(imageSticker)
        imageSticker.frame = originFrame
        self.view.layoutIfNeeded()
        
        self.configImageSticker(imageSticker)
        self.configColors()
    }
    
    /// Add text sticker
    func addTextStickersView(_ text: String, textColor: String, bgColor: String?) {
        guard !text.isEmpty else { return }
        let scale = self.scrollView.zoomScale
        let size = ZLTextStickerView.calculateSize(text: text, width: self.view.frame.width)
        let originFrame = self.getStickerOriginFrame(size)
        
        let textSticker = ZLTextStickerView(text: text, textColor: textColor, bgColor: bgColor, originScale: 1 / scale, originAngle: -self.angle, originFrame: originFrame)
        self.stickersContainer.addSubview(textSticker)
        textSticker.frame = originFrame
        
        self.configTextSticker(textSticker)
    }
    
    func configTextSticker(_ textSticker: ZLTextStickerView) {
        textSticker.delegate = self
        self.scrollView.pinchGestureRecognizer?.require(toFail: textSticker.pinchGes)
        self.scrollView.panGestureRecognizer.require(toFail: textSticker.panGes)
        self.panGes.require(toFail: textSticker.panGes)
    }
    
    func configImageSticker(_ imageSticker: ZLImageStickerView) {
        imageSticker.delegate = self
        self.scrollView.pinchGestureRecognizer?.require(toFail: imageSticker.pinchGes)
        self.scrollView.panGestureRecognizer.require(toFail: imageSticker.panGes)
        self.panGes.require(toFail: imageSticker.panGes)
    }
    
    func reCalculateStickersFrame(_ oldSize: CGSize, _ oldAngle: CGFloat, _ newAngle: CGFloat) {
        let currSize = self.stickersContainer.frame.size
        let scale: CGFloat
        if Int(newAngle - oldAngle) % 180 == 0{
            scale = currSize.width / oldSize.width
        } else {
            scale = currSize.height / oldSize.width
        }
        
        self.stickersContainer.subviews.forEach { (view) in
            (view as? ZLStickerViewAdditional)?.addScale(scale)
        }
    }
    
    func drawLine() {
        let originalRatio = min(self.scrollView.frame.width / self.originalImage.size.width, self.scrollView.frame.height / self.originalImage.size.height)
        let ratio = min(self.scrollView.frame.width / self.editRect.width, self.scrollView.frame.height / self.editRect.height)
        let scale = ratio / originalRatio
        // Zoom to original size
        var size = self.drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if self.angle == -90 || self.angle == -270 {
            swap(&size.width, &size.height)
        }
        var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
        if self.editImage.size.width / self.editImage.size.height > 1 {
            toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
        }
        size.width *= toImageScale
        size.height *= toImageScale
        
        UIGraphicsBeginImageContextWithOptions(size, false, self.editImage.scale)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setAllowsAntialiasing(true)
        context?.setShouldAntialias(true)
        for path in self.drawPaths {
            path.drawPath()
        }
        self.drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    func generateNewMosaicImageLayer() {
        mosaicImage = editImage.mosaicImage()
        
        mosaicImageLayer?.removeFromSuperlayer()
        
        mosaicImageLayer = CALayer()
        mosaicImageLayer?.frame = imageView.bounds
        mosaicImageLayer?.contents = mosaicImage?.cgImage
        imageView.layer.insertSublayer(mosaicImageLayer!, below: mosaicImageLayerMaskLayer)
        
        mosaicImageLayer?.mask = mosaicImageLayerMaskLayer
    }
    
    /// 传入inputImage 和 inputMosaicImage则代表仅想要获取新生成的mosaic图片
    @discardableResult
    func generateNewMosaicImage(inputImage: UIImage? = nil, inputMosaicImage: UIImage? = nil) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
        if inputImage != nil {
            inputImage?.draw(at: .zero)
        } else {
            var drawImage: UIImage? = nil
            if tools.contains(.filter), let image = filterImages[currentFilter.name] {
                drawImage = image
            } else {
                drawImage = originalImage
            }
            drawImage = drawImage?.adjust(brightness: brightness, contrast: contrast, saturation: saturation)
            drawImage?.draw(at: .zero)
        }
        let context = UIGraphicsGetCurrentContext()
        
        self.mosaicPaths.forEach { (path) in
            context?.move(to: path.startPoint)
            path.linePoints.forEach { (point) in
                context?.addLine(to: point)
            }
            context?.setLineWidth(path.path.lineWidth / path.ratio)
            context?.setLineCap(.round)
            context?.setLineJoin(.round)
            context?.setBlendMode(.clear)
            context?.strokePath()
        }
        
        var midImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let midCgImage = midImage?.cgImage else {
            return nil
        }
        
        midImage = UIImage(cgImage: midCgImage, scale: editImage.scale, orientation: .up)
        
        UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
        (inputMosaicImage ?? mosaicImage)?.draw(at: .zero)
        midImage?.draw(at: .zero)
        
        let temp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgi = temp?.cgImage else {
            return nil
        }
        let image = UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
        
        if inputImage != nil {
            return image
        }
        
        editImage = image
        imageView.image = image
        mosaicImageLayerMaskLayer?.path = nil
        
        return image
    }
    
    func buildImage() -> UIImage {
        return UIImage(view: containerView) ?? .init()
    }
    
    func finishClipDismissAnimate() {
        self.scrollView.alpha = 1
        UIView.animate(withDuration: 0.1) {
            self.topShadowView.alpha = 1
            self.bottomShadowView.alpha = 1
            self.adjustSlider?.alpha = 1
        }
    }

    func configColors() {
        stickersContainer.isHidden = true
        editImage = buildImage()
        stickersContainer.isHidden = false

        ZLImageEditorConfiguration.default().colorsDataSource?.getTextColors(editImage: buildImage(), { colors in
            ZLImageEditorConfiguration.default().textStickerTextColors = colors
        })
        
        ZLImageEditorConfiguration.default().colorsDataSource?.getBackgroundColors(editImage: buildImage(), { colors in
            ZLImageEditorConfiguration.default().imageBackgroundColors = colors
            self.backgroundColors = colors
        })
    }
}

extension UIImage {

    convenience init?(view: UIView?, shouldCornerRadius: Bool = false) {
        guard let view: UIView = view else { return nil }

        if shouldCornerRadius {
            view.layer.cornerRadius = 20
            view.clipsToBounds = true
        }
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        guard let context: CGContext = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        view.layer.render(in: context)
        let contextImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard
            let image: UIImage = contextImage,
            let pngData: Data = image.pngData()
            else { return nil }

        self.init(data: pngData)
    }

    
}

extension ZLEditImageViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard self.imageStickerContainerIsHidden else {
            return false
        }
        if gestureRecognizer is UITapGestureRecognizer {
            if self.bottomShadowView.alpha == 1 {
                let p = gestureRecognizer.location(in: self.view)
                return !self.bottomShadowView.frame.contains(p)
            } else {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            guard let st = self.selectedTool else {
                return false
            }
            return (st == .draw || st == .mosaic) && !self.isScrolling
        }
        
        return true
    }
    
}


// MARK: scroll view delegate
extension ZLEditImageViewController: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return nil
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        self.containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.isScrolling = false
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }
        self.isScrolling = true
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == self.scrollView else {
            return
        }
        self.isScrolling = decelerate
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }
        self.isScrolling = false
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else {
            return
        }
        self.isScrolling = false
    }
    
}


extension ZLEditImageViewController: UICollectionViewDataSource,
                                     UICollectionViewDelegate,
                                     UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == editToolCollectionView {
            return tools.count
        } else if collectionView == drawColorCollectionView {
            return drawColors.count
        } else if collectionView == filterCollectionView {
            return thumbnailFilterImages.count
        } else if collectionView == textColorsCollectionView {
            return backgroundColors.count
        } else {
            return adjustTools.count
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == editToolCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLEditToolCell.zl_identifier(), for: indexPath) as! ZLEditToolCell
            
            let toolType = tools[indexPath.row]
            cell.icon.isHighlighted = false
            cell.toolType = toolType
            cell.icon.isHighlighted = toolType == selectedTool
            cell.icon.tintColor = .white
            cell.icon.contentMode = .scaleAspectFit
            
            return cell
        } else if collectionView == drawColorCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLDrawColorCell.zl_identifier(), for: indexPath) as! ZLDrawColorCell
            
            let c = drawColors[indexPath.row]
            cell.color = c
            if c == currentDrawColor {
        //        cell.bgWhiteView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1)
            } else {
         //       cell.bgWhiteView.layer.transform = CATransform3DIdentity
            }
            
            return cell
        } else if collectionView == textColorsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLDrawColorCell.zl_identifier(), for: indexPath) as! ZLDrawColorCell
            
            let c = backgroundColors[indexPath.row]
                cell.color = c
//            if c == currentDrawColor {
//                cell.bgWhiteView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1)
//            } else {
//                cell.bgWhiteView.layer.transform = CATransform3DIdentity
//            }
            //                cell.bgWhiteView.layer.transform = CATransform3DIdentity

            return cell
        }  else if collectionView == filterCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLFilterImageCell.zl_identifier(), for: indexPath) as! ZLFilterImageCell
            
            let image = thumbnailFilterImages[indexPath.row]
            let filter = ZLImageEditorConfiguration.default().filters[indexPath.row]
            
            cell.nameLabel.text = filter.name
            cell.imageView.image = image
            
            if currentFilter === filter {
                cell.nameLabel.textColor = .white
            } else {
                cell.nameLabel.textColor = zlRGB(160, 160, 160)
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLAdjustToolCell.zl_identifier(), for: indexPath) as! ZLAdjustToolCell
            
            let tool = adjustTools[indexPath.row]
            
            cell.imageView.isHighlighted = false
            cell.adjustTool = tool
            let isSelected = tool == selectedAdjustTool
            cell.imageView.isHighlighted = isSelected
            
            if isSelected {
                cell.nameLabel.textColor = .white
            } else {
                cell.nameLabel.textColor = zlRGB(160, 160, 160)
            }
            
            return cell
        }
    }
    
    fileprivate func setStyleForImageBorder() {
        if currentBackgroundColor == .clear {
            dumyViewBorder.layer.borderColor = UIColor.white.cgColor
        } else {
            dumyViewBorder.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == editToolCollectionView {
            let toolType = tools[indexPath.row]
            switch toolType {
            case .draw:
                drawBtnClick()
            case .clip:
                clipBtnClick()
            case .imageSticker:
                imageStickerBtnClick()
            case .textSticker:
                textStickerBtnClick()
            case .mosaic:
                mosaicBtnClick()
            case .filter:
                filterBtnClick()
            case .adjust:
                adjustBtnClick()
                break
            case .imagePicker:
                imagePickerBtnClick()
            case .colorPicker:
                if let index = backgroundColors.firstIndex(of: currentBackgroundColor) {
                    if backgroundColors.indices.contains(index+1) {
                        currentBackgroundColor = backgroundColors[index+1]
                    } else {
                        currentBackgroundColor = backgroundColors.first!
                    }
                } else {
                    currentBackgroundColor = backgroundColors.first!
                }
                
                imageView.backgroundColor = currentBackgroundColor
                imageView.image = nil
                backgroundImage = nil
                setStyleForImageBorder()
                
                if let image = UIImage(view: self.imageView) {
                    editImage = image
                    backgroundImage = image
                }
                
                
            }
        } else if collectionView == drawColorCollectionView {
            currentDrawColor = drawColors[indexPath.row]
        }else if collectionView == textColorsCollectionView {
            print("collectionView-> dd")
        } else if collectionView == filterCollectionView {
            currentFilter = ZLImageEditorConfiguration.default().filters[indexPath.row]
            if let image = filterImages[currentFilter.name] {
                editImage = image.adjust(brightness: brightness, contrast: contrast, saturation: saturation) ?? image
                editImageWithoutAdjust = image
            } else {
                let image = currentFilter.applier?(originalImage) ?? originalImage
                editImage = image.adjust(brightness: brightness, contrast: contrast, saturation: saturation) ?? image
                editImageWithoutAdjust = image
                filterImages[currentFilter.name] = image
            }
            if self.tools.contains(.mosaic) {
                generateNewMosaicImageLayer()
                
                if mosaicPaths.isEmpty {
                    imageView.image = editImage
                } else {
                    generateNewMosaicImage()
                }
            } else {
                imageView.image = editImage
            }
        } else {
            let tool = adjustTools[indexPath.row]
            if tool != selectedAdjustTool {
                changeAdjustTool(tool)
            }
        }
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == textColorsCollectionView {
            let totalCellWidth = Int(40) * backgroundColors.count
            let totalSpacingWidth = 0
            if totalCellWidth < Int(collectionView.frame.width){
                let leftInset = (collectionView.frame.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
                let rightInset = leftInset
                return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
            }
            return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        }
        
        return .zero
      
    }
}

extension ZLEditImageViewController: UIImagePickerControllerDelegate,
                                     UINavigationControllerDelegate {
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            guard let image = info[.originalImage] as? UIImage else { return }
            self.imageView.image = image
            self.imageView.contentMode = .redraw
            self.backgroundImage = UIImage(view: self.imageView) ?? image
            self.imageView.image = self.backgroundImage
            self.configColors()
        }
    }
    
}

extension ZLEditImageViewController: ZLTextStickerViewDelegate {
    
    func stickerBeginOperation(_ sticker: UIView) {
        self.setToolView(show: false)
        self.ashbinView.layer.removeAllAnimations()
        self.ashbinView.isHidden = false
        var frame = self.ashbinView.frame
        let diff = self.view.frame.height - frame.minY
        frame.origin.y += diff
        self.ashbinView.frame = frame
        frame.origin.y -= diff
        UIView.animate(withDuration: 0.25) {
            self.ashbinView.frame = frame
        }
        
        self.stickersContainer.subviews.forEach { (view) in
            if view !== sticker {
                (view as? ZLStickerViewAdditional)?.resetState()
                (view as? ZLStickerViewAdditional)?.gesIsEnabled = false
            }
        }
    }
    
    func stickerOnOperation(_ sticker: UIView, panGes: UIPanGestureRecognizer) {
        let point = panGes.location(in: self.view)
        if self.ashbinView.frame.contains(point) {
            self.ashbinView.backgroundColor = zlRGB(241, 79, 79).withAlphaComponent(0.98)
            self.ashbinImgView.isHighlighted = true
            if sticker.alpha == 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) {
                    sticker.alpha = 0.5
                }
            }
        } else {
            self.ashbinView.backgroundColor = ZLEditImageViewController.ashbinNormalBgColor
            self.ashbinImgView.isHighlighted = false
            if sticker.alpha != 1 {
                sticker.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.25) {
                    sticker.alpha = 1
                }
            }
        }
    }
    
    func stickerEndOperation(_ sticker: UIView, panGes: UIPanGestureRecognizer) {
        self.setToolView(show: true)
        self.ashbinView.layer.removeAllAnimations()
        self.ashbinView.isHidden = true
        
        let point = panGes.location(in: self.view)
        if self.ashbinView.frame.contains(point) {
            (sticker as? ZLStickerViewAdditional)?.moveToAshbin()
        }
        
        self.stickersContainer.subviews.forEach { (view) in
            (view as? ZLStickerViewAdditional)?.gesIsEnabled = true
        }
        
        self.stickersContainer.subviews.forEach { (view) in
            if view is ZLTextStickerView {
                (view as? ZLTextStickerView)?.bringToFront()
            }
        }
        
        self.textColorsCollectionView.isHidden = true
    }
    
    func stickerDidTap(_ sticker: UIView) {
        self.stickersContainer.subviews.forEach { (view) in
            if view !== sticker {
                (view as? ZLStickerViewAdditional)?.resetState()
            }
        }

        self.textColorsCollectionView.isHidden = !(sticker is ZLTextStickerView)

    }
    
    func sticker(_ textSticker: ZLTextStickerView, editText text: String) {
        self.showInputTextVC(text,
                             textColor: textSticker.textColor,
                             bgColor: textSticker.bgColor?.toHexString()) { [weak self] (text, textColor, bgColor) in
            guard let `self` = self else { return }
            if text.isEmpty {
                textSticker.moveToAshbin()
            } else {
                textSticker.startTimer()
                guard textSticker.text != text || textSticker.textColor != textColor || textSticker.bgColor?.toHexString() != bgColor else {
                    return
                }
                textSticker.text = text
                textSticker.textColor = textColor
                textSticker.bgColor = bgColor?.colorWithHexString()
                let newSize = ZLTextStickerView.calculateSize(text: text, width: self.view.frame.width)
                textSticker.changeSize(to: newSize)
            }
        }
    }
    
    func showActivityIndicator() {
        self.view.viewWithTag(5)?.removeFromSuperview()
        self.stickersContainer.isHidden = true
        self.imageView.isHidden = true
        
        activityView = UIActivityIndicatorView(style: .large)
        activityView?.center = self.view.center
        activityView?.hidesWhenStopped = true
        activityView?.tag = 5
        self.view.addSubview(activityView!)
        activityView?.startAnimating()
    }

    func hideActivityIndicator(){
        self.stickersContainer.isHidden = false
        self.imageView.isHidden = false

        self.view.viewWithTag(5)?.removeFromSuperview()
        if (activityView != nil){
            activityView?.stopAnimating()
        }
    }
    
}

// MARK: Draw path
public class ZLDrawPath: NSObject {
    
    let pathColor: UIColor
    
    let path: UIBezierPath
    
    let ratio: CGFloat
    
    let shapeLayer: CAShapeLayer
    
    init(pathColor: UIColor, pathWidth: CGFloat, ratio: CGFloat, startPoint: CGPoint) {
        self.pathColor = pathColor
        self.path = UIBezierPath()
        self.path.lineWidth = pathWidth / ratio
        self.path.lineCapStyle = .round
        self.path.lineJoinStyle = .round
        self.path.move(to: CGPoint(x: startPoint.x / ratio, y: startPoint.y / ratio))
        
        self.shapeLayer = CAShapeLayer()
        self.shapeLayer.lineCap = .round
        self.shapeLayer.lineJoin = .round
        self.shapeLayer.lineWidth = pathWidth / ratio
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.strokeColor = pathColor.cgColor
        self.shapeLayer.path = self.path.cgPath
        
        self.ratio = ratio
        
        super.init()
    }
    
    func addLine(to point: CGPoint) {
        self.path.addLine(to: CGPoint(x: point.x / self.ratio, y: point.y / self.ratio))
        self.shapeLayer.path = self.path.cgPath
    }
    
    func drawPath() {
        self.pathColor.set()
        self.path.stroke()
    }
    
}


// MARK: Mosaic path

public class ZLMosaicPath: NSObject {
    
    let path: UIBezierPath
    
    let ratio: CGFloat
    
    let startPoint: CGPoint
    
    var linePoints: [CGPoint] = []
    
    init(pathWidth: CGFloat, ratio: CGFloat, startPoint: CGPoint) {
        self.path = UIBezierPath()
        self.path.lineWidth = pathWidth
        self.path.lineCapStyle = .round
        self.path.lineJoinStyle = .round
        self.path.move(to: startPoint)
        
        self.ratio = ratio
        self.startPoint = CGPoint(x: startPoint.x / ratio, y: startPoint.y / ratio)
        
        super.init()
    }
    
    func addLine(to point: CGPoint) {
        self.path.addLine(to: point)
        self.linePoints.append(CGPoint(x: point.x / self.ratio, y: point.y / self.ratio))
    }
}
