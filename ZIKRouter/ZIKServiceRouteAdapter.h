//
//  ZIKServiceRouteAdapter.h
//  ZIKRouter
//
//  Created by zuik on 2017/8/21.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKServiceRouter.h"

NS_ASSUME_NONNULL_BEGIN

///Subclass it and register protocols for other ZIKServiceRouter in the subclass's +registerRoutableDestination with ZIKServiceRouter_registerServiceProtocol() or ZIKServiceRouter_registerConfigProtocol().
@interface ZIKServiceRouteAdapter : ZIKServiceRouter
- (nullable instancetype)initWithConfiguration:(__kindof ZIKServiceRouteConfiguration *)configuration
                           removeConfiguration:(nullable __kindof ZIKRouteConfiguration *)removeConfiguration NS_UNAVAILABLE;
- (nullable instancetype)initWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKServiceRouteConfiguration *config))configBuilder
                           removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKRouteConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (BOOL)canPerform NS_UNAVAILABLE;
- (void)performRoute NS_UNAVAILABLE;
- (void)performRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                 performerErrorHandler:(void(^ __nullable)(SEL routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
- (BOOL)canRemove NS_UNAVAILABLE;
- (void)removeRoute NS_UNAVAILABLE;
- (void)removeRouteWithSuccessHandler:(void(^ __nullable)(void))performerSuccessHandler
                performerErrorHandler:(void(^ __nullable)(SEL routeAction, NSError *error))performerErrorHandler NS_UNAVAILABLE;
+ (nullable __kindof ZIKServiceRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKServiceRouteConfiguration *config))configBuilder
                                             removeConfigure:(void(NS_NOESCAPE ^ _Nullable)( __kindof ZIKRouteConfiguration *config))removeConfigBuilder NS_UNAVAILABLE;
+ (nullable __kindof ZIKServiceRouter *)performWithConfigure:(void(NS_NOESCAPE ^)(__kindof ZIKServiceRouteConfiguration *config))configBuilder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
