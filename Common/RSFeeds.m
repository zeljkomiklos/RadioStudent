//
//  RSFeeds.m
//  RadioStudent
//
//  Created by tigor on 21. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "RSFeeds.h"
#import "RSImage.h"
#import "Constants.h"

@interface RSFeeds ()

@property (strong, nonatomic) NSURL *feedsUrl;
@property (strong, nonatomic) NSArray *feeds;
@property (strong, nonatomic) NSDictionary *icons;

@end


@implementation RSFeeds

+ (RSFeeds *)feedsWithURL:(NSURL *)feedsUrl {
    return [[RSFeeds alloc] initWithURL:feedsUrl];
}

- (id)initWithURL:(NSURL *)feedsUrl {
    if((self = [super init]) == nil) return nil;
    
    self.feedsUrl = feedsUrl;
    
    return self;
}

- (void)fetch {
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:_feedsUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:120];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if(connectionError) {
                                   NSLog(@"RSFeeds request failed: connection-error = %@", connectionError);
                                   return;
                               }
                               
                               NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
                               if(responseCode != 200) {
                                   NSLog(@"RSFeeds request failed: response-code = %d", (int)responseCode);
                                   return;
                               }
                               
                               NSError *jsonError = nil;
                               NSDictionary *index = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                               if(jsonError) {
                                   NSLog(@"RSFeeds json parser failed: json-error = %@", jsonError);
                                   self.feeds = nil;
                                   return;
                               }
                               
                               self.feeds = index[@"nodes"];
                               
                               NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                               
                               [[NSNotificationCenter defaultCenter] postNotificationName:RS_FEEDS_LOADED_NOTIF object:nil];
                               
                               for (NSDictionary *node in _feeds) {
                                   NSDictionary *feed = node[@"node"];
                                   NSString *imageUrl = feed[@"mb_image"];
                                   if(imageUrl != nil) {
                                       NSURL *url = [NSURL URLWithString:imageUrl];
                                       [dict setObject:[RSImage imageWithURL:url] forKey:imageUrl];
                                   }
                               }
                               
                               self.icons = dict;
                           }];
    
}


@end
