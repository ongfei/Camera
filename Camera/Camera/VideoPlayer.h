//
//  VideoPlayer.h
//  iOS8
//
//  Created by ongfei on 2018/4/4.
//  Copyright © 2018年 ongfei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface VideoPlayer : NSObject

@property (nonatomic, strong) AVPlayer *player;

- (void)playWithUrl:(NSURL *)url superView:(UIView *)view frame:(CGRect)frame;

- (void)stopPlay;

@end
