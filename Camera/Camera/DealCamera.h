//
//  DealCamera.h
//  iOS8
//
//  Created by ongfei on 2018/4/3.
//  Copyright © 2018年 ongfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DealCamera : NSObject

/**
 Document路径
 */
+ (NSString *)getDocumentDir;

/**
 获取视频文件夹路径
 */
+ (NSString *)getVideoDir;

/**
 图片临时路径（用于图像处理）
 */
+ (NSString *)getTempPicDir;

/**
 当前时间生成字符串
 */
+ (NSString *)stringFromeNow;

/**
 删除文件
 */
+ (BOOL)deleteFileWithPath:(NSString *)path;

/**
 产生视频缩略图
 */
+ (UIImage *)getVideoImage:(NSURL *)videoURL;

/**
 保存视频到相册
 */
+ (void)writeVideoToMUKAssetsGroup:(NSURL *)videoURL completion:(void(^)(BOOL isSuccess))completion;

/**
 保存图片到相册
 */
+ (void)saveImageToPhotoAlbum:(UIImage *)savedImage completion:(void(^)(BOOL isSuccess))completion;

/**
 视频压缩
 @param url 视频url
 @param presetName 压缩分辨率 默认 AVAssetExportPresetMediumQuality
 @param name 压缩之后名字 例如 a.mp4
 */
+ (void)videoCompressionSourceUrl:(NSURL *)url presetName:(NSString *)presetName videoName:(NSString *)name completion:(void(^)(BOOL isSuccess, NSURL *url))completion;

/**
 通过尺寸压缩图片
 @param sourceImg 原图
 @param size 压缩后大小
 */
+ (UIImage *)imageCompression:(UIImage *)sourceImg size:(CGSize)size;

/**
 通过比率压缩图片
 @param sourceImg 原图
 @param rate 压缩比率
 */
+ (UIImage *)imageCompression:(UIImage *)sourceImg rate:(NSInteger)rate;

@end
