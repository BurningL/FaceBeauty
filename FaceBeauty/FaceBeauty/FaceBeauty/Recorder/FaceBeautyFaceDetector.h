//
//  FaceBeautyFaceDetector.h
//  FaceBeauty
//
//  Created by liuhongyang on 2020/11/17.
//  Copyright © 2020 Burning. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FaceBeautyFaceDetector : NSObject

+ (instancetype)shareInstance;

@property (nonatomic,strong) NSArray *landmarks;

- (void)getLandmarksFromPixelBuffer:(CVPixelBufferRef)pixelBuffer orientation:(CGImagePropertyOrientation)orientation complete:(void(^)(NSArray *landmarks))complete;

@end

NS_ASSUME_NONNULL_END
