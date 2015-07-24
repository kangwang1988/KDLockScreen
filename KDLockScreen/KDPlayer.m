//
//  KDPlayer.m
//  KDLockScreen
//
//  Created by KyleWong on 15/7/2.
//  Copyright (c) 2015年 KyleWong. All rights reserved.
//

#import "KDPlayer.h"

@interface KDPlayer()
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,strong) NSURL *musicURL;
@property (nonatomic,assign) BOOL isReady;
@property (nonatomic,copy) NSString *totalTime;
@property (nonatomic,assign) NSString *title;
@property (nonatomic,assign) NSString *albumTitle;
@property (nonatomic,assign) NSString *artist;
@property (nonatomic,strong) NSNumber *totalTimeSecond;
@property (nonatomic,strong) id playbackTimeObserver;
@end

@implementation KDPlayer
- (instancetype)init{
    if(self=[super init]){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
            if(![[AVAudioSession sharedInstance] setActive:YES error:nil])
            {
                NSLog(@"Failed to set up a session.");
            }
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            MPRemoteCommandCenter *rcc = [MPRemoteCommandCenter sharedCommandCenter];
            
            MPFeedbackCommand *bookmarkCommand = [rcc bookmarkCommand];
            [bookmarkCommand setEnabled:YES];
            [bookmarkCommand setLocalizedTitle:@"Bookmark"];  // can leave this out for default
            [bookmarkCommand addTarget:self action:@selector(onBookmarkEvent:)];
            
            MPFeedbackCommand *likeCommand = [rcc likeCommand];
            [likeCommand setEnabled:YES];
            [likeCommand setLocalizedTitle:@"I love it"];  // can leave this out for default
            [likeCommand addTarget:self action:@selector(onLikeEvent:)];
            
            MPFeedbackCommand *dislikeCommand = [rcc dislikeCommand];
            [dislikeCommand setEnabled:YES];
            [dislikeCommand setActive:YES];
            [dislikeCommand setLocalizedTitle:@"I hate it"];
            [dislikeCommand addTarget:self action:@selector(onDislikeEvent:)];
            
            MPRemoteCommand *playCommand = [rcc playCommand];
            [playCommand setEnabled:YES];
            [playCommand addTarget:self action:@selector(onPlayEvent:)];
            
            MPRemoteCommand *pauseCommand = [rcc pauseCommand];
            [pauseCommand setEnabled:YES];
            [playCommand addTarget:self action:@selector(onPauseEvent:)];
            
            MPRemoteCommand *nextTrackCommand = [rcc nextTrackCommand];
            [nextTrackCommand setEnabled:YES];
            [nextTrackCommand addTarget:self action:@selector(onNextTrackEvent:)];
            
        });
    }
    return self;
}

- (void)dealloc{
    [self unregisterNotification];
}

#pragma mark - Action
- (IBAction)onBookmarkEvent:(id)sender{
    
}

- (IBAction)onPlayEvent:(id)sender{
    
}

- (IBAction)onPauseEvent:(id)sender{
    
}

- (IBAction)onNextTrackEvent:(id)sender{
    
}

- (IBAction)onLikeEvent:(id)sender{
    
}

- (IBAction)onDislikeEvent:(id)sender{
    
}

#pragma mark - Notification
- (void)registerNotification{
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];// 监听loadedTimeRanges属性
    
    // 添加播放结束通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

- (void)unregisterNotification{
    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [self.player removeTimeObserver:self.playbackTimeObserver];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            CMTime duration = self.playerItem.duration;
            CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;// 转换成秒
            _totalTimeSecond = @((int)totalSecond);
            _totalTime = [self convertTime:totalSecond];// 转换成播放时间
            if ([self.delegate respondsToSelector:@selector(playerStatusReadyToPlayWithPlayer:totalTime:)]) {
                [self.delegate playerStatusReadyToPlayWithPlayer:self totalTime:_totalTime];
            }
            [self monitoringPlayback:self.playerItem];// 监听播放状态
            
            // 记录状态
            _isReady = YES;
            if (_isPlaying) {
                [self nowplaySetting];
            }
            
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            if ([self.delegate respondsToSelector:@selector(playerStatusFailedWithPlayer:)]) {
                [self.delegate playerStatusFailedWithPlayer:self];
            }
            _isReady = NO;
            NSLog(@"AVPlayerStatusFailed");
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        NSLog(@"Time Interval:%f",timeInterval);
        CMTime duration = _playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        // 缓冲的百分比
        CGFloat progress = timeInterval / totalDuration;
        NSLog(@"缓存进度---%f",progress);
    }
}

#pragma mark - 播放完成的通知
- (void)moviePlayDidEnd:(NSNotification *)notification {
    self.isPlaying = NO;
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        if ([weakSelf.delegate respondsToSelector:@selector(playerWithPlayEndWithPlayer:)]) {
            [weakSelf.delegate playerWithPlayEndWithPlayer:self];
        }
    }];
}

#pragma mark - Player Operation
- (void)play
{
    self.isPlaying = YES;
    [self.player play];
    if (_isReady) {
        [self nowplaySetting];
    }
}

- (void)pause
{
    self.isPlaying = NO;
    [self.player pause];
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value / playerItem.currentTime.timescale;// 计算当前在第几秒
        
        NSString *timeString = [weakSelf convertTime:currentSecond];
        
        if ([weakSelf.delegate respondsToSelector:@selector(playerWithCurrentTimeRefreshWithPlayer:currentTimeStr:)]) {
            [weakSelf.delegate playerWithCurrentTimeRefreshWithPlayer:weakSelf currentTime:timeString];
        }
    }];
}


#pragma mark - Nowplaying
- (void)nowplaySetting
{
    CGFloat currentSecond = _playerItem.currentTime.value / _playerItem.currentTime.timescale;// 计算当前在第几秒
    [self _loadWithTitle:self.title artist:self.artist albumTitle:self.albumTitle totalDuration:self.totalTimeSecond currentTime:@(currentSecond)];
}

#pragma mark - Public Interfaces
- (void)loadMusicWithURL:(NSURL *)aURL{
    if(self.musicURL && [self.musicURL.absoluteString isEqualToString:aURL.absoluteString]){
        if(self.isPlaying)
            [self play];
        if([self.delegate respondsToSelector:@selector(playerStatusReadyToPlayWithPlayer:totalTime:)])
            [self.delegate playerStatusReadyToPlayWithPlayer:self totalTime:self.totalTime];
    }else{
        [self setPlayerItem:[[AVPlayerItem alloc] initWithAsset:[AVAsset assetWithURL:aURL]]];
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
        [self registerNotification];
        [self setMusicURL:aURL];
    }
}

- (void)loadWithTitle:(NSString *)aTitle artist:(NSString *)aArtist albumTitle:(NSString *)aAlbumTitle{
    [self setTitle:aTitle];
    [self setArtist:aArtist];
    [self setAlbumTitle:aAlbumTitle];
}

- (void)_loadWithTitle:(NSString *)aTitle artist:(NSString *)aArtist albumTitle:(NSString *)aAlbumTitle totalDuration:(NSNumber *)aTotalDuration currentTime:(NSNumber *)aCurTime{
    NSMutableDictionary *playingInfo = [NSMutableDictionary dictionaryWithDictionary:[MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo];
    playingInfo[MPMediaItemPropertyAlbumTitle] = aAlbumTitle;
    playingInfo[MPMediaItemPropertyTitle] = aTitle;
    playingInfo[MPMediaItemPropertyArtist] = aArtist;
    playingInfo[MPMediaItemPropertyPlaybackDuration] = @(aTotalDuration.doubleValue);
    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"ruyan"]];
    playingInfo[MPMediaItemPropertyArtwork]=albumArt;
    playingInfo[MPMediaItemPropertyPodcastTitle]=@"测试而已";
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = playingInfo;
}

#pragma mark - Private Function

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

// 将秒转化为具体时间
- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [[self dateFormatter] stringFromDate:d];
    return showtimeNew;
}

- (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    return dateFormatter;
}
@end
