//
//  AppDelegate.m
//  GSHTMLParser
//
//  Created by Xinrong Guo on 12-11-14.
//  Copyright (c) 2012年 Xinrong Guo. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate {
    GSHTMLParser *_parser;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://stackoverflow.com/questions/13313365/parsing-html-using-libxml2-gives-entity-ref-issue"]];
    //[request setValue:@"text/html" forHTTPHeaderField:@"Content-Type"];
	//[request setValue:@"text/html" forHTTPHeaderField:@"Accept"];
    [request setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17" forHTTPHeaderField:@"User-Agent"];
    _parser = [[GSHTMLParser alloc] initWithURLRequest:request];
    _parser.delegate = self;
    [_parser parse];
}

- (void)parser:(GSHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict {
    NSLog(@">>>>>>[%@]", elementName);
}

- (void)parser:(GSHTMLParser *)parser didEndElement:(NSString *)elementName {
    NSLog(@"<<<<<<[%@]", elementName);
}

- (void)parser:(GSHTMLParser *)parser foundCharacters:(NSString *)string {
    NSLog(@"{%@}", string);
}

- (void)parser:(GSHTMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"[ERROR]: %@", [parseError localizedDescription]);
}
@end
