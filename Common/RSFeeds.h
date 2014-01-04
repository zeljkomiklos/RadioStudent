//
//  RSFeeds.h
//  RadioStudent
//
//  Created by tigor on 21. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSFeeds : NSObject

@property (readonly, nonatomic) NSArray *feeds;
@property (readonly, nonatomic) NSDictionary *icons;

+ (RSFeeds *)feedsWithURL:(NSURL *)feedsUrl;

- (void)fetch;

@end
