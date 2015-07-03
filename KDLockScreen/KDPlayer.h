//
//  KDPlayer.h
//  KDLockScreen
//
//  Created by KyleWong on 15/7/2.
//  Copyright (c) 2015年 KyleWong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>
#import <MediaPlayer/MPRemoteCommandCenter.h>
#import <MediaPlayer/MPRemoteCommand.h>
#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVPlayerItem.h>
#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVTime.h>
#import <AVFoundation/AVAudioSession.h>

@class KDPlayer;

@protocol KDPlayerDelegate <NSObject>
- (void)playerWithCurrentTimeRefreshWithPlayer:(KDPlayer *)aPlayer currentTime:(NSString *)curTime;
- (void)playerWithPlayEndWithPlayer:(KDPlayer *)aPlayer;
- (void)playerStatusReadyToPlayWithPlayer:(KDPlayer *)aPlayer totalTime:(NSString *)totalTime;
- (void)playerStatusFailedWithPlayer:(KDPlayer *)aPlayer;
@end

@interface KDPlayer : NSObject
@property (nonatomic,assign) id<KDPlayerDelegate> delegate;
- (void)loadMusicWithURL:(NSURL *)aURL;
- (void)loadWithTitle:(NSString *)aTitle artist:(NSString *)aArtist albumTitle:(NSString *)aAlbumTitle;
- (void)play;
- (void)pause;
@property (nonatomic,assign) BOOL isPlaying;
@end
