//
//  ZLEditImageModel.swift
//  ZLImageEditor
//
//  Created by Khalid S Almalki on 3/28/22.
//

import UIKit

public class ZLEditImageModel: NSObject {
    
    public let drawPaths: [ZLDrawPath]
    
    public let mosaicPaths: [ZLMosaicPath]
    
    public let editRect: CGRect?
    
    public let angle: CGFloat
    
    public let brightness: Float
    
    public let contrast: Float
    
    public let saturation: Float
    
    public let selectRatio: ZLImageClipRatio?
    public let selectFilter: ZLFilter?
    
    public let textStickers: [ZLTextStickerState]?
    public let imageStickers: [ZLImageStickerState]?
    
    public init(
        drawPaths: [ZLDrawPath],
        mosaicPaths: [ZLMosaicPath],
        editRect: CGRect?,
        angle: CGFloat,
        brightness: Float,
        contrast: Float,
        saturation: Float,
        selectRatio: ZLImageClipRatio?,
        selectFilter: ZLFilter,
        textStickers: [ZLTextStickerState]?,
        imageStickers: [ZLImageStickerState]?
    ) {
        self.drawPaths = drawPaths
        self.mosaicPaths = mosaicPaths
        self.editRect = editRect
        self.angle = angle
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.selectRatio = selectRatio
        self.selectFilter = selectFilter
        self.textStickers = textStickers
        self.imageStickers = imageStickers
        super.init()
    }
    
}
