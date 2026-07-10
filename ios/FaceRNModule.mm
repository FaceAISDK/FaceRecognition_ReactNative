//
//  FaceRNModule.mm
//  FaceRN
//
//  This file is a duplicate. See FaceRN/FaceRNModule.m for the actual implementation.
//  统一 iOS/Android 桥接 API，参考 FaceAISDK_uniapp_UTS

#import "FaceRNModule.h"
#import <UIKit/UIKit.h>

#import "FaceAISDKReactNative-Swift.h"

@implementation FaceRNModule

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(addFaceBySDKCamera:(NSString *)faceID
                  addFacePerformanceMode:(nonnull NSNumber *)performanceMode
                  needShowConfirmDialog:(BOOL)needConfirm
                  callback:(RCTResponseSenderBlock)callback) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [FaceSDKSwiftManager showAddFaceByCamera:faceID :performanceMode :needConfirm :^(NSNumber * _Nonnull resultCode, NSString * _Nonnull feature, NSString * _Nonnull message) {
            NSString *base64Str = @"";
            if ([resultCode integerValue] == 1) {
                base64Str = [FaceSDKSwiftManager getFaceImageBase64:faceID] ?: @"";
            }
            NSString *faceFeature = feature.length > 0 ? feature : ([FaceSDKSwiftManager getiOSFaceFeature:faceID] ?: @"");
            NSDictionary *result = @{
                @"code": resultCode,
                @"message": message ?: @"",
                @"faceID": faceID ?: @"",
                @"similarity": @(0),
                @"liveness": @(0),
                @"faceFeature": faceFeature,
                @"faceBase64": base64Str
            };
            callback(@[result]);
        }];
    });
}

RCT_EXPORT_METHOD(faceVerify:(NSString *)faceID
                  threshold:(nonnull NSNumber *)threshold
                  faceLivenessType:(nonnull NSNumber *)faceLivenessType
                  motionLivenessTypes:(NSString *)motionLivenessTypes
                  motionLivenessTimeOut:(nonnull NSNumber *)motionLivenessTimeOut
                  motionLivenessSteps:(nonnull NSNumber *)motionLivenessSteps
                  allowMultiFaces:(BOOL)allowMultiFaces
                  callback:(RCTResponseSenderBlock)callback) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [FaceSDKSwiftManager showFaceVerify:faceID :threshold :faceLivenessType :motionLivenessTypes :motionLivenessTimeOut :motionLivenessSteps :^(NSNumber * _Nonnull resultCode, NSNumber * _Nonnull similarity, NSNumber * _Nonnull liveness, NSString * _Nonnull message) {
            NSString *base64Str = @"";
            NSInteger code = [resultCode integerValue];
            if (code == 1 || code == 10) {
                base64Str = [FaceSDKSwiftManager getFaceImageBase64:faceID] ?: @"";
            }
            NSDictionary *result = @{
                @"code": resultCode,
                @"message": message ?: @"",
                @"faceID": faceID ?: @"",
                @"similarity": similarity,
                @"liveness": liveness,
                @"faceFeature": @"",
                @"faceBase64": base64Str
            };
            callback(@[result]);
        }];
    });
}

RCT_EXPORT_METHOD(livenessVerify:(nonnull NSNumber *)faceLivenessType
                  motionLivenessTypes:(NSString *)motionLivenessTypes
                  motionLivenessTimeOut:(nonnull NSNumber *)motionLivenessTimeOut
                  motionLivenessSteps:(nonnull NSNumber *)motionLivenessSteps
                  allowMultiFaces:(BOOL)allowMultiFaces
                  callback:(RCTResponseSenderBlock)callback) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [FaceSDKSwiftManager showLivenessVerify:faceLivenessType :motionLivenessTypes :motionLivenessTimeOut :motionLivenessSteps :^(NSNumber * _Nonnull resultCode, NSNumber * _Nonnull liveness, NSString * _Nonnull message) {
            NSString *base64Str = @"";
            NSInteger code = [resultCode integerValue];
            if (code == 1 || code == 10) {
                base64Str = [FaceSDKSwiftManager getFaceImageBase64:@"Liveness"] ?: @"";
            }
            NSDictionary *result = @{
                @"code": resultCode,
                @"message": message ?: @"",
                @"faceID": @"",
                @"similarity": @(0),
                @"liveness": liveness,
                @"faceFeature": @"",
                @"faceBase64": base64Str
            };
            callback(@[result]);
        }];
    });
}

RCT_EXPORT_METHOD(getFaceFeature:(NSString *)faceID
                  callback:(RCTResponseSenderBlock)callback) {
    NSString *faceFeature = [FaceSDKSwiftManager getiOSFaceFeature:faceID] ?: @"";
    [FaceSDKSwiftManager isFaceFeatureExist:faceID :^(NSNumber * _Nonnull resultCode, NSString * _Nonnull msg) {
        NSDictionary *result = @{
            @"code": resultCode,
            @"message": msg,
            @"faceID": faceID ?: @"",
            @"similarity": @(0),
            @"liveness": @(0),
            @"faceFeature": faceFeature,
            @"faceBase64": @""
        };
        callback(@[result]);
    }];
}

RCT_EXPORT_METHOD(insertFaceFeature:(NSString *)faceID
                  faceFeature:(NSString *)faceFeature
                  callback:(RCTResponseSenderBlock)callback) {
    [FaceSDKSwiftManager insertFaceFeature:faceID :faceFeature :^(NSNumber * _Nonnull resultCode, NSString * _Nonnull msg) {
        NSDictionary *result = @{
            @"code": resultCode,
            @"message": msg,
            @"faceID": faceID ?: @"",
            @"similarity": @(0),
            @"liveness": @(0),
            @"faceFeature": @"",
            @"faceBase64": @""
        };
        callback(@[result]);
    }];
}

RCT_EXPORT_METHOD(addFaceBySDKImage:(NSString *)faceID
                  base64FaceImage:(NSString *)base64FaceImage
                  callback:(RCTResponseSenderBlock)callback) {
    [FaceSDKSwiftManager addFaceByBase64:faceID :base64FaceImage :^(NSNumber * _Nonnull resultCode, NSString * _Nonnull feature, NSString * _Nonnull msg) {
        NSDictionary *result = @{
            @"code": resultCode,
            @"message": msg,
            @"faceID": faceID ?: @"",
            @"similarity": @(0),
            @"liveness": @(0),
            @"faceFeature": feature ?: @"",
            @"faceBase64": @""
        };
        callback(@[result]);
    }];
}

RCT_EXPORT_METHOD(deleteFaceFeature:(NSString *)faceID
                  callback:(RCTResponseSenderBlock)callback) {
    [FaceSDKSwiftManager deleteFaceFeature:faceID];
    NSDictionary *result = @{
        @"code": @(1),
        @"message": @"Delete Success",
        @"faceID": faceID ?: @"",
        @"similarity": @(0),
        @"liveness": @(0),
        @"faceFeature": @"",
        @"faceBase64": @""
    };
    callback(@[result]);
}

@end
