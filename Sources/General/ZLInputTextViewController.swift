//
//  ZLInputTextViewController.swift
//  ZLImageEditor
//
//  Created by long on 2020/10/30.
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

class ZLInputTextViewController: UIViewController,
                                 UIGestureRecognizerDelegate, UIColorPickerViewControllerDelegate {

    static let collectionViewHeight: CGFloat = 50
    
    let image: UIImage?
    
    var text: String
    
    var cancelBtn: UIButton!
    
    var doneBtn: UIButton!
    
    var textView: UITextView!
    
    var collectionView: UICollectionView!
    
    var currentTextColor: UIColor
    
    
    var allowCustomColor: Bool

    /// text, textColor, bgColor
    var endInput: ( (String, String, String?) -> Void )?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    lazy var tap = UITapGestureRecognizer(target: self, action: #selector(cancelBtnClick))

    init(image: UIImage?,
         text: String? = nil,
         textColor: String? = nil,
         bgColor: String? = nil,
         allowCustomColor: Bool) {
        
        self.allowCustomColor = allowCustomColor
        
        self.image = image
        self.text = text ?? ""
        if let textColor = textColor {
            self.currentTextColor = textColor.colorWithHexString()
        } else {
            if !ZLImageEditorConfiguration.default().textStickerTextColors.contains(ZLImageEditorConfiguration.default().textStickerDefaultTextColor) {
                self.currentTextColor = ZLImageEditorConfiguration.default().textStickerTextColors.first!
            } else {
                self.currentTextColor = ZLImageEditorConfiguration.default().textStickerDefaultTextColor
            }
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIApplication.keyboardWillShowNotification,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.textView.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    
        
        let btnY = UIScreen.main.heightOfSafeArea()
        let cancelBtnW = localLanguageTextValue(.cancel).boundingRect(font: ZLImageEditorConfiguration.default().zlImageEditorFont.bottomToolTitleFont, limitSize: CGSize(width: .greatestFiniteMagnitude, height: ZLImageEditorLayout.bottomToolBtnH)).width + 20
        self.cancelBtn.frame = CGRect(x: 30, y: btnY, width: cancelBtnW, height: ZLImageEditorLayout.bottomToolBtnH)
        
        let doneBtnW = localLanguageTextValue(.done).boundingRect(font: ZLImageEditorConfiguration.default().zlImageEditorFont.bottomToolTitleFont, limitSize: CGSize(width: .greatestFiniteMagnitude, height: ZLImageEditorLayout.bottomToolBtnH)).width + 20
        self.doneBtn.frame = CGRect(x: view.bounds.width - 30 - doneBtnW, y: btnY, width: doneBtnW, height: ZLImageEditorLayout.bottomToolBtnH)
        
        self.textView.frame = CGRect(x: 20,
                                     y: cancelBtn.frame.maxY + 20,
                                     width: view.bounds.width,
                                     height: 150)
        
        self.textView.center = self.view.center
        
        if let index = ZLImageEditorConfiguration.default().textStickerTextColors.firstIndex(where: { $0 == self.currentTextColor}) {
            self.collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    func setupUI() {
        self.view.backgroundColor = .black
        
        let bgImageView = UIImageView(image: image?.blurImage(level: 4))
        bgImageView.frame = self.view.bounds
        bgImageView.contentMode = .scaleAspectFit
        self.view.addSubview(bgImageView)
        
        let coverView = UIView(frame: bgImageView.bounds)
        coverView.backgroundColor = .black
        coverView.alpha = 0.4
        bgImageView.addSubview(coverView)
        
        self.cancelBtn = UIButton(type: .custom)
        self.cancelBtn.setTitle(localLanguageTextValue(.cancel), for: .normal)
        self.cancelBtn.titleLabel?.font = ZLImageEditorConfiguration.default().zlImageEditorFont.bottomToolTitleFont
        self.cancelBtn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        view.addSubview(self.cancelBtn)
        self.cancelBtn.isHidden = true

        self.doneBtn = UIButton(type: .custom)
        self.doneBtn.setTitle(localLanguageTextValue(.done), for: .normal)
        self.doneBtn.titleLabel?.font = ZLImageEditorConfiguration.default().zlImageEditorFont.bottomToolTitleFont
        self.doneBtn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        view.addSubview(self.doneBtn)
        self.textView = UITextView(frame: .zero)
        self.textView.keyboardAppearance = .dark
        self.textView.returnKeyType = .default
        self.textView.delegate = self
        self.textView.backgroundColor = .clear
        self.textView.tintColor = ZLImageEditorConfiguration.default().editDoneBtnBgColor
        self.textView.textColor = self.currentTextColor
        self.textView.tintColor = self.currentTextColor
        self.textView.text = self.text
        self.textView.font = ZLImageEditorConfiguration.default().zlImageEditorFont.textFont
        view.addSubview(self.textView)
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.minimumLineSpacing = 15
        layout.minimumInteritemSpacing = 15
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        self.collectionView = UICollectionView(frame: CGRect(x: 0, y: self.view.frame.height - ZLInputTextViewController.collectionViewHeight, width: self.view.frame.width, height: ZLInputTextViewController.collectionViewHeight), collectionViewLayout: layout)
        self.collectionView.backgroundColor = .clear
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.showsHorizontalScrollIndicator = false
        self.view.addSubview(self.collectionView)
        
        ZLDrawColorCell.zl_register(self.collectionView)
        self.view.addGestureRecognizer(tap)
        tap.delegate = self
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
             shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
       if gestureRecognizer == self.tap &&
            otherGestureRecognizer == self.collectionView.panGestureRecognizer {
           self.tap.isEnabled = false
          return true
       }
        self.tap.isEnabled = true
       return false
    }
        
    @objc func cancelBtnClick() {
        self.tap.isEnabled = true
        self.endInput?(self.textView.text,
                       self.currentTextColor.toHexString(), nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneBtnClick() {
        self.tap.isEnabled = true
        self.endInput?(self.textView.text,
                       self.currentTextColor.toHexString(),
                       nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(_ notify: Notification) {
        let rect = notify.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect
        let keyboardH = rect?.height ?? 366
        let duration: TimeInterval = notify.userInfo?[UIApplication.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        
        UIView.animate(withDuration: max(duration, 0.25)) {
            self.collectionView.frame = CGRect(x: 0, y: self.view.frame.height - keyboardH - ZLInputTextViewController.collectionViewHeight, width: self.view.frame.width, height: ZLInputTextViewController.collectionViewHeight)
        }
    }
    
}


extension ZLInputTextViewController: UICollectionViewDelegate,
                                     UICollectionViewDataSource,
                                     UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ZLImageEditorConfiguration.default().textStickerTextColors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLDrawColorCell.zl_identifier(), for: indexPath) as! ZLDrawColorCell
        
        let c = ZLImageEditorConfiguration.default().textStickerTextColors[indexPath.row]
        cell.color = c
 
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.currentTextColor = ZLImageEditorConfiguration.default().textStickerTextColors[indexPath.row]
        self.textView.textColor = self.currentTextColor
        self.textView.tintColor =  self.currentTextColor
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        collectionView.reloadData()
        
        if indexPath.item == 0 && allowCustomColor {
            presentColorPicker()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let totalCellWidth = Int(40) * ZLImageEditorConfiguration.default().textStickerTextColors.count
        let totalSpacingWidth = 0
        if totalCellWidth < Int(collectionView.frame.width){
            let leftInset = (collectionView.frame.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
            let rightInset = leftInset
            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        }
        return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    }
    
    
    func presentColorPicker() {
        // Initializing Color Picker
        if #available(iOS 14.0, *) {
            let picker = UIColorPickerViewController()
            picker.selectedColor = currentTextColor
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    
}


extension ZLInputTextViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        if text == "\n" {
//            self.doneBtnClick()
//            return false
//        }
        textView.sizeToFit()
        return true
    }
    
}

@available(iOS 14.0, *)
extension ZLInputTextViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        ZLImageEditorConfiguration.default().textStickerTextColors[0] = viewController.selectedColor
        collectionView.reloadData()
        self.currentTextColor = viewController.selectedColor
        self.textView.textColor = self.currentTextColor
        self.textView.tintColor =  self.currentTextColor
    }
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        ZLImageEditorConfiguration.default().textStickerTextColors[0] = viewController.selectedColor
        collectionView.reloadData()
        self.currentTextColor = viewController.selectedColor
        self.textView.textColor = self.currentTextColor
        self.textView.tintColor =  self.currentTextColor
    }
}
