//
//  FaceBeautyFaceDetector.m
//  FaceBeauty
//
//  Created by liuhongyang on 2020/11/17.
//  Copyright © 2020 Burning. All rights reserved.
//

#import "FaceBeautyFaceDetector.h"
#import <Vision/Vision.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@implementation FaceBeautyFaceDetector

static FaceBeautyFaceDetector *detector;

+ (instancetype)shareInstance
{
    if (detector == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            detector = [[FaceBeautyFaceDetector alloc] init];
        });
    }
    return detector;
}

- (void)getLandmarksFromPixelBuffer:(CVPixelBufferRef)pixelBuffer orientation:(CGImagePropertyOrientation)orientation complete:(void(^)(NSArray *landmarks))complete
{
    if (@available(iOS 11.0,*)) {
        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pixelBuffer orientation:orientation options:@{}];
        VNDetectFaceLandmarksRequest *landmarksRequest = [[VNDetectFaceLandmarksRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
            [self handleWithObservations:request.results complete:complete];
        }];
        [handler performRequests:@[landmarksRequest] error:nil];
    }else{
        
    }
}

- (void)handleWithObservations:(NSArray *)observations complete:(void(^)(NSArray *landmarks))complete{
    if (@available(iOS 11.0,*)) {
        if (!observations.count) {
            !complete?:complete(nil);
            return;
        }
        VNFaceObservation *observation = observations.firstObject;
        VNFaceLandmarks *landmarks = observation.landmarks;
        
        CGFloat boxX = observation.boundingBox.origin.x;
        CGFloat boxY = observation.boundingBox.origin.y;
        CGFloat boxW = observation.boundingBox.size.width;
        CGFloat boxH = observation.boundingBox.size.height;
        
        NSMutableArray *array = [NSMutableArray array];
        [self getAllkeyWithClass:VNFaceLandmarks2D.class isProperty:YES block:^(NSString *key) {
            if ([key isEqualToString:@"allPoints"] ||
                [key isEqualToString:@"constellation"] ||
                [key isEqualToString:@"occlusionFlagsPerPoint"] ||
                [key isEqualToString:@"precisionEstimatesPerPoint"]) {
                return;
            }
            VNFaceLandmarkRegion2D *region2D = [landmarks valueForKey:key];
            for (int i= 0; i<region2D.pointCount; i++) {
                CGPoint point = region2D.normalizedPoints[i];
                CGPoint center = CGPointMake(boxX + boxW * point.x,
                                             1 - (boxY + boxH * point.y));
                [array addObject:[NSValue valueWithCGPoint:center]];
                [FaceBeautyFaceDetector shareInstance].landmarks = [array copy];
                !complete?:complete([array copy]);
            }
        }];
    }
}

// 获取对象属性keys
- (NSArray *)getAllkeyWithClass:(Class)class isProperty:(BOOL)property block:(void(^)(NSString *key))block{
    
    NSMutableArray *keys = @[].mutableCopy;
    unsigned int outCount = 0;
    
    Ivar *vars = NULL;
    objc_property_t *propertys = NULL;
    const char *name;
    
    if (property) {
        propertys = class_copyPropertyList(class, &outCount);
    }else{
        vars = class_copyIvarList(class, &outCount);
    }
    
    for (int i = 0; i < outCount; i ++) {
        
        if (property) {
            objc_property_t property = propertys[i];
            name = property_getName(property);
        }else{
            Ivar var = vars[i];
            name = ivar_getName(var);
        }
        
        NSString *key = [NSString stringWithUTF8String:name];
        block(key);
    }
    free(vars);
    return keys.copy;
}

@end
