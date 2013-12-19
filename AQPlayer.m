#import "AQPlayer.h"


@interface AQPlayer ()
{
    AudioQueueRef					_queue;
    UInt32						    _bufferByteSize;
    AudioQueueBufferRef				_buffers[AUDIOBUFFERS_NUMBER];
    AudioStreamPacketDescription	_packetDescriptions[MAX_PACKET_COUNT];
    
    SInt64	_currentPacketNumber;
    UInt32	_numPacketsToRead;
}

- (NSInteger)fillBuffer:(AudioQueueBufferRef)buffer;

@end


static void AQOutputCallback(void * inUserData,	AudioQueueRef inAQ, AudioQueueBufferRef	inBuffer) {
    AQPlayer * aqp = (__bridge AQPlayer *)inUserData;
    [aqp fillBuffer:(AudioQueueBufferRef)inBuffer];
}


@implementation AQPlayer

@synthesize currentPacketNumber;
@synthesize audioFile;

- (id)initWithFile:(NSString *)file {
    self.audioFile = [[AudioFile alloc] initWithURL:(__bridge CFURLRef)([NSURL fileURLWithPath:file])];
    
    currentPacketNumber = 0;
    
    AudioQueueNewOutput([audioFile audioFormatRef], AQOutputCallback, (__bridge void *)(self), CFRunLoopGetCurrent (), kCFRunLoopCommonModes, 0, &_queue);
    
    _bufferByteSize = 4096;
    
    if (_bufferByteSize < audioFile.maxPacketSize) {
        _bufferByteSize = audioFile.maxPacketSize;
    }
    
    _numPacketsToRead = _bufferByteSize/audioFile.maxPacketSize;
    
    for(int i = 0; i < AUDIOBUFFERS_NUMBER; i++){
        AudioQueueAllocateBuffer (_queue, _bufferByteSize, &_buffers[i]);
    }
    
    return self;
}

- (void)dealloc {
    if (_queue != NULL){
        AudioQueueDispose(_queue, YES);
        _queue = nil;
    }
}

- (void)play {
    for (int bufferIndex = 0; bufferIndex < AUDIOBUFFERS_NUMBER; bufferIndex++) {
        [self fillBuffer:_buffers[bufferIndex]];
    }
    AudioQueueStart (_queue, NULL);
    
}

- (NSInteger)fillBuffer:(AudioQueueBufferRef)buffer {
    UInt32 numBytes;
    UInt32 numPackets = _numPacketsToRead ;
    BOOL isVBR = [audioFile audioFormatRef]->mBytesPerPacket == 0 ? YES : NO;
    AudioFileReadPackets(
                         audioFile.fileID,
                         NO,
                         &numBytes,
                         isVBR ? _packetDescriptions : 0,
                         currentPacketNumber,
                         &numPackets,
                         buffer->mAudioData
                         );
    
    if (numPackets > 0) {
        buffer->mAudioDataByteSize = numBytes;
        AudioQueueEnqueueBuffer (
                                 _queue,
                                 buffer,
                                 isVBR ? numPackets : 0,
                                 isVBR ? _packetDescriptions : 0
                                 );
        
        
    } else {
        // end of present data, check if all packets are played
        // if yes, stop play and dispose queue
        // if no, pause queue till new data arrive then start it again
    }
    
    return  numPackets;
}

@end