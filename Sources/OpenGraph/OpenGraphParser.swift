import Foundation

public protocol OpenGraphParser {
    func parse(htmlString: String) -> [OpenGraphMetadata: String]
}

extension OpenGraphParser {
    func parse(htmlString: String) -> [OpenGraphMetadata: String] {
        let nsString = htmlString as NSString

        // extract meta tag
        let metatagRegex  = try! NSRegularExpression(
            pattern: "<meta(?:\".*?\"|\'.*?\'|[^\'\"])*?>",
            options: [.dotMatchesLineSeparators]
        )
        let metaTagMatches = metatagRegex.matches(in: htmlString,
                                       options: [],
                                       range: NSMakeRange(0, nsString.length))
        if metaTagMatches.isEmpty {
            return [:]
        }

        // prepare regular expressions to extract og property and content.
        let propertyRegexp = try! NSRegularExpression(
            pattern: "\\s(?:property|name)=(?:\"|\')*og:([a-zA_Z:]+)(?:\"|\')*",
            options: []
        )
        let contentRegexp = try! NSRegularExpression(
            pattern: "\\scontent=\\\\*?\"(.*?)\\\\*?\"",
            options: []
        )

        // create attribute dictionary
        let attributes = metaTagMatches.reduce([OpenGraphMetadata: String]()) { (attributes, result) -> [OpenGraphMetadata: String] in
            var copiedAttributes = attributes

            let property = { () -> (name: String, content: String)? in
                let metaTag = nsString.substring(with: result.range)
                let nsMetaTag = metaTag as NSString
                let propertyMatches = propertyRegexp.matches(in: metaTag,
                                               options: [],
                                               range: NSMakeRange(0, nsMetaTag.length))
                guard let propertyResult = propertyMatches.first else { return nil }
                
                var contentMatches = contentRegexp.matches(in: metaTag, options: [], range: NSMakeRange(0, nsMetaTag.length))
                if contentMatches.first == nil {
                    let contentRegexp = try! NSRegularExpression(
                        pattern: "\\scontent=\\\\*?'(.*?)\\\\*?'",
                        options: []
                    )
                    contentMatches = contentRegexp.matches(in: metaTag, options: [], range: NSMakeRange(0, nsMetaTag.length))
                }
                guard let contentResult = contentMatches.first else { return nil }

                let property = nsMetaTag.substring(with: propertyResult.range(at: 1))
                let content = nsMetaTag.substring(with: contentResult.range(at: 1)).stringByDecodingHTMLEntities
                
                return (name: property, content: content)
            }()
            if let property = property, let metadata = OpenGraphMetadata(rawValue: property.name) {
                copiedAttributes[metadata] = property.content
            }
            return copiedAttributes
        }
        
        return attributes
    }
}
