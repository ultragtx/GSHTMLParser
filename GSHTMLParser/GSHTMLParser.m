//
//  GSHTMLParser.m
//  GSHTMLParser
//
//  Created by Xinrong Guo on 12-11-14.
//  Copyright (c) 2012年 Xinrong Guo. All rights reserved.
//

#import "GSHTMLParser.h"
#import <libxml/HTMLtree.h>

static void startDocumentSAX(void *userData);
static void endDocumentSAX(void *userData);
static void	startElementSAX	(void *userData, const xmlChar * name, const xmlChar ** atts);
static void	endElementSAX (void *userData, const xmlChar * name);

static void	charactersFoundSAX(void * userData, const xmlChar * ch, int len);
static void errorEncounteredSAX(void * userData, const char * msg, ...);

static htmlSAXHandler simpleSAXHandlerStruct;

@interface GSHTMLParser ()

@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableData *characterBuffer;

@property (assign, nonatomic) htmlParserCtxtPtr context;
@property (assign, nonatomic) BOOL done;
@property (assign, nonatomic) BOOL storingCharacters;

@property (assign, nonatomic) dispatch_queue_t parseQueue;


@end

@implementation GSHTMLParser

- (void)dealloc {
    [_connection cancel];
}

- (id)initWithURLRequest:(NSURLRequest *)urlRequest {
    self = [super init];
    
    if (self) {
        self.urlRequest = urlRequest;
        
        _parseQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    
    return self;
}

- (void)parse {
    //[NSThread detachNewThreadSelector:@selector(downloadAndParse:) toTarget:self withObject:_urlRequest];
    dispatch_async(_parseQueue, ^{
        [self downloadAndParse:_urlRequest];
    });
}

- (void)abortParsing {
    dispatch_async(_parseQueue, ^{
        _done = YES;
        [_connection cancel];
    });
}

#pragma mark - Second Thread

- (void)downloadAndParse:(NSURLRequest *)urlRequest {
    @autoreleasepool {
        _done = NO;
        
        if (_connection != nil) {
            [self abortParsing];
        }
        
        self.connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
        
        [self performSelectorOnMainThread:@selector(downloadStarted) withObject:nil waitUntilDone:NO];
        
        _context = htmlCreatePushParserCtxt(&simpleSAXHandlerStruct, (__bridge void *)(self), NULL, 0, NULL, XML_CHAR_ENCODING_NONE);
        
        if (_connection != nil) {
            do {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            } while (!_done);
        }
        
        htmlFreeParserCtxt(_context);
        self.characterBuffer = nil;
    }
}

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    _done = YES;
    [self performSelectorOnMainThread:@selector(downloadError:) withObject:error waitUntilDone:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"didReceiveData");
    //NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    if (_context != NULL) {
        htmlParseChunk(_context, (const char*)[data bytes], (int)[data length], 0); // !!!: uint to int cast
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self performSelectorOnMainThread:@selector(downloadEnded) withObject:nil waitUntilDone:NO];
    if (_context != NULL) {
        htmlParseChunk(_context, NULL, 0, 1);
    }
    _done = YES;
}

#pragma mark - Main Thread

- (void)downloadStarted {
    
}

- (void)downloadError:(NSError *)error {
    
}

- (void)downloadEnded {
    
}


@end


#pragma mark - libxml SAX callbacks

static void startDocumentSAX(void *userData) {
    GSHTMLParser *parser = (__bridge GSHTMLParser *)userData;
    if ([parser.delegate respondsToSelector:@selector(parserDidStartDocument:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [parser.delegate parserDidStartDocument:parser];
        });
    }
}

static void endDocumentSAX(void *userData) {
    GSHTMLParser *parser = (__bridge GSHTMLParser *)userData;
    if ([parser.delegate respondsToSelector:@selector(parserDidEndDocument:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [parser.delegate parserDidEndDocument:parser];
        });
    }
}

static void	startElementSAX	(void *userData, const xmlChar * name, const xmlChar ** atts) {
    GSHTMLParser *parser = (__bridge GSHTMLParser *)userData;
    
    NSString *elementName = [NSString stringWithUTF8String:(const char*)name];
    
    if ([parser.delegate respondsToSelector:@selector(parser:didStartElement:attributes:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [parser.delegate parser:parser didStartElement:elementName attributes:nil];
        });
    }
    
}

static void	endElementSAX (void *userData, const xmlChar * name) {
    GSHTMLParser *parser = (__bridge GSHTMLParser *)userData;
    
    NSString *elementName = [NSString stringWithUTF8String:(const char*)name];
    
    if ([parser.delegate respondsToSelector:@selector(parser:didEndElement:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [parser.delegate parser:parser didEndElement:elementName];
        });
    }
    
}


static void	charactersFoundSAX(void *userData, const xmlChar *ch, int len) {
    GSHTMLParser *parser = (__bridge GSHTMLParser *)userData;
    
    NSString *string = [NSString stringWithUTF8String:(const char*)ch];
    
    if ([parser.delegate respondsToSelector:@selector(parser:foundCharacters:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [parser.delegate parser:parser foundCharacters:string];
        });
    }
}

#define MAX_MSG_SIZE 100

static void errorEncounteredSAX(void *userData, const char *msg, ...) {
    GSHTMLParser *parser = (__bridge GSHTMLParser *)userData;
    
    char message[MAX_MSG_SIZE] = {'\0'};
    
    va_list args;
    va_start ( args, msg );
    vsnprintf ( message, MAX_MSG_SIZE, msg, args );
    va_end ( args );
    
    NSString *errorMsg = [NSString stringWithUTF8String:(const char*)message];
    
    NSDictionary *errorDict = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:@"GSHTMLParser" code:-1 userInfo:errorDict];
    
    if ([parser.delegate respondsToSelector:@selector(parser:parseErrorOccurred:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [parser.delegate parser:parser parseErrorOccurred:error];
        });
    }
}

// Refer to libxml documentation at http://www.xmlsoft.org for more information
// about the SAX callbacks.
static htmlSAXHandler simpleSAXHandlerStruct = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,                       /* attributeDecl */
    NULL,                       /* elementDecl */
    NULL,                       /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    startDocumentSAX,           /* startDocument */
    endDocumentSAX,             /* endDocument */
    startElementSAX,            /* startElement*/
    endElementSAX,              /* endElement */
    NULL,                       /* reference */
    charactersFoundSAX,         /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncounteredSAX,        /* error */
    NULL,                       /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    NULL,                       /* cdataBlock */
    NULL,                       /* externalSubset */
    1,                          //
    NULL,
    NULL,            /* startElementNs */
    NULL,              /* endElementNs */
    NULL,                       /* serror */
};