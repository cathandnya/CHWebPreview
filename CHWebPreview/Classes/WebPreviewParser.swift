//
//  WebPreviewParser.swift
//  ORE2
//
//  Created by nya on 2/27/16.
//  Copyright © 2016 cathand.org. All rights reserved.
//

import Foundation

class WebPreviewParser: CHHtmlParser, NSURLSessionDataDelegate {
    
    var baseUrl: NSURL!
    var finishedHandler: ((WebpageInfo, NSError?) -> Void)?
    private var webInfo = WebpageInfo()
    private var finished = false
    private var inHead = false
    private var characterBuffer: NSMutableData?
    private var dataBuffer = NSMutableData()
    private var charset: NSStringEncoding
    
    override init() {
        charset = NSUTF8StringEncoding
        super.init(encoding: charset)
    }
    
    override func startElementName(name: String!, attributes: [NSObject : AnyObject]!) {
        let name = name.lowercaseString
        func getValue(key: String) -> String? {
            return (attributes[key] as? String)
        }

        if name == "meta" {
            if getValue("http-equiv")?.lowercaseString == "content-type" {
                if let content = getValue("content")?.lowercaseString, start = content.rangeOfString("charset=")?.endIndex {
                    let set = content.substringFromIndex(start)
                    var enc = encoding()
                    if set == "shift_jis" {
                        enc = NSShiftJISStringEncoding
                    } else if set == "euc-jp" {
                        enc = NSJapaneseEUCStringEncoding
                    } else if set == "iso-2022-jp" {
                        enc = NSISO2022JPStringEncoding
                    } else if set == "utf-8" {
                        enc = NSUTF8StringEncoding
                    }
                    charset = enc
                }
            }
        }
        
        if name == "head" {
            inHead = true
        }
        if inHead {
            
            if name == "meta" {
                if let property = getValue("property")?.lowercaseString, content = getValue("content") {
                    if property == "og:title" {
                        webInfo.title = content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    } else if property == "og:description" {
                        webInfo.desc = content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    } else if webInfo.desc == nil && property == "description" {
                        webInfo.desc = content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    } else if property.hasPrefix("og:image") {
                        if property == "og:image" || property == "og:image:url" {
                            var url = content
                            while url.rangeOfString("/../") != nil {
                                url = url.stringByReplacingOccurrencesOfString("/../", withString: "/")
                            }
                            if !url.hasPrefix("https://") && !url.hasPrefix("http://") {
                                url = baseUrl.URLByAppendingPathComponent(url).absoluteString
                            }
                            webInfo.images.append(WebpageImage(url: url))
                        } else if property == "og:image:width" {
                            if let val = Int(content) {
                                webInfo.images.last?.width = val
                            }
                        } else if property == "og:image:height" {
                            if let val = Int(content) {
                                webInfo.images.last?.height = val
                            }
                        }
                    } else if property == "og:type" && content == "metadata" {
                        
                    }
                } else if let name = getValue("name")?.lowercaseString, content = getValue("content") {
                    if webInfo.desc == nil && name == "description" {
                        webInfo.desc = content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    }
                }
            } else if name == "title" {
                if webInfo.title == nil {
                    characterBuffer = NSMutableData()
                }
            } else if name == "link" && getValue("rel")?.lowercaseString == "origin" {
                if let href = getValue("href") {
                    webInfo.origin = NSURL(string: href)
                }
            }
        }
    }
    
    override func endElementName(name: String!) {
        if name == "head" {
            inHead = false
            finished = true
        }
        if inHead {
            if name == "title" {
                /*
                if webInfo.title == nil {
                    if let data = characterBuffer, str = String(data: data, encoding: encoding()) {
                        //webInfo.title = str.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    }
                }
                 */
                characterBuffer = nil
            }
        }
    }
    
    override func characters(ch: UnsafePointer<UInt8>, length len: Int32) {
        /*
        for i in 0 ..< Int(len) {
            print(String(format: "%%%02X", Int(ch[i])), terminator: "")
        }
        print("\ncharacters: \(String(data: NSData(bytes: ch, length: Int(len)), encoding: encoding()))")
        */
        characterBuffer?.appendData(NSData(bytes: ch, length: Int(len)))
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        webInfo.url = response.URL?.absoluteString
        completionHandler(.Allow)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        dataBuffer.appendData(data)
        addData(data)
        if encoding() != charset {
            addDataEnd()
            webInfo = WebpageInfo()
            finished = false
            inHead = false
            characterBuffer = nil
            
            setup(charset)
            addData(dataBuffer)
        }
        if finished {
            addDataEnd()
            finish(nil)
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        addDataEnd()
        finish(error)
    }
    
    private func finish(err: NSError?) {
        finishedHandler?(webInfo, err)
        finishedHandler = nil
    }
    
    class func load(url: NSURL, handler: (WebpageInfo, NSError?) -> Void) {
        let parser = WebPreviewParser()
        parser.baseUrl = url.URLByDeletingLastPathComponent
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: parser, delegateQueue: NSOperationQueue())
        let task = session.dataTaskWithRequest(NSURLRequest(URL: url))
        task.resume()
        
        parser.finishedHandler = { info, err in
            dispatch_async(dispatch_get_main_queue()) {
                task.cancel()
                parser
                
                if let url = info.origin {
                    WebPreviewParser.load(url) { i, e -> Void in
                        handler(i, e)
                    }
                } else {
                    handler(info, err)
                }
            }
        }
    }
}
