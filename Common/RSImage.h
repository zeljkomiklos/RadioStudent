//
//  RSImage.h
//  RadioStudent
//
//  Created by tigor on 21. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSImage : NSObject

@property (readonly, nonatomic) UIImage *image;

+ (RSImage *)imageWithURL:(NSURL *)url;

@end
