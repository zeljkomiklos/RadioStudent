//
//  RSImage.m
//  RadioStudent
//
//  Created by tigor on 21. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "RSImage.h"
#import "Constants.h"

@interface RSImage ()

@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) NSData *imageData;
@property (strong, nonatomic) UIImage *image;
@property (atomic) BOOL fetching;

@end

@implementation RSImage

+ (RSImage *)imageWithURL:(NSURL *)url {
    return [[RSImage alloc] initWithURL:url];
}

- (id)initWithURL:(NSURL *)url {
    if((self = [super init]) == nil) return nil;
    
    self.url = url;
    
    return self;
}

- (UIImage *)image {
    if(_image != nil) {
        return _image;
    }
    
    if(self.imageData != nil) {
        _image = [UIImage imageWithData:_imageData];
    }
    
    return _image;
}

- (NSData *)imageData {
    if(_imageData == nil) {
        [self fetch];
    }
    return _imageData;
}


- (void)fetch {
    if(self.fetching) {
        return;
    }
    
    self.fetching = TRUE;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:_url options:NSDataReadingMappedIfSafe error:&error];
        if(error != nil) {
            NSLog(@"RSImage connection-error: %@", error);
            self.fetching = FALSE;
            return;
        }
        
        @synchronized(self) {
            self.imageData = data;
        }
        
        self.fetching = FALSE;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RS_IMAGE_LOADED_NOTIF object:nil userInfo:@{@"url": _url}];
        });
    });
}

@end
