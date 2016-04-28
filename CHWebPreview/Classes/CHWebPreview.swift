//
//  CHWebPreview.swift
//  CHWebPreviewDemo
//
//  Created by nya on 4/28/16.
//  Copyright © 2016 CatHand. All rights reserved.
//

import Foundation

public class WebpageInfo {
    
    public var url: String?
    public var title: String?
    public var desc: String?
    public var images = [WebpageImage]()
    public var origin: NSURL?
    
    public var image: WebpageImage? {
        return images.sort({ $0.value < $1.value }).last
    }
}

public class WebpageImage {
    
    public var url: String
    public var width: Int?
    public var height: Int?
    
    init(url: String) {
        self.url = url
    }
    
    var value: Int {
        return (width ?? 1) * (height ?? 1)
    }
}

public struct CHWebPreview {
    
    public static func load(url: NSURL, handler: (WebpageInfo, NSError?) -> Void) {
        WebPreviewParser.load(url, handler: handler)
    }
}
