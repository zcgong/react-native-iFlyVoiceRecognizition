//
//  RNiFlyVoiceRecognizition.h
//  RNiFlyVoiceRecognizition
//
//  Created by zcgong on 16/10/9.
//  Copyright © 2016年 zcgong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCTBridgeModule.h"
#import "iflyMSC/IFlySpeechRecognizerDelegate.h"
#import "iflyMSC/IFlySpeechRecognizer.h"
@interface RNiFlyVoiceRecognizition : NSObject<RCTBridgeModule,IFlySpeechRecognizerDelegate>
@property (nonatomic, strong) IFlySpeechRecognizer* iFlyRecognizer;
@end
