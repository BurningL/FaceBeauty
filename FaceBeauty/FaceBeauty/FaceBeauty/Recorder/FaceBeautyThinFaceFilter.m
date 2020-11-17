//
//  FaceBeautyThinFaceFilter.m
//  FaceBeauty
//
//  Created by liuhongyang on 2020/11/17.
//  Copyright © 2020 Burning. All rights reserved.
//

#import "FaceBeautyThinFaceFilter.h"
#import "FaceBeautyFaceDetector.h"

NSString *const kGPUImageThinFaceFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;

 uniform int hasFace;
 uniform float facePoints[74 * 2];

 uniform highp float aspectRatio;
 uniform float thinFaceDelta;
 uniform float bigEyeDelta;

 //圓內放大
 //originPosition: {0.38518361522073974, 0.32416098202065768},
 //radius:0.300493006324773
 vec2 enlargeEye(vec2 textureCoord, vec2 originPosition, float radius, float delta) {
     
     float weight = distance(vec2(textureCoord.x, textureCoord.y / aspectRatio), vec2(originPosition.x, originPosition.y / aspectRatio)) / radius;
     
     weight = 1.0 - (1.0 - weight * weight) * delta;
     weight = clamp(weight,0.0,1.0);
     textureCoord = originPosition + (textureCoord - originPosition) * weight;
     return textureCoord;
 }

 // 曲线形变处理
 vec2 curveWarp(vec2 textureCoord, vec2 originPosition, vec2 targetPosition, float delta) {
     
     vec2 offset = vec2(0.0);
     vec2 result = vec2(0.0);
     vec2 direction = (targetPosition - originPosition) * delta;
     
     float radius = distance(vec2(targetPosition.x, targetPosition.y / aspectRatio), vec2(originPosition.x, originPosition.y / aspectRatio));
     float ratio = distance(vec2(textureCoord.x, textureCoord.y / aspectRatio), vec2(originPosition.x, originPosition.y / aspectRatio)) / radius;
     
     ratio = 1.0 - ratio;
     ratio = clamp(ratio, 0.0, 1.0);
     offset = direction * ratio;
     
     result = textureCoord - offset;
     
     return result;
 }

 vec2 thinFace(vec2 currentCoordinate){
     vec2 faceIndexs[8];
//     faceIndexs[0] = vec2(0., 45.);
//     faceIndexs[1] = vec2(10.,45.);
     faceIndexs[0] = vec2(1., 46.);
     faceIndexs[1] = vec2(9., 46.);
     faceIndexs[2] = vec2(2., 50.);
     faceIndexs[3] = vec2(8., 50.);
     faceIndexs[4] = vec2(3., 50.);
     faceIndexs[5] = vec2(7., 50.);
     faceIndexs[6] = vec2(4., 50.);
     faceIndexs[7] = vec2(6., 50.);
     
     for(int i = 0;i < 8;i++){
         int originIndex = int(faceIndexs[i].x);
         int targetIndex = int(faceIndexs[i].y);
         
         vec2 originPoint = vec2(facePoints[originIndex * 2],
                                 facePoints[originIndex *2 + 1]);
         vec2 targetPoint = vec2(facePoints[targetIndex * 2],
                                 facePoints[targetIndex *2 + 1]);
         
         currentCoordinate = curveWarp(currentCoordinate,originPoint,targetPoint,thinFaceDelta);
     }
     return currentCoordinate;
 }
 
 vec2 bigEye(vec2 currentCoordinate) {
     
     vec2 faceIndexs[2];
     faceIndexs[0] = vec2(72., 13.);
     faceIndexs[1] = vec2(73., 21.);
     
     for(int i = 0; i < 2; i++)
     {
         int originIndex = int(faceIndexs[i].x);//72
         int targetIndex = int(faceIndexs[i].y);//13
         
         vec2 originPoint = vec2(facePoints[originIndex * 2], facePoints[originIndex * 2 + 1]);//NSPoint: {0.38518361522073974, 0.32416098202065768},
         vec2 targetPoint = vec2(facePoints[targetIndex * 2], facePoints[targetIndex * 2 + 1]);//NSPoint: {0.38579181530803908, 0.3132528545029345},
         
         float radius = distance(vec2(targetPoint.x, targetPoint.y / aspectRatio), vec2(originPoint.x, originPoint.y / aspectRatio));
         //0.38579181530803908,0.556893963560772
         //0.38518361522073974,0.496798439878403
         //0.000608200087299 , 0.060095523682369
         //0.000000369907346 , 0.003611471966658
         //0.003611841874004
         //0.060098601264955
         radius = radius * 5.;//0.300493006324773
         currentCoordinate = enlargeEye(currentCoordinate, originPoint, radius, bigEyeDelta);
     }
     return currentCoordinate;
 }

 void main()
 {
     vec2 positionToUse = textureCoordinate;
     if (hasFace == 1) {
         positionToUse = thinFace(positionToUse);
         positionToUse = bigEye(positionToUse);
     }
     gl_FragColor = texture2D(inputImageTexture,positionToUse);
 }
);

@implementation FaceBeautyThinFaceFilter
{
    GLint aspectRatioUniform;
    GLint facePointsUniform;
    GLint thinFaceDeltaUniform;
    GLint bigEyeDeltaUniform;
    GLint hasFaceUniform;
}

- (instancetype)init
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageThinFaceFragmentShaderString]))
    {
        return nil;
    }
    hasFaceUniform = [filterProgram uniformIndex:@"hasFace"];
    aspectRatioUniform = [filterProgram uniformIndex:@"aspectRatio"];
    facePointsUniform = [filterProgram uniformIndex:@"facePoints"];
    thinFaceDeltaUniform = [filterProgram uniformIndex:@"thinFaceDelta"];
    bigEyeDeltaUniform = [filterProgram uniformIndex:@"bigEyeDelta"];
    
    self.thinFaceDelta = 0.0;
    self.bigEyeDelta = 0.0;
    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates
{
    NSArray *landmarks = [FaceBeautyFaceDetector shareInstance].landmarks;
    [self setUniformsWithLandmarks:landmarks];
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates];
}


- (void)setUniformsWithLandmarks:(NSArray <NSValue *>*)landmarks{
    if (!landmarks.count) {
        [self setInteger:0 forUniform:hasFaceUniform program:filterProgram];
        return;
    }
    [self setInteger:1 forUniform:hasFaceUniform program:filterProgram];
    
    CGFloat aspect = inputTextureSize.width/inputTextureSize.height;
    [self setFloat:aspect forUniform:aspectRatioUniform program:filterProgram];
    [self setFloat:self.thinFaceDelta forUniform:thinFaceDeltaUniform program:filterProgram];
    [self setFloat:self.bigEyeDelta forUniform:bigEyeDeltaUniform program:filterProgram];
    
#warning 不同机型获取的特征点数量不一样，如6s上为74个，XS上为87个
    GLsizei size = 74 * 2;
    GLfloat *facePoints = malloc(size*sizeof(GLfloat));
    
    int index = 0;
    for (NSValue *value in landmarks) {
        CGPoint point = [value CGPointValue];
        *(facePoints + index) = point.x;
        *(facePoints + index + 1) = point.y;
        index += 2;
        if (index == size) {
            break;
        }
    }
    [self setFloatArray:facePoints length:size forUniform:facePointsUniform program:filterProgram];
    free(facePoints);
}

@end
