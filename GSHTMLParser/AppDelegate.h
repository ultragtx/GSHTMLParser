//
//  AppDelegate.h
//  GSHTMLParser
//
//  Created by Xinrong Guo on 12-11-14.
//  Copyright (c) 2012年 Xinrong Guo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GSHTMLParser.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, GSHTMLParserDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
