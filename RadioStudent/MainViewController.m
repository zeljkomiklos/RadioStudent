//
//  MainViewController.m
//  RadioStudent
//
//  Created by tigor on 17. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "MainViewController.h"
#import "Constants.h"
#import "AudioStreamer.h"
#import "RSPlayer.h"
#import "RSFeeds.h"
#import "RSImage.h"

#define NORMAL_FONT_SIZE 15
#define AUDIO_STREAM_DONE  @"Dotik za Vklop"
#define AUDIO_STREAM_WAITING @"..."
#define AUDIO_STREAM_PLAYING @"Dotik za Izklop"
#define AUDIO_STREAM_PAUSED @"Pavza"

@interface MainViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) RSPlayer *player;
@property (strong, nonatomic) RSFeeds *feeds;
@property (strong, nonatomic) NSString *error;
@property (strong, nonatomic) NSString *statusInfo;

@end


@implementation MainViewController


#pragma mark - Lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self == nil) {
        return nil;
    }
    return self;
}

- (void)dealloc {
    [_player tearDown];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.player = [RSPlayer playerWithURL:[NSURL URLWithString:RS_LIVE_STREAM_URL]];
    self.feeds = [RSFeeds feedsWithURL:[NSURL URLWithString:RS_FEEDS_URL]];
    
    [_player wakeUp];
    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    self.statusInfo = AUDIO_STREAM_DONE;
}

- (void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedsLoadedNotif:) name:RS_FEEDS_LOADED_NOTIF object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageLoadedNotif:) name:RS_IMAGE_LOADED_NOTIF object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioStreamerErrorNotif:) name:AUDIO_STREAMER_ERROR_NOTIF object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioStreamerPlayingNotif:) name:AUDIO_STREAMER_PLAYING_NOTIF object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioStreamerStatusChangedNotif:) name:ASStatusChangedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Bindings

- (IBAction)playStopAction:(id)sender {
    self.error = nil;
    if(_player.isPlaying) {
        [_player stop];
    } else {
        [_feeds fetch];
        [_player start];
    }
}


#pragma mark - Feeds

- (void)feedsLoadedNotif:(NSNotification *)notif {
#ifdef DEBUG
    NSLog(@"Feeds: %@", _feeds.feeds);
#endif
    [self updateUi];
}

- (void)imageLoadedNotif:(NSNotification *)notif {
#ifdef DEBUG
    NSLog(@"Image loaded: %@", notif.userInfo[@"url"]);
#endif
    [self updateUi];
}

- (void)audioStreamerPlayingNotif:(NSNotification *)notif {
    self.error = nil;
    [self updateUi];
}

- (void)audioStreamerStatusChangedNotif:(NSNotification *)notif {
    AudioStreamer *as = notif.object;
    if(as.isDone) {
        self.statusInfo = AUDIO_STREAM_DONE;
    } else if(as.isPaused) {
        self.statusInfo = AUDIO_STREAM_PAUSED;
    } else if(as.isWaiting) {
        self.statusInfo = AUDIO_STREAM_WAITING;
    } else if(as.isPlaying) {
        self.statusInfo = AUDIO_STREAM_PLAYING;
    }
    [self updateUi];
}

- (void)audioStreamerErrorNotif:(NSNotification *)notif {
    self.error = notif.userInfo[@"info"];
    [self updateUi];
}


#pragma mark - Remote Events

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    [_player remoteControlReceivedWithEvent:(UIEvent *)receivedEvent];
}



#pragma mark - UIViewControllerRotation


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation {
    if ((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight)
        || (orientation == UIInterfaceOrientationPortrait)) {
        [_collectionView reloadData];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout) invalidateLayout];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _feeds.feeds.count * 2; // image & feed cells
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    if (kind != UICollectionElementKindSectionHeader) {
        return nil;
    }
    
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                        withReuseIdentifier:@"NavigationView" forIndexPath:indexPath];
    
    UILabel *statusLabel = (UILabel *)[view viewWithTag:2];
    statusLabel.text = [self statusText];
    
    UIButton *playButton = (UIButton *)[view viewWithTag:3];
    [playButton addTarget:self action:@selector(playStopAction:) forControlEvents:UIControlEventTouchDown];
    
    return view;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger _feedIndex = indexPath.row / 2;
    
    NSDictionary *feed = _feeds.feeds[_feedIndex][@"node"];
    if((indexPath.row % 2) == 0) {
        // 0, 2, ... icons
        NSString *key = feed[@"mb_image"];
        RSImage *icon = _feeds.icons[key];
        
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IconCell" forIndexPath:indexPath];
        if(icon.image != nil) {
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
            imageView.image = icon.image;
        }
        
        return cell;
    }
    
    // 1, 3, ... feeds
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FeedCell" forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:1];
    titleLabel.text = feed[@"title"];
    
    UILabel *subLabel = (UILabel *)[cell viewWithTag:2];
    subLabel.text = feed[@"mb_subtitle"];
    
    if(UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        titleLabel.font = [titleLabel.font fontWithSize:(NORMAL_FONT_SIZE + 2) * 1.1];
        subLabel.font = [subLabel.font fontWithSize:NORMAL_FONT_SIZE * 1.2];
    } else {
        titleLabel.font = [titleLabel.font fontWithSize:(NORMAL_FONT_SIZE + 2)];
        subLabel.font = [subLabel.font fontWithSize:NORMAL_FONT_SIZE];
    }

    return cell;
    
}


#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat w = [[self class] totalContentWidth:collectionView layout:collectionViewLayout cellCount:2];
    
    if(UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        if((indexPath.row % 2) == 0) {
            return CGSizeMake(100, 110); // image size
        }
        return CGSizeMake(w - 100, 110); // feed size
    } else {
        if((indexPath.row % 2) == 0) {
            return CGSizeMake(160, 110); // image size
        }
        return CGSizeMake(w - 160, 110); // feed size
    }
    [NSException raise:@"Illegal state!" format:nil];
    return CGSizeMake(0, 0);
}

+ (CGFloat)totalContentWidth:(UICollectionView *)collectionView  layout:(UICollectionViewFlowLayout *)layout cellCount:(NSUInteger)itemCount {
    return CGRectGetWidth(collectionView.frame) - layout.sectionInset.left - layout.sectionInset.right - (itemCount - 1) * layout.minimumInteritemSpacing;
}


#pragma mark - Private

- (void)updateUi {
    [_collectionView reloadData];
}

- (NSString *)statusText {
    if(_error) {
        return [NSString stringWithFormat:@"%@ [%@]", _statusInfo, _error];
    }
    return [NSString stringWithFormat:@"%@", _statusInfo];
}

@end
