//
//  CameraManager.h
//  iOS8
//
//  Created by ongfei on 2018/4/3.
//  Copyright © 2018年 ongfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@protocol CameraManagerDelegate <NSObject>

- (void)videoFinished:(NSURL *)url;

@end
@interface CameraManager : NSObject
//对焦的图片
@property (nonatomic, strong) UIImageView *focusView;
//拍照图
@property (nonatomic, strong) UIImage *image;
//放大比率
@property (nonatomic, assign) CGFloat scale;

//捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
@property(nonatomic, strong) AVCaptureDevice *device;
//AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
@property(nonatomic, strong) AVCaptureDeviceInput *input;

//视频输出
@property(nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
//图片输出
@property (nonatomic, strong) AVCaptureStillImageOutput *ImageOutPut;
//session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
@property(nonatomic, strong) AVCaptureSession *session;
//图像预览层，实时显示捕获的图像
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) NSURL *videoUrl;
/**
 闪光灯 默认 NO
 */
@property (nonatomic, assign) BOOL flashState;

@property (nonatomic, assign) id<CameraManagerDelegate> delegate;

- (instancetype)initWithSuperView:(UIView *)superView;
/**
 切换相机
 */
- (void)changeCamera;
/**
 拍照
 */
- (void)takePhoto:(void(^)(UIImage *img))imgBlock;
/**
 视频录制
 */
- (void)videoAction;


@end
