//
//  InteractiveLinkLabel.swift
//  ClickableLabel
//
//  Created by Steven Curtis on 31/10/2019.
//  Copyright © 2019 Steven Curtis. All rights reserved.
//

import UIKit

class InteractiveLinkLabel: UILabel {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.configure()

        if let text = self.text {
            self.attributedText = self.activateHyperlinks(in: text)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()

        if let text = self.text {
            self.attributedText = self.activateHyperlinks(in: text)
        }
    }

    func configure() {
        isUserInteractionEnabled = true
    }

    private func activateHyperlinks(in text: String) -> NSMutableAttributedString {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            else { return NSMutableAttributedString(string: text) }

        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        guard matches.count > 0 else { return NSMutableAttributedString(string: text) }
        let match = matches[0]

        guard let range = Range(match.range, in: text) else { return NSMutableAttributedString(string: text) }

        let urlString = String(text[range])
        let output    = NSMutableAttributedString()

        // Split Text into Components (by url)
        let textComponents = text.components(separatedBy: urlString)

        // Append part before the url
        output.append(NSAttributedString(string: textComponents[0], attributes: nil))

        guard let correctedUrl = URL(string: String(urlString.hasPrefix("http") ? urlString : "http://\(urlString)")) else { return NSMutableAttributedString(string: text) }

        // Append the url
        output.append(NSAttributedString(string: String(urlString), attributes: [NSAttributedString.Key.link: correctedUrl]))

        // Append part after the url (also scanning it for hyperlinks
        if textComponents.count > 1, textComponents[1] != "" {

            output.append(activateHyperlinks(in: textComponents[1]))
        }

        return output
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        let superBool = super.point(inside: point, with: event)

        // Configure NSTextContainer
        let textContainer = NSTextContainer(size: bounds.size)
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines

        // Configure NSLayoutManager and add the text container
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)

        guard let attributedText = attributedText else {return false}

        // Configure NSTextStorage and apply the layout manager
        let textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addAttribute(NSAttributedString.Key.font, value: font!, range: NSMakeRange(0, attributedText.length))
        textStorage.addLayoutManager(layoutManager)

        // get the tapped character location
        let locationOfTouchInLabel = point

        // account for text alignment and insets
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        var alignmentOffset: CGFloat!
        switch textAlignment {
        case .left, .natural, .justified:
            alignmentOffset = 0.0
        case .center:
            alignmentOffset = 0.5
        case .right:
            alignmentOffset = 1.0
        @unknown default:
            fatalError()
        }

        let xOffset = ((bounds.size.width - textBoundingBox.size.width) * alignmentOffset) - textBoundingBox.origin.x
        let yOffset = ((bounds.size.height - textBoundingBox.size.height) * alignmentOffset) - textBoundingBox.origin.y
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - xOffset, y: locationOfTouchInLabel.y - yOffset)

        // work out which character was tapped
        let characterIndex = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        // work out how many characters are in the string up to and including the line tapped, to ensure we are not off the end of the character string
        let lineTapped = Int(ceil(locationOfTouchInLabel.y / font.lineHeight)) - 1
        let rightMostPointInLineTapped = CGPoint(x: bounds.size.width, y: font.lineHeight * CGFloat(lineTapped))
        let charsInLineTapped = layoutManager.characterIndex(for: rightMostPointInLineTapped, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < charsInLineTapped else {return false}

        let attributeName = NSAttributedString.Key.link

        let attributeValue = self.attributedText?.attribute(attributeName, at: characterIndex, effectiveRange: nil)

        if let value = attributeValue {
            if let url = value as? URL {
                UIApplication.shared.open(url)
            }
        }

        return superBool
    }
}
