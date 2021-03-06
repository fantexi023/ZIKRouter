//
//  ZIKCompatibleAlertConfigProtocol.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/6.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZIKRouter/ZIKViewConfigRoutable.h>

NS_ASSUME_NONNULL_BEGIN

#define _ZIKCompatibleAlertConfigProtocol_ (Protocol<ZIKViewConfigRoutable> *)@protocol(ZIKCompatibleAlertConfigProtocol)
@protocol ZIKCompatibleAlertConfigProtocol <ZIKViewConfigRoutable>
@property(nonatomic,copy) NSString *title;
@property(nullable,nonatomic,copy) NSString *message;
- (void)addCancelButtonTitle:(NSString *)cancelButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addOtherButtonTitle:(NSString *)otherButtonTitle handler:(void (^__nullable)(void))handler;
- (void)addDestructiveButtonTitle:(NSString *)destructiveButtonTitle handler:(void (^)(void))handler;
@end

NS_ASSUME_NONNULL_END
