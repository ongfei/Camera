//
//  ViewController.m
//  Camera
//
//  Created by ongfei on 2018/4/12.
//  Copyright © 2018年 ongfei. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>

#import <AVFoundation/AVFoundation.h>
#import "CameraManager.h"
#import "VideoPlayer.h"
#import "DealCamera.h"

#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height


@interface ViewController ()<CameraManagerDelegate>

@property (nonatomic, strong) UIView *topBar;
//录制时间的bg
@property (nonatomic, strong) UIView *topTimeBar;
//录制时间
@property (nonatomic, strong) UILabel *timeL;
@property (nonatomic, strong) UIButton *cancleBtn;
@property (nonatomic, strong) UIButton *saveBtn;
//拍照按钮
@property (nonatomic, strong) UIImageView *actionBtn;
//展示照片的img
@property (nonatomic, strong) UIImageView *imgPhoto;
//展示视频的view
@property (nonatomic, strong) UIView *playView;

@property (nonatomic, strong) CameraManager *cameraManager;
//视频播放器
@property (nonatomic, strong) VideoPlayer *videoPlayer;

//计时器
@property (nonatomic, strong) NSTimer *time;

//@property (nonatomic, strong) UIButton *picStoreBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [self prepareLayoutCamera];
    [self preapreLayoutSubviews];
    
}

- (void)preapreLayoutSubviews {
    
    self.topBar = [[UIView alloc] init];
    self.topBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.topBar];
    
    self.topTimeBar = [UIView new];
    [self.view addSubview:self.topTimeBar];
    self.topTimeBar.backgroundColor = [UIColor grayColor];
    self.topTimeBar.hidden = YES;
    
    self.timeL = [UILabel new];
    [self.topTimeBar addSubview:self.timeL];
    self.timeL.text = @"00:00:00";
    self.timeL.textAlignment = NSTextAlignmentCenter;
    
    self.imgPhoto = [[UIImageView alloc] init];
    [self.view addSubview:self.imgPhoto];
    self.imgPhoto.hidden = YES;
    
    //    self.picStoreBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    //    [self.view addSubview:self.picStoreBtn];
    //    [self.picStoreBtn setImage:[UIImage imageNamed:@"Image1"] forState:(UIControlStateNormal)];
    //    [self.picStoreBtn addTarget:self action:@selector(picStore) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *dissMissBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [self.topBar addSubview:dissMissBtn];
    [dissMissBtn setImage:[UIImage imageNamed:@"feed_more_arrow"] forState:(UIControlStateNormal)];
    [dissMissBtn addTarget:self action:@selector(dismiss) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *flashBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [self.topBar addSubview:flashBtn];
    [flashBtn setImage:[UIImage imageNamed:@"camera_flashlight_disable"] forState:(UIControlStateNormal)];
    [flashBtn setImage:[UIImage imageNamed:@"camera_flashlight_open_disable"] forState:(UIControlStateSelected)];
    [flashBtn addTarget:self action:@selector(flashBtnClick:) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *chageCBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [self.topBar addSubview:chageCBtn];
    [chageCBtn setImage:[UIImage imageNamed:@"camera_overturn_highlighted"] forState:(UIControlStateNormal)];
    [chageCBtn addTarget:self action:@selector(chageCBtnClick:) forControlEvents:(UIControlEventTouchUpInside)];
    
    self.actionBtn = [[UIImageView alloc] init];
    [self.view addSubview:self.actionBtn];
    [self.actionBtn setImage:[UIImage imageNamed:@"camera_video_background_highlighted"]];
    self.actionBtn.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.actionBtn addGestureRecognizer:tap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.actionBtn addGestureRecognizer:longPress];
    
    UIButton *cancleBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [self.view addSubview:cancleBtn];
    [cancleBtn setImage:[UIImage imageNamed:@"camera_close_highlighted"] forState:(UIControlStateNormal)];
    [cancleBtn addTarget:self action:@selector(cancle:) forControlEvents:(UIControlEventTouchUpInside)];
    self.cancleBtn = cancleBtn;
    cancleBtn.alpha = 0;
    
    UIButton *saveBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [self.view addSubview:saveBtn];
    [saveBtn setImage:[UIImage imageNamed:@"compose_guide_check_box_right"] forState:(UIControlStateNormal)];
    [saveBtn addTarget:self action:@selector(save:) forControlEvents:(UIControlEventTouchUpInside)];
    self.saveBtn = saveBtn;
    saveBtn.alpha = 0;
    
    [self.topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).offset(40);
        make.height.mas_equalTo(40);
    }];
    
    [self.imgPhoto mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    //
    self.playView = [[UIView alloc] init];
    [self.view addSubview:self.playView];
    self.playView.hidden = YES;
    
    UIButton *btn1 = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [btn1 setTitle:@"取消" forState:(UIControlStateNormal)];
    [btn1.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [self.playView addSubview:btn1];
    [btn1 addTarget:self action:@selector(videoCancle) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *btn2 = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [btn2 setTitle:@"保存" forState:(UIControlStateNormal)];
    [btn2.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [self.playView addSubview:btn2];
    [btn2 addTarget:self action:@selector(videoSave) forControlEvents:(UIControlEventTouchUpInside)];
    
    [self.playView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [btn1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.playView).offset(40);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(30);
    }];
    
    [btn2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.width.height.equalTo(btn1);
        make.right.equalTo(self.playView).offset(-40);
    }];
    
    
    [dissMissBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.topBar).offset(20);
        make.top.equalTo(self.topBar);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(40);
    }];
    
    [chageCBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.topBar.mas_right).offset(-30);
        make.top.equalTo(self.topBar);
        make.width.height.mas_equalTo(40);
    }];
    
    [flashBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(chageCBtn.mas_left).offset(-20);
        make.width.height.top.equalTo(chageCBtn);
    }];
    
    [self.actionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.mas_bottom).offset(-50);
        make.width.height.mas_equalTo(80);
    }];
    
    //    [self.picStoreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
    //        make.bottom.equalTo(self.view.mas_bottom).offset(-50);
    //        make.width.height.mas_equalTo(80);
    //        make.left.equalTo(self.view).offset(30);
    //    }];
    
    [cancleBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.actionBtn);
        make.width.height.mas_equalTo(80);
        make.centerX.equalTo(self.actionBtn);
    }];
    
    [saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.actionBtn);
        make.width.height.mas_equalTo(80);
        make.centerX.equalTo(self.actionBtn);
    }];
    
    [self.topTimeBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.view);
        make.height.mas_equalTo(60);
    }];
    
    [self.timeL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.topTimeBar);
    }];
}

- (void)tap:(UITapGestureRecognizer *)sender {
    
    [self actionBtnClick];
    
}

- (void)longPress:(UILongPressGestureRecognizer *)sender {
    
    //    NSLog(@"============");
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:{
            [self changeTopBar];
            [self startTime];
            [self.cameraManager videoAction];
        }
            break;
        case UIGestureRecognizerStateCancelled: {
            NSLog(@"UIGestureRecognizerStateCancelled");
            [self changeTopBar];
            [self.time invalidate];
            [self.cameraManager.movieFileOutput stopRecording];
        }
            break;
        case UIGestureRecognizerStateEnded: {
            [self changeTopBar];
            [self.time invalidate];
            [self.cameraManager.movieFileOutput stopRecording];
        }
            break;
            
        default:
            break;
    }
}

- (void)videoFinished:(NSURL *)url {
    
//    self.playView.backgroundColor = [UIColor orangeColor];
    self.playView.hidden = NO;

    [self.videoPlayer playWithUrl:url superView:self.playView frame:self.playView.frame];
}


- (void)prepareLayoutCamera {
    
    self.cameraManager = [[CameraManager alloc] initWithSuperView:self.view];
    self.cameraManager.delegate = self;
    //    [self.cameraManager.session setSessionPreset:AVCaptureSessionPresetPhoto];
    //开始启动
    [self.cameraManager.session startRunning];
    
}

- (VideoPlayer *)videoPlayer {
    if (!_videoPlayer) {
        _videoPlayer = [[VideoPlayer alloc] init];
    }
    return _videoPlayer;
}

#pragma mark -  ----------action----------

- (void)actionBtnClick {
    [self animationShow];
    self.topBar.hidden = YES;
    self.actionBtn.image = [UIImage imageNamed:@"camera_video_background"];
    __weak typeof(self) weakSelf = self;
    [self.cameraManager takePhoto:^(UIImage *img) {
        weakSelf.imgPhoto.image = img;
    }];
}

- (void)flashBtnClick:(UIButton *)sender {
    self.cameraManager.flashState = sender.selected;
    sender.selected = !sender.selected;
}

- (void)chageCBtnClick:(UIButton *)sender {
    [self.cameraManager changeCamera];
}

- (void)cancle:(UIButton *)sender {
    [self animationHide];
    [self.actionBtn setImage:[UIImage imageNamed:@"camera_video_background_highlighted"]];
    [self.cameraManager.session startRunning];
    self.imgPhoto.image = nil;
    self.topBar.hidden = NO;
}

- (void)picStore {
    NSLog(@"---");
}

- (void)save:(UIButton *)sender {
    __block __weak typeof(self) weakSelf = self;
    [DealCamera saveImageToPhotoAlbum:self.imgPhoto.image completion:^(BOOL isSuccess) {
        
        [weakSelf cancle:nil];
        UIAlertView *alertV = [[UIAlertView alloc] initWithTitle:@"保存" message:@"已保存到相册" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertV show];
    }];
}

- (void)videoCancle {
    self.playView.hidden = YES;
    
    NSString *path = [self.cameraManager.videoUrl path];
    
    long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    
    NSError *error;
    BOOL state = [[NSFileManager defaultManager] removeItemAtURL:self.cameraManager.videoUrl error:&error];
    
    NSLog(@"-=-=-=-=%d----%lld",state,size);
    [self.videoPlayer stopPlay];
    self.videoPlayer = nil;
}

- (void)videoSave {
    NSString *path = [self.cameraManager.videoUrl path];
    long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    
    NSLog(@"----压缩前大小%lld",size);
    
    
    __block __weak typeof(self) weakSelf = self;
    [DealCamera writeVideoToMUKAssetsGroup:self.cameraManager.videoUrl completion:^(BOOL isSuccess) {
        if (isSuccess) {
            //            BOOL state = [[NSFileManager defaultManager] removeItemAtURL:self.cameraManager.videoUrl error:nil];
            //            NSLog(@"[[][[][][--%d",state);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                weakSelf.playView.hidden = YES;
                [DealCamera videoCompressionSourceUrl:self.cameraManager.videoUrl presetName:nil videoName:@"hee.mp4" completion:^(BOOL isSuccess, NSURL *url) {
                    [DealCamera writeVideoToMUKAssetsGroup:self.cameraManager.videoUrl completion:^(BOOL isSuccess) {
                        NSLog(@"%d",isSuccess);
                        NSLog(@"%d",[DealCamera deleteFileWithPath:self.cameraManager.videoUrl.path]);
                        NSLog(@"%d",[DealCamera deleteFileWithPath:[[DealCamera getVideoDir] stringByAppendingPathComponent:@"hee.mp4"]]);
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf videoCancle];
                        });
                    }];
                }];
            });
            
        }
    }];
}

- (void)animationShow {
    
    [UIView animateWithDuration:0.23 animations:^{
        self.cancleBtn.alpha = 1;
        self.saveBtn.alpha = 1;
        self.actionBtn.alpha = 0;
        self.cancleBtn.transform = CGAffineTransformTranslate(self.cancleBtn.transform, -80, 0);
        self.saveBtn.transform = CGAffineTransformTranslate(self.saveBtn.transform, 80, 0);
    }];
}

- (void)animationHide {
    
    [UIView animateWithDuration:0.23 animations:^{
        self.cancleBtn.alpha = 0;
        self.saveBtn.alpha = 0;
        self.actionBtn.alpha = 1;
        self.cancleBtn.transform = CGAffineTransformTranslate(self.cancleBtn.transform, 80, 0);
        self.saveBtn.transform = CGAffineTransformTranslate(self.saveBtn.transform, -80, 0);
    }];
}

- (void)changeTopBar {
    self.topTimeBar.hidden = !self.topTimeBar.hidden;
    self.topBar.hidden = !self.topBar.hidden;
    self.timeL.text = @"00:00:00";
}

- (void)animationAction {
    
    NSDate *date = [[self formatDate] dateFromString:self.timeL.text];
    self.timeL.text = [[self formatDate] stringFromDate:[NSDate dateWithTimeInterval:self.time.timeInterval sinceDate:date]];
    [UIView animateWithDuration:0.5 animations:^{
        self.actionBtn.transform = CGAffineTransformScale(self.actionBtn.transform, 2, 2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            self.actionBtn.transform = CGAffineTransformScale(self.actionBtn.transform, 0.5, 0.5);
        }];
    }];
}

- (void)startTime {
    self.time = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(animationAction) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:self.time forMode:NSDefaultRunLoopMode];
}

- (NSDateFormatter *)formatDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    return formatter;
}



- (void)dismiss {
    
//    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -  ----------屏幕旋转----------

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    return UIInterfaceOrientationMaskPortrait;
    
}

@end
