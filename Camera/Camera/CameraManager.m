//
//  CameraManager.m
//  iOS8
//
//  Created by ongfei on 2018/4/3.
//  Copyright © 2018年 ongfei. All rights reserved.
//

#import "CameraManager.h"
#import "DealCamera.h"

@interface CameraManager ()<AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) UIView *superView;

@end
@implementation CameraManager

- (instancetype)initWithSuperView:(UIView *)superView {
    if (self = [super init]) {
        
        self.superView = superView;
        [self prepareLayout];
      
    }
    
    return self;
}

- (void)prepareLayout {
    
    self.scale = 1.0f;
    
    //使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    self.previewLayer.frame = CGRectMake(0, 0, self.superView.frame.size.width, self.superView.frame.size.height);
    //layer填充状态
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    //摄像头朝向
    self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    [self.superView.layer addSublayer:self.previewLayer];

    
    //创建对焦手势及对焦框
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusGesture:)];
    [self.superView addGestureRecognizer:tapGesture];
    
    //焦距捏合
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
    [self.superView addGestureRecognizer:pinch];
    
    self.focusView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    self.focusView.image = [UIImage imageNamed:@"media_focus"];
    [self.previewLayer addSublayer:self.focusView.layer];
    self.focusView.hidden = YES;
}

//调整焦距方法
- (void)pinchAction:(UIPinchGestureRecognizer*)pinch {
    float scale = pinch.scale;
    scale = self.scale + (scale - 1.f) * 0.1;
    if (scale < 1.f) {
        scale = 1.f;
    }else if (scale > 4.f){
        scale = 4.f;
    }
    
    self.scale = scale;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    __weak typeof(self) weak = self;
    [self setFocalLength:scale complete:^(BOOL success, NSError *error) {
        if (success) {
            if (pinch.state == UIGestureRecognizerStateEnded || pinch.state == UIGestureRecognizerStateCancelled) {
                weak.previewLayer.contentsScale = scale;
            }
        }else NSLog(@"%@",error);
    }];
    [CATransaction commit];
}

- (void)setFocalLength:(float)focalLength complete:(void(^)(BOOL success,NSError *error))complete {
    NSError *error;
    if([self.device lockForConfiguration:&error]){
        [self.device setVideoZoomFactor:focalLength];
        [self.device unlockForConfiguration];
        if (error) {
            if (complete) {
                complete(NO,nil);
            }
        }else {
            if (complete) {
                complete(YES,nil);
            }
        }
    }else {
        if (complete) {
            complete(NO,nil);
        }
    }
}

- (void)focusGesture:(UITapGestureRecognizer*)gesture {
    CGPoint point = [gesture locationInView:gesture.view];
    [self focusAtPoint:point];
}

- (void)focusAtPoint:(CGPoint)point{
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGPoint focusPoint = CGPointMake(point.y /size.height ,1-point.x/size.width );
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
            [self.device setFocusPointOfInterest:focusPoint];
        }
        if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.device setExposurePointOfInterest:focusPoint];
            [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.device unlockForConfiguration];
        _focusView.center = point;
        _focusView.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            _focusView.transform = CGAffineTransformMakeScale(1.25, 1.25);
        }completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                _focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                _focusView.hidden = YES;
            }];
        }];
    }
    
}

#pragma mark -  ----------lazy loading----------

- (AVCaptureSession *)session {
    if (!_session) {
        
        _session = [[AVCaptureSession alloc]init];
//        if ([_session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
//            _session.sessionPreset = AVCaptureSessionPreset1280x720;
//        }
        //        添加摄像头输出
        if ([_session canAddInput:self.input]) {
            [_session addInput:self.input];
        }
        //        添加图片输出
        if ([_session canAddOutput:self.ImageOutPut]) {
            [_session addOutput:self.ImageOutPut];
        }
        if ([_session canAddOutput:self.movieFileOutput]) {
            [_session addOutput:self.movieFileOutput];
        }
        
        //添加一个音频输入设备
        NSError *error = nil;
        AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
        AVCaptureDeviceInput *audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioCaptureDevice error:&error];
        if (error == nil) {
            [_session addInput:audioCaptureDeviceInput];
        }
    }
    return _session;
}

- (AVCaptureStillImageOutput *)ImageOutPut {
    if (!_ImageOutPut) {
        //        图片输出
        _ImageOutPut = [[AVCaptureStillImageOutput alloc] init];
    }
    return _ImageOutPut;
}

- (AVCaptureDeviceInput *)input {
    if (!_input) {
        //        摄像头输出
        NSError *err;
        _input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:&err];
    }
    return _input;
}

- (AVCaptureDevice *)device {
    if (!_device) {
        //      使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//        闪光灯自动
        if ([_device lockForConfiguration:nil]) {
            if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
                [_device setFlashMode:AVCaptureFlashModeAuto];
            }
        //自动白平衡
            if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            }
//            闪光灯属性设置两个setTorchMode  setFlashMode
            if ([_device hasTorch]) {
                [_device setTorchMode:AVCaptureTorchModeAuto];
            }
            
            [_device unlockForConfiguration];
        }
    }
    return _device;
}

- (AVCaptureMovieFileOutput *)movieFileOutput {//视频输出
    if (!_movieFileOutput) {
        _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    }
    return _movieFileOutput;
}

//- (AVCaptureMetadataOutput *)output {
//    if (!_output) {
//        //生成输出对象
//        _output = [[AVCaptureMetadataOutput alloc] init];
//    }
//    return _output;
//}
#pragma mark -  ----------闪光灯----------

- (void)setFlashState:(BOOL)flashState {
    _flashState = flashState;
    if ([_device lockForConfiguration:nil]) {
        if (flashState) {
            if ([_device isFlashModeSupported:AVCaptureFlashModeOff]) {
                [_device setFlashMode:AVCaptureFlashModeOff];
            }
        }else{
            if ([_device isFlashModeSupported:AVCaptureFlashModeOn]) {
                [_device setFlashMode:AVCaptureFlashModeOn];
            }
        }
        [_device unlockForConfiguration];
    }
}

#pragma mark -  ----------切换相机----------

- (void)changeCamera {
    
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        NSError *error;
        
        AVCaptureDevice *newCamera = nil;
        AVCaptureDeviceInput *newInput = nil;
        AVCaptureDevicePosition position = [[_input device] position];
        if (position == AVCaptureDevicePositionFront){
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
        else {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }
        
        newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        if (newInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:_input];
            if ([self.session canAddInput:newInput]) {
                [self.session addInput:newInput];
                self.input = newInput;
                
            } else {
                [self.session addInput:self.input];
            }
            
            [self.session commitConfiguration];
            
        } else if (error) {
            NSLog(@"toggle carema failed, error = %@", error);
        }
        
    }
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
//    if (@available(iOS 10.0, *)) {
//        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInTelephotoCamera mediaType:AVMediaTypeVideo position:position];
//    } else {
//        // Fallback on earlier versions
//    }

    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
}

#pragma mark -  ----------拍照----------

- (void)takePhoto:(void(^)(UIImage *img))imgBlock {
    
    AVCaptureConnection * videoConnection = [self.ImageOutPut connectionWithMediaType:AVMediaTypeVideo];
//    防抖
    if ([videoConnection isVideoStabilizationSupported ]) {
        videoConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
    }
  
    if (!videoConnection) {
        NSLog(@"take photo failed!");
        return;
    }
    
    [self.ImageOutPut captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [UIImage imageWithData:imageData];
        [self.session stopRunning];
        self.image = image;
        imgBlock(image);
        //        self.imageView = [[UIImageView alloc]initWithFrame:self.previewLayer.frame];
        //        [self.view insertSubview:_imageView belowSubview:_PhotoButton];
        //        self.imageView.layer.masksToBounds = YES;
        //        self.imageView.image = _image;
        NSLog(@"image size = %@",NSStringFromCGSize(image.size));
    }];
}

- (void)saveImageToPhotoAlbum:(UIImage *)savedImage {
    if (savedImage == nil) {
        return;
    }
    // 判断授权状态
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            
            // 保存相片到相机胶卷
            __block PHObjectPlaceholder *createdAsset = nil;
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                createdAsset = [PHAssetCreationRequest creationRequestForAssetFromImage:savedImage].placeholderForCreatedAsset;
            } error:&error];
            
            if (error) {
                NSLog(@"保存失败：%@", error);
//                if (completion) {
//                    completion(NO);
//                }
                return;
            }else {
//                if (completion) {
//                    completion(YES);
//                }
            }
        });
    }];
}

- (void)writeVideoToMUKAssetsGroup:(NSURL *)videoURL completion:(void(^)(BOOL isSuccess))completion {
    PHAuthorizationStatus oldStatus = [PHPhotoLibrary authorizationStatus];
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status)
            {
                case PHAuthorizationStatusAuthorized://权限打开
                {
                    //                    //获取所有自定义相册
                    //                    PHFetchResult *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
                    //                    //筛选
                    //                    __block PHAssetCollection *simoCollection = nil;
                    //                    __block NSString *collectionID = nil;
                    //                    for (PHAssetCollection *collection in collections)  {
                    //                        if ([collection.localizedTitle isEqualToString:kAssetsGroup]) {
                    //                            simoCollection = collection;
                    //                            break;
                    //                        }
                    //                    }
                    //                    if (!simoCollection) {
                    //                        //创建相册
                    //                        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    //                            collectionID = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:kAssetsGroup].placeholderForCreatedAssetCollection.localIdentifier;
                    //                        } error:nil];
                    //                        //取出
                    //                        simoCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionID] options:nil].firstObject;
                    //                    }
                    //保存图片
                    __block NSString *assetId = nil;
                    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        if (@available(iOS 9.0, *)) {
                            assetId = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:videoURL].placeholderForCreatedAsset.localIdentifier;
                        } else {
                            // Fallback on earlier versions
                        }
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"视频保存橡胶相册失败");
                            if (completion) completion(NO);
                            return ;
                        }else {
                            if (completion) completion(success);
                        }
                        //                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                        //                            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:simoCollection];
                        //                            PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
                        //                            // 添加图片到相册中
                        //                            [request addAssets:@[asset]];
                        //
                        //                        } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        //                            if (error) {
                        //                                PGGLog(@"视频保存自定义相册失败");
                        //                            }
                        //                            if (completion) completion(success);
                        //                        }];
                    }];
                    
                    break;
                }
                case PHAuthorizationStatusDenied:
                case PHAuthorizationStatusRestricted:
                {
                    if (oldStatus == PHAuthorizationStatusNotDetermined) {
                        return;
                    }
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                    message:@"请在设置>隐私>相册中开启权限"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"知道了"
                                                          otherButtonTitles:nil, nil];
                    [alert show];
                    break;
                }
                default:
                    break;
            }
        });
    }];
}

#pragma mark - 视频录制事件
- (void)videoAction {

    AVCaptureConnection *videoConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
//设置捕捉视频方向
    if([videoConnection isVideoOrientationSupported])  {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
//    预览图层和视频方向保持一致
//    videoConnection.videoOrientation = [self.previewLayer connection].videoOrientation;
    //    防抖
//    if ([videoConnection isVideoStabilizationSupported ]) {
//        videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
//    }
    
    //创建视频文件路径
    NSString *prefix = [NSString stringWithFormat:@"%@",[DealCamera stringFromeNow]];
    
    NSString *fileName = [NSString stringWithFormat:@"%@.mp4",prefix];
    NSString *filePath = [[DealCamera getVideoDir] stringByAppendingPathComponent:fileName];
    [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:filePath] recordingDelegate:self];
//        //播放开始提示音
//    AudioServicesPlaySystemSound(1117);

}


#pragma mark -  ----------video delegate----------

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    self.videoUrl = outputFileURL;

    NSLog(@"视频录制完成");
    if ([self.delegate respondsToSelector:@selector(videoFinished:)]) {
        [self.delegate videoFinished:outputFileURL];
    }
    //1、保存图库
//    [DealCamera writeVideoToMUKAssetsGroup:outputFileURL completion:nil];
    //2.预览显示
    _image = [DealCamera getVideoImage:outputFileURL];
//    self.previewBtn.userInteractionEnabled = YES;
//    [self.previewBtn setImage:[UIImage imageNamed:@"media_video_small"] forState:UIControlStateNormal];
//    [self.previewBtn setBackgroundImage:_previewImage forState:UIControlStateNormal];
    //3.代理回传
    NSDictionary *dic = @{UIImagePickerControllerMediaURL:outputFileURL};
//    AudioServicesPlaySystemSound(1118);
    NSLog(@"%@---",dic);
//    if ([self.delegate respondsToSelector:@selector(mediaCaptureController:didFinishPickingMediaWithInfo:)]) {
//        [self.delegate mediaCaptureController:self didFinishPickingMediaWithInfo:dic];
//    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"视频开始录制");
}

@end
