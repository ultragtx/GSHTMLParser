//
//  GSHTMLParser.h
//  GSHTMLParser
//
//  Created by Xinrong Guo on 12-11-14.
//  Copyright (c) 2012年 Xinrong Guo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GSHTMLParserDelegate;

@interface GSHTMLParser : NSObject
<
NSURLConnectionDelegate,
NSURLConnectionDataDelegate
>

@property (weak, nonatomic) id<GSHTMLParserDelegate> delegate;

@property (strong, nonatomic) NSURLRequest *urlRequest;

- (id)initWithURLRequest:(NSURLRequest *)urlRequest;

- (void)parse;
- (void)abortParsing;

@end

@protocol GSHTMLParserDelegate <NSObject>

@optional

- (void)parserDidStartDocument:(GSHTMLParser *)parser;
- (void)parserDidEndDocument:(GSHTMLParser *)parser;
- (void)parser:(GSHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict;
- (void)parser:(GSHTMLParser *)parser didEndElement:(NSString *)elementName;
- (void)parser:(GSHTMLParser *)parser parseErrorOccurred:(NSError *)parseError;
- (void)parser:(GSHTMLParser *)parser foundCharacters:(NSString *)string;

@end