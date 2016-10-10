//
//  RNiFlyVoiceRecognizition.m
//  RNiFlyVoiceRecognizition
//
//  Created by zcgong on 16/10/9.
//  Copyright © 2016年 zcgong. All rights reserved.
//

#import "RNiFlyVoiceRecognizition.h"
#import "iflyMSC/IFlyMSC.h"
#import "IATConfig.h"
#import "ISRDataHelper.h"
#import "RCTEventDispatcher.h"
@implementation RNiFlyVoiceRecognizition
RCT_EXPORT_MODULE();
@synthesize bridge = _bridge;
- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(config:(NSString*)appkey){
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",appkey];
    //所有服务启动前，需要确保执行createUtility
    [IFlySpeechUtility createUtility:initString];
}

RCT_EXPORT_METHOD(startListening) {
    [self.iFlyRecognizer startListening];
}

RCT_EXPORT_METHOD(stopListening) {
    [self.iFlyRecognizer stopListening];
}

- (void) onError:(IFlySpeechError *) errorCode {
    NSDictionary* errorDic = @{@"errorCode":@(errorCode.errorCode),@"msg":errorCode.errorDesc};
    [self.bridge.eventDispatcher sendAppEventWithName:@"onError" body:errorDic];
}

- (void) onResults:(NSArray *) results isLast:(BOOL)isLast {
    if (results && results.count > 0) {
        NSMutableString *resultString = [[NSMutableString alloc] init];
        NSDictionary *dic = results[0];
        for (NSString *key in dic) {
            [resultString appendFormat:@"%@",key];
        }
        NSString * resultFromJson =  [ISRDataHelper stringFromJson:resultString];
        NSLog(@"resultFromJson=%@",resultFromJson);
        [self.bridge.eventDispatcher sendAppEventWithName:@"onResults" body:@{@"results":resultFromJson,@"isLast":@(isLast)}];
    }
}

/*!
 *  音量变化回调
 *    在录音过程中，回调音频的音量。
 *
 *  @param volume -[out] 音量，范围从0-30
 */
- (void) onVolumeChanged: (int)volume {
    [self.bridge.eventDispatcher sendAppEventWithName:@"onVolumeChanged" body:@{@"volume":@(volume)}];
}

/*!
 *  开始录音回调
 *  当调用了`startListening`函数之后，如果没有发生错误则会回调此函数。
 *  如果发生错误则回调onError:函数
 */
- (void) onBeginOfSpeech {
    [self.bridge.eventDispatcher sendAppEventWithName:@"onBeginOfSpeech" body:nil];
}

/*!
 *  停止录音回调
 *   当调用了`stopListening`函数或者引擎内部自动检测到断点，如果没有发生错误则回调此函数。
 *  如果发生错误则回调onError:函数
 */
- (void) onEndOfSpeech {
    [self.bridge.eventDispatcher sendAppEventWithName:@"onEndOfSpeech" body:nil];
}

/*!
 *  取消识别回调
 *    当调用了`cancel`函数之后，会回调此函数，在调用了cancel函数和回调onError之前会有一个
 *  短暂时间，您可以在此函数中实现对这段时间的界面显示。
 */
- (void) onCancel {
    [self.bridge.eventDispatcher sendAppEventWithName:@"onCancel" body:nil];
}

- (IFlySpeechRecognizer *)iFlyRecognizer {
    if (!_iFlyRecognizer) {
        _iFlyRecognizer = [IFlySpeechRecognizer sharedInstance];
        [_iFlyRecognizer setDelegate:self];
        //设置sdk的工作路径
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [paths objectAtIndex:0];
        [IFlySetting setLogFilePath:cachePath];
        [self.iFlyRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
        
        //设置听写模式
        [self.iFlyRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
        
        
        IATConfig *instance = [IATConfig sharedInstance];
        //设置最长录音时间
        [self.iFlyRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
        //设置后端点
        [self.iFlyRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
        //设置前端点
        [self.iFlyRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
        //网络等待时间
        [self.iFlyRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
        
        //设置采样率，推荐使用16K
        [self.iFlyRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
        if ([instance.language isEqualToString:[IATConfig chinese]]) {
            //设置语言
            [self.iFlyRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
            //设置方言
            [self.iFlyRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
        }else if ([instance.language isEqualToString:[IATConfig english]]) {
            //设置语言
            [self.iFlyRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
        }
        //设置是否返回标点符号
        [self.iFlyRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
        [self.iFlyRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
        
        //设置听写结果格式为json
        [self.iFlyRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
    }
    return _iFlyRecognizer;
}

@end
