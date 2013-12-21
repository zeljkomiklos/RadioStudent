//
//  RSFeeds.h
//  RadioStudent
//
//  Created by tigor on 21. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSFeeds : NSObject

@property (strong, nonatomic) NSDictionary *feeds;

+ (RSFeeds *)feedsWithURL:(NSURL *)feedsUrl;

- (void)fetch;

- (NSArray *)feed:(NSString *)mbLink;

@end
