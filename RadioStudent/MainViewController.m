//
//  MainViewController.m
//  RadioStudent
//
//  Created by tigor on 17. 12. 13.
//  Copyright (c) 2013 Zavod Radio Študent Ljubljana. All rights reserved.
//

#import "MainViewController.h"
#import "Constants.h"
#import "RobustPlayer.h"
#import "RobustHttpStreamer.h"
#import "RSFeeds.h"
#import "RSImage.h"

#import "WebArticleController.h"

#define CELL_COUNT 4
#define TITLE_FONT_SIZE 15
#define SUBTITLE_FONT_SIZE 14

#define PLAYER_SCHEDULED_RETRY_INFO @"Retrying..."
#define AUDIO_STREAM_STOPPED_INFO  @"Touch Me!"
#define AUDIO_STREAM_WAITING_INFO @"Buffering..."
#define AUDIO_STREAM_PLAYING_INFO @"Don't touch me!"
#define AUDIO_STREAM_PAUSED_INFO @"Paused!"

@interface MainViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) BOOL attemptingRestartPlayer;
@property (strong, nonatomic) RobustPlayer *player;
@property (strong, nonatomic) RSFeeds *feeds;
@property (strong, nonatomic) NSString *error;
@property (strong, nonatomic) NSDictionary *presentingFeed;
@property (nonatomic) UIInterfaceOrientation orientation;

@property (readonly, nonatomic) NSString *statusInfo;

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
    
    self.player = [RobustPlayer playerWithURL:[NSURL URLWithString:RS_LIVE_STREAM_URL]];
    self.feeds = [RSFeeds feedsWithURL:[NSURL URLWithString:RS_FEEDS_URL]];
    
    [_player wakeUp];
    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    self.orientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = TRUE;
    self.navigationController.navigationBar.backItem.title = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedsLoadedNotif:) name:RS_FEEDS_LOADED_NOTIF object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageLoadedNotif:) name:RS_IMAGE_LOADED_NOTIF object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioStreamerStatusChangedNotif:) name:ASStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduledRetryAttemptChangedNotif:) name:RPScheduledRetryAttemptChangedNotification object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
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
    self.attemptingRestartPlayer = FALSE;
    
    if(_player.shouldStopBeforeStart) {
        [_player stop];
        
        return;
    }
    
    [_feeds fetch];
    [_player start];
    
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


#pragma mark - AudioStreamer

- (void)audioStreamerStatusChangedNotif:(NSNotification *)notif {
    [self updateUi];
}


#pragma mark - Player

- (void)scheduledRetryAttemptChangedNotif:(NSNotification *)notif {
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
    return _feeds.feeds.count * CELL_COUNT; // image & feed cells
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    if (kind != UICollectionElementKindSectionHeader) {
        return nil;
    }
    
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                        withReuseIdentifier:@"NavigationView" forIndexPath:indexPath];
    
    UILabel *statusLabel = (UILabel *)[view viewWithTag:1];
    statusLabel.text = self.statusInfo;
    
    UIButton *playButton = (UIButton *)[view viewWithTag:2];
    [playButton addTarget:self action:@selector(playStopAction:) forControlEvents:UIControlEventTouchDown];
    
    UIView *bgView = [view viewWithTag:3];
    if(_player.isPlaying) {
        bgView.backgroundColor = [UIColor orangeColor];
    } else {
        if(_player.scheduledRetryAttempt) {
            bgView.backgroundColor = [UIColor greenColor];
        } else {
            bgView.backgroundColor = [UIColor clearColor];
        }
    }
    
    return view;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger _feedIndex = indexPath.row / 4;
    
    NSDictionary *feed = _feeds.feeds[_feedIndex][@"node"];
    if((indexPath.row % CELL_COUNT) == 0) {
        // title
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TitleCell" forIndexPath:indexPath];
        
        UILabel *titleLabel = (UILabel *)[cell viewWithTag:1];
        titleLabel.text = feed[@"title"];
        
        if(UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            titleLabel.font = [titleLabel.font fontWithSize:TITLE_FONT_SIZE * 1.2];
        } else {
            titleLabel.font = [titleLabel.font fontWithSize:TITLE_FONT_SIZE];
        }
        return cell;
    }
    if((indexPath.row % CELL_COUNT) == 1) {
        // icon
        NSString *key = feed[@"mb_image"];
        RSImage *icon = _feeds.icons[key];
        
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IconCell" forIndexPath:indexPath];
        if(icon.image != nil) {
            UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
            imageView.image = icon.image;
        }
        
        return cell;
    }
    
    if((indexPath.row % CELL_COUNT) == 2) {
        // subtitles
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SubtitleCell" forIndexPath:indexPath];
        
        UITextView *subtitleView = (UITextView *)[cell viewWithTag:1];
        subtitleView.text = feed[@"mb_subtitle"];
        
        subtitleView.editable = TRUE;
        if(UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
            subtitleView.font = [subtitleView.font fontWithSize:SUBTITLE_FONT_SIZE * 1.2];
        } else {
            subtitleView.font = [subtitleView.font fontWithSize:SUBTITLE_FONT_SIZE];
        }
        subtitleView.editable = FALSE;
        return cell;
        
    }
    
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"FeedFooter" forIndexPath:indexPath];
}


#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat w = [[self class] totalContentWidth:collectionView layout:collectionViewLayout cellCount:2];
    
    if(UIDeviceOrientationIsPortrait(_orientation)) {
        if((indexPath.row % CELL_COUNT) == 0) {
            return CGSizeMake(w, 40); // title size
        }
        
        if((indexPath.row % CELL_COUNT) == 1) {
            return CGSizeMake(90, 80); // image size
        }
        
        if((indexPath.row % CELL_COUNT) == 2) {
            return CGSizeMake(w - 90, 80); // subtitle size
        }
        
        return CGSizeMake(w, 40); // footer size
    }
    
    // landscape
    
    if((indexPath.row % CELL_COUNT) == 0) {
        return CGSizeMake(w, 40); // title size
    }
    
    if((indexPath.row % CELL_COUNT) == 1) {
        return CGSizeMake(130, 90); // image size
    }
    
    if((indexPath.row % CELL_COUNT) == 2) {
        return CGSizeMake(w - 130, 90); // subtitle size
    }
    
    return CGSizeMake(w, 40); // footer size
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *feed = _feeds.feeds[indexPath.row / CELL_COUNT][@"node"];
    [self presentWebArticle:feed];
}


#pragma mark - Private

- (NSString *)statusInfo {
    RobustHttpStreamer *streamer = _player.streamer;
    
    if(_player.scheduledRetryAttempt) {
        return PLAYER_SCHEDULED_RETRY_INFO;
    }
    
    if(streamer.isDone) {
        if(streamer.errorCode != AS_NO_ERROR) {
            return [NSString stringWithFormat:@"[%@]", [AudioStreamer stringForErrorCode:streamer.errorCode]];
        }
        
        return AUDIO_STREAM_STOPPED_INFO;
    }
    
    if(streamer.isPaused) {
       return AUDIO_STREAM_PAUSED_INFO;
    }
    
    if(streamer.isWaiting) {
        return AUDIO_STREAM_WAITING_INFO;
    }
    
    if(streamer.isPlaying) {
        return  AUDIO_STREAM_PLAYING_INFO;
    }
    
    return AUDIO_STREAM_STOPPED_INFO;
}

- (void)updateUi {
    [_collectionView reloadData];
}


#pragma mark - Helpers

+ (CGFloat)totalContentWidth:(UICollectionView *)collectionView  layout:(UICollectionViewFlowLayout *)layout cellCount:(NSUInteger)itemCount {
    return CGRectGetWidth(collectionView.frame) - layout.sectionInset.left - layout.sectionInset.right - (itemCount - 1) * layout.minimumInteritemSpacing;
}



@end
