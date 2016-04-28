//
//  ViewController.swift
//  CHWebPreviewDemo
//
//  Created by nya on 4/28/16.
//  Copyright © 2016 CatHand. All rights reserved.
//

import UIKit
import SVProgressHUD
import SDWebImage
import CHWebPreview

class ViewController: UIViewController {

    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = nil
        descLabel.text = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loadAction(sender: AnyObject) {
        guard let str = urlField.text, url = NSURL(string: str) else {
            let alert = UIAlertController(title: "Invalid url.", message: nil, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        SVProgressHUD.show()
        CHWebPreview.load(url) { (info, error) in
            SVProgressHUD.dismiss()
            guard error == nil else {
                let alert = UIAlertController(title: "No preview", message: error?.localizedDescription, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            
            if let imageUrlString = info.image?.url, imageUrl = NSURL(string: imageUrlString) {
                self.imageView.sd_setImageWithURL(imageUrl)
            } else {
                self.imageView.image = nil
            }
            self.titleLabel.text = info.title
            self.descLabel.text = info.desc
        }
    }
}

