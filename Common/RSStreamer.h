//
//  RSStreamer.h
//  RadioStudent
//
//  Created by tigor on 20. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "AudioStreamer.h"

@interface RSStreamer : AudioStreamer

@property (readonly) BOOL pausedByInterruption;

+ (RSStreamer *)streamWithURL:(NSURL *)url;

- (BOOL)togglePlayPause;

@end
