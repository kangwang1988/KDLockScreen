//
//  ViewController.m
//  KDLockScreen
//
//  Created by KyleWong on 15/7/2.
//  Copyright (c) 2015年 KyleWong. All rights reserved.
//

#import "ViewController.h"
#import "KDPlayer.h"

@interface ViewController ()<KDPlayerDelegate>
@property (nonatomic,strong) KDPlayer *player;
@end

@implementation ViewController
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if(self=[super initWithCoder:aDecoder]){
        [self commonInit];
    }
    return self;
}

- (void)loadView{
    UIScreen *screen = [UIScreen mainScreen];
    UIView *view = [[UIView alloc] initWithFrame:screen.bounds];
    [view setBackgroundColor:[UIColor whiteColor]];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onPlayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"Play" forState:UIControlStateNormal];
    [view addSubview:btn];
    [btn setCenter:view.center];
    [self setView:view];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
            [self.player play];
            break;
        case UIEventSubtypeRemoteControlPause:
            [self.player pause];
            break;
        case UIEventSubtypeRemoteControlStop:
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
            break;
        default:
            break;
    }
}

- (void)commonInit{
    [self setPlayer:[KDPlayer new]];
}

- (IBAction)onPlayButtonPressed:(id)sender{
    [self.player setDelegate:self];
    [self.player loadMusicWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"dddj" ofType:@"mp3"]]];
    [self.player loadWithTitle:@"嘀嘀代驾" artist:@"嘀嘀打车" albumTitle:@"你有新订单了"];
    [self.player play];
}

- (void)setupCommands{
    MPRemoteCommandCenter *rcc = [MPRemoteCommandCenter sharedCommandCenter];
    MPFeedbackCommand *bookmarkCommand = [rcc bookmarkCommand];
    [bookmarkCommand setEnabled:YES];
    [bookmarkCommand addTarget:self action:@selector(onBookmarkEvent:)];
}

- (IBAction)onBookmarkEvent:(id)sender{
    NSLog(@"");
}

#pragma mark - KDPlayerDelegate
- (void)playerStatusFailedWithPlayer:(KDPlayer *)aPlayer{

}

- (void)playerStatusReadyToPlayWithPlayer:(KDPlayer *)aPlayer totalTime:(NSString *)totalTime{

}

- (void)playerWithCurrentTimeRefreshWithPlayer:(KDPlayer *)aPlayer currentTime:(NSString *)curTime{

}

- (void)playerWithPlayEndWithPlayer:(KDPlayer *)aPlayer{
    
}
@end