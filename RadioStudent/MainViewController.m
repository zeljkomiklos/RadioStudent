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

#import "WebArticleController.h"

#define NORMAL_FONT_SIZE 15
#define AUDIO_STREAM_DONE  @"Touch Me!"
#define AUDIO_STREAM_WAITING @"Buffering ..."
#define AUDIO_STREAM_PLAYING @"Don't touch me!"
#define AUDIO_STREAM_PAUSED @"Paused!"

@interface MainViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) RSPlayer *player;
@property (strong, nonatomic) RSFeeds *feeds;
@property (strong, nonatomic) NSString *error;
@property (strong, nonatomic) NSString *statusInfo;
@property (strong, nonatomic) NSDictionary *presentingFeed;
@property (nonatomic) UIInterfaceOrientation orientation;

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
    self.orientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = TRUE;
    self.navigationController.navigationBar.backItem.title = nil;
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


#pragma mark - Navigation

- (void)presentWebArticle:(NSDictionary *)feed {
    self.presentingFeed = feed;
    [self performSegueWithIdentifier:@"pushWebArticle" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"pushWebArticle"]) {
        WebArticleController *controller = (WebArticleController *)segue.destinationViewController;
        controller.feed = _presentingFeed;
        self.presentingFeed = nil;
    } else if([segue.identifier isEqualToString:@"pushArticle"]) {
        WebArticleController *controller = (WebArticleController *)segue.destinationViewController;
        controller.feed = _presentingFeed;
        self.presentingFeed = nil;
    }

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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:orientation duration:duration];
    self.orientation = orientation;
    [((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout) invalidateLayout];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation {
    if ((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight)
        || (orientation == UIInterfaceOrientationPortrait)) {
        [_collectionView reloadData];
    }
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
    
    UILabel *statusLabel = (UILabel *)[view viewWithTag:1];
    statusLabel.text = [self statusText];
    
    UIButton *playButton = (UIButton *)[view viewWithTag:2];
    [playButton addTarget:self action:@selector(playStopAction:) forControlEvents:UIControlEventTouchDown];
    
    UIView *bgView = [view viewWithTag:3];
    if(_player.isPlaying) {
        bgView.backgroundColor = [UIColor orangeColor];
    } else {
        bgView.backgroundColor = [UIColor clearColor];
    }
    
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
    
    if(UIDeviceOrientationIsPortrait(_orientation)) {
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *feed = _feeds.feeds[indexPath.row / 2][@"node"];
    [self presentWebArticle:feed];
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


#pragma mark - Helpers

+ (CGFloat)totalContentWidth:(UICollectionView *)collectionView  layout:(UICollectionViewFlowLayout *)layout cellCount:(NSUInteger)itemCount {
    return CGRectGetWidth(collectionView.frame) - layout.sectionInset.left - layout.sectionInset.right - (itemCount - 1) * layout.minimumInteritemSpacing;
}



@end
