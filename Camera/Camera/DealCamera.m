//
//  DealCamera.m
//  iOS8
//
//  Created by ongfei on 2018/4/3.
//  Copyright © 2018年 ongfei. All rights reserved.
//

#import "DealCamera.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@implementation DealCamera

+ (NSString *)getDocumentDir {
    NSArray *searchPaths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];
    return documentPath;
}

+ (NSString *)getVideoDir {
    NSString *docDir = [self getDocumentDir];
    NSString *videoDir = [docDir stringByAppendingPathComponent:@"Video"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:videoDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:videoDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return videoDir;
}

+ (NSString *)stringFromeNow {
    
    NSDate *detaildate =[NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    dateFormatter.timeZone = [NSTimeZone systemTimeZone];
    
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *timeString = [dateFormatter stringFromDate:detaildate];
    return timeString;
}

+ (NSString *)getTempPicDir {
    NSString *docDir = [self getDocumentDir];
    NSString *picDir = [docDir stringByAppendingPathComponent:@"TempPic"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:picDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:picDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return picDir;
}

+ (UIImage *)getVideoImage:(NSURL *)videoURL {
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:videoURL options:opts];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    NSError *error = nil;
    CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(10, 10) actualTime:NULL error:&error];
    UIImage *image = [UIImage imageWithCGImage: img];
    return image;
}

+ (void)saveImageToPhotoAlbum:(UIImage *)savedImage completion:(void(^)(BOOL isSuccess))completion {
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
                if (completion) {
                    completion(NO);
                }
                return;
            }else {
                if (completion) {
                    completion(YES);
                }
            }
        });
    }];
}

+ (void)writeVideoToMUKAssetsGroup:(NSURL *)videoURL completion:(void(^)(BOOL isSuccess))completion {
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

+ (BOOL)deleteFileWithPath:(NSString *)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }else {
        return YES;
    }

}

//压缩
+ (void)videoCompressionSourceUrl:(NSURL *)url presetName:(NSString *)presetName videoName:(NSString *)name completion:(void(^)(BOOL isSuccess, NSURL *url))completion {
    // 创建AVAsset对象
    AVAsset* asset = [AVAsset assetWithURL:url];
    /*
     创建AVAssetExportSession对象
     压缩的质量
     AVAssetExportPresetLowQuality 最low的画质最好不要选择实在是看不清楚
     AVAssetExportPresetMediumQuality 使用到压缩的话都说用这个
     AVAssetExportPresetHighestQuality 最清晰的画质
     */
    AVAssetExportSession * session = [[AVAssetExportSession alloc]
                                      initWithAsset:asset presetName:presetName == nil ?  AVAssetExportPresetMediumQuality : presetName];
    //优化网络
    session.shouldOptimizeForNetworkUse = YES;
    //转换后的格式
    //拼接输出文件路径 为了防止同名 可以根据日期拼接名字 或者对名字进行MD5加密
    NSString* path = [[self getVideoDir]
                      stringByAppendingPathComponent:name];
    //判断文件是否存在，如果已经存在删除
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    //设置输出路径
    session.outputURL = [NSURL fileURLWithPath:path];
    //设置输出类型 这里可以更改输出的类型 具体可以看文档描述
    session.outputFileType = AVFileTypeMPEG4;
    [session exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"%@",[NSThread currentThread]);
        //压缩完成
        if(session.status == AVAssetExportSessionStatusCompleted) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"导出完成");
                long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
                
                NSLog(@"压缩完毕,压缩后大小=== %lld --- %@",size);
                
                if (completion) completion(YES, [NSURL URLWithString:path]);
                
            });
        }else {
            if (completion) completion(NO, nil);
        }
    }];
    
}

+ (UIImage *)imageCompression:(UIImage *)sourceImg size:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [sourceImg drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

+ (UIImage *)imageCompression:(UIImage *)sourceImg rate:(NSInteger)rate {
    NSData *data = UIImageJPEGRepresentation(sourceImg, rate);
    UIImage *resultImage = [UIImage imageWithData:data];
    return resultImage;
}

@end
