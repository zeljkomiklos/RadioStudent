//
//  AudioStream.m
//  RadioStudent
//
//  Created by tigor on 17. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "AudioPlayer.h"

@interface AudioPlayer ()

@property (strong, nonatomic) NSURL *audioUrl;

@end

@implementation AudioPlayer

#pragma mark - Factory

+ (AudioPlayer *)newInstance:(NSString *)url {
    return [[AudioPlayer alloc] initWithUrl:url];
}

- (id)initWithUrl:(NSString *)url {
    self.audioUrl = [NSURL URLWithString:url];
    
    return self;
}


#pragma mark - Control

- (BOOL)playing {
    return FALSE;
}

- (void)startPlaying {
}

- (void)stopPlaying {
    
}

@end
