@import AudioToolbox;

#import <Foundation/Foundation.h>


@interface AudioFile : NSObject

@property (readonly)                AudioFileID					fileID;
@property (readonly)                UInt64						packetsCount;
@property (readonly)                UInt32						maxPacketSize;
@property (readonly, nonatomic)     AudioStreamBasicDescription *audioFormatRef;

- (id) initWithURL: (CFURLRef) url;

@end


