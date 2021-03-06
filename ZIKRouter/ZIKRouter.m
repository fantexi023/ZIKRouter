//
//  ZIKRouter.m
//  ZIKRouter
//
//  Created by zuik on 2017/3/2.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKRouter.h"
#import <objc/runtime.h>

NSString *kZIKRouterErrorDomain = @"kZIKRouterErrorDomain";

@interface ZIKRouteConfiguration ()

@end

@interface ZIKRouter () {
    dispatch_semaphore_t _stateSema;
}
@property (nonatomic, assign) ZIKRouterState state;
@property (nonatomic, assign) ZIKRouterState preState;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, copy) __kindof ZIKRouteConfiguration *configuration;
@property (nonatomic, copy, nullable) __kindof ZIKRouteConfiguration *removeConfiguration;
@property (nonatomic, weak) id destination;
@end

@implementation ZIKRouter

- (instancetype)initWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration removeConfiguration:(nullable __kindof ZIKRouteConfiguration *)removeConfiguration {
    NSParameterAssert(configuration);
    NSAssert([self conformsToProtocol:@protocol(ZIKRouterProtocol)], @"%@ not conforms to ZIKRouterProtocol",[self class]);
    
    if (self = [super init]) {
        _state = ZIKRouterStateNotRoute;
        _configuration = [configuration copy];
        _removeConfiguration = [removeConfiguration copy];
        _stateSema = dispatch_semaphore_create(1);
    }
    return self;
}

- (instancetype)initWithConfigure:(void(^)(__kindof ZIKRouteConfiguration * configuration))configBuilder removeConfigure:(void(^ _Nullable)( __kindof ZIKRouteConfiguration *configuration))removeConfigBuilder {
    NSParameterAssert(configBuilder);
    ZIKRouteConfiguration *configuration = [[self class] defaultRouteConfiguration];
    if (configBuilder) {
        configBuilder(configuration);
    }
    ZIKRouteConfiguration *removeConfiguration;
    if (removeConfigBuilder) {
        removeConfiguration = [[self class] defaultRemoveConfiguration];
        removeConfigBuilder(removeConfiguration);
    }
    return [self initWithConfiguration:configuration removeConfiguration:removeConfiguration];
}

- (void)attachDestination:(id)destination {
    NSParameterAssert(destination);
//    NSAssert(!self.destination, @"destination exists!");
    if (destination) {
        self.destination = destination;
    }
}

- (void)notifyRouteState:(ZIKRouterState)state {
    dispatch_semaphore_wait(_stateSema, DISPATCH_TIME_FOREVER);
    ZIKRouterState oldState = self.state;
    self.preState = oldState;
    self.state = state;
    
    if (self._nocopy_configuration.stateNotifier) {
        self._nocopy_configuration.stateNotifier(oldState, state);
    }
    
    dispatch_semaphore_signal(_stateSema);
}

- (BOOL)canPerform {
    return YES;
}

- (void)performRoute {
    [self performRouteWithSuccessHandler:self._nocopy_configuration.performerSuccessHandler
                      performerErrorHandler:self._nocopy_configuration.performerErrorHandler];
}

- (void)performRouteWithSuccessHandler:(void(^)(void))performerSuccessHandler
                    performerErrorHandler:(void(^)(SEL routeAction, NSError *error))performerErrorHandler {
    NSAssert(self._nocopy_configuration, @"router must has configuration");
    ZIKRouteConfiguration *configuration = self._nocopy_configuration;
    if (performerSuccessHandler) {
        configuration.performerSuccessHandler = performerSuccessHandler;
    }
    if (performerErrorHandler) {
        configuration.performerErrorHandler = performerErrorHandler;
    }
    [self performWithConfiguration:configuration];
}

- (void)performWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    NSParameterAssert(configuration);
    
    id destination = [self destinationWithConfiguration:configuration];
    self.destination = destination;
    [self performRouteOnDestination:destination configuration:configuration];
}

+ (__kindof ZIKRouter *)performRoute {
    ZIKRouter *router = [[self alloc] initWithConfiguration:[self defaultRouteConfiguration] removeConfiguration:nil];
    [router performRoute];
    return router;
}

+ (__kindof ZIKRouter *)performWithConfigure:(void(^)(__kindof ZIKRouteConfiguration *configuration))configBuilder {
    NSParameterAssert(configBuilder);
    ZIKRouter *route = [[self alloc] initWithConfigure:configBuilder removeConfigure:nil];
    [route performRoute];
    return route;
}

+ (__kindof ZIKRouter *)performWithConfigure:(void(^)(__kindof ZIKRouteConfiguration *configuration))configBuilder removeConfigure:(void(^)( __kindof ZIKRouteConfiguration * configuration))removeConfigBuilder {
    NSParameterAssert(configBuilder);
    ZIKRouter *route = [[self alloc] initWithConfigure:configBuilder removeConfigure:removeConfigBuilder];
    [route performRoute];
    return route;
}

- (BOOL)canRemove {
    return YES;
}

- (void)removeRoute {
    [self removeRouteWithSuccessHandler:nil performerErrorHandler:nil];
}

- (void)removeRouteWithSuccessHandler:(void(^)(void))performerSuccessHandler
                   performerErrorHandler:(void(^)(SEL routeAction, NSError *error))performerErrorHandler {
    ZIKRouteConfiguration *configuration = self._nocopy_removeConfiguration;
    if (!configuration) {
        configuration = [[self class] defaultRemoveConfiguration];
    }
    if (performerSuccessHandler) {
        configuration.performerSuccessHandler = performerSuccessHandler;
    }
    if (performerErrorHandler) {
        configuration.performerErrorHandler = performerErrorHandler;
    }
    [self removeDestination:self.destination removeConfiguration:configuration];
}

#pragma mark ZIKRouterProtocol

- (void)performRouteOnDestination:(id)destination configuration:(__kindof ZIKRouteConfiguration *)configuration {
    NSAssert(NO, @"ZIKRouter: %@ not conforms to ZIKRouterProtocol!",[self class]);
}

- (void)removeDestination:(id)destination removeConfiguration:(__kindof ZIKRouteConfiguration *)removeConfiguration {
    NSAssert(NO, @"ZIKRouter: %@ not conforms to ZIKRouterProtocol!",[self class]);
}

- (id)destinationWithConfiguration:(__kindof ZIKRouteConfiguration *)configuration {
    NSAssert(NO, @"ZIKRouter: %@ not conforms to ZIKRouterProtocol!",[self class]);
    return nil;
}

+ (ZIKRouteConfiguration *)defaultRouteConfiguration {
    NSAssert(NO, @"ZIKRouter: %@ not conforms to ZIKRouterProtocol!",[self class]);
    return nil;
}

+ (ZIKRouteConfiguration *)defaultRemoveConfiguration {
    NSAssert(NO, @"ZIKRouter: %@ not conforms to ZIKRouterProtocol!",[self class]);
    return nil;
}

+ (BOOL)completeSynchronously {
    return YES;
}

#pragma mark Error Handle

+ (NSString *)errorDomain {
    return kZIKRouterErrorDomain;
}

+ (NSError *)errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo {
    return [NSError errorWithDomain:[self errorDomain] code:code userInfo:userInfo];
}

+ (NSError *)errorWithCode:(NSInteger)code localizedDescription:(NSString *)description {
    NSParameterAssert(description);
    return [NSError errorWithDomain:[self errorDomain] code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

+ (NSError *)errorWithCode:(NSInteger)code localizedDescriptionFormat:(NSString *)format ,... {
    va_list argList;
    va_start(argList, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    return [NSError errorWithDomain:[self errorDomain] code:code userInfo:@{NSLocalizedDescriptionKey:description}];
}

- (void)notifySuccessWithAction:(SEL)routeAction {
    [self notifySuccessToProviderWithAction:routeAction];
    [self notifySuccessToPerformerWithAction:routeAction];
}

- (void)notifyError:(NSError *)error routeAction:(SEL)routeAction {
    [self notifyErrorToProvider:error routeAction:routeAction];
    [self notifyErrorToPerformer:error routeAction:routeAction];
}

- (void)notifySuccessToProviderWithAction:(SEL)routeAction {
    NSParameterAssert(routeAction);
    ZIKRouteConfiguration *configuration;
    if (routeAction == @selector(performRoute)) {
        configuration = self._nocopy_configuration;
    } else if (routeAction == @selector(removeRoute)) {
        configuration = self._nocopy_removeConfiguration;
    } else {
        configuration = self._nocopy_configuration;
    }
    
    if (configuration.providerSuccessHandler) {
        configuration.providerSuccessHandler();
    }
}

- (void)notifyErrorToProvider:(NSError *)error routeAction:(SEL)routeAction {
    NSParameterAssert(error);
    NSParameterAssert(routeAction);
    self.error = error;
    if (!self._nocopy_configuration.providerErrorHandler) {
        return;
    }
    if ([NSThread isMainThread]) {
        self._nocopy_configuration.providerErrorHandler(routeAction, error);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self._nocopy_configuration.providerErrorHandler(routeAction, error);
        });
    }
}

- (void)notifySuccessToPerformerWithAction:(SEL)routeAction {
    NSParameterAssert(routeAction);
    
    ZIKRouteConfiguration *configuration;
    if (routeAction == @selector(performRoute)) {
        configuration = self._nocopy_configuration;
    } else if (routeAction == @selector(removeRoute)) {
        configuration = self._nocopy_removeConfiguration;
    } else {
        configuration = self._nocopy_configuration;
    }
    
    if (configuration.performerSuccessHandler) {
        configuration.performerSuccessHandler();
        configuration.performerSuccessHandler = nil;
    }
    if (configuration.performerErrorHandler) {
        configuration.performerErrorHandler = nil;
    }
}

- (void)notifyErrorToPerformer:(NSError *)error routeAction:(SEL)routeAction {
    NSParameterAssert(error);
    NSParameterAssert(routeAction);
    
    self.error = error;
    ZIKRouteConfiguration *configuration;
    if (routeAction == @selector(performRoute)) {
        configuration = self._nocopy_configuration;
    } else if (routeAction == @selector(removeRoute)) {
        configuration = self._nocopy_removeConfiguration;
    } else {
        configuration = self._nocopy_configuration;
    }
    
    if (configuration.performerErrorHandler) {
        configuration.performerErrorHandler(routeAction, error);
        configuration.performerErrorHandler = nil;
    }
    if (configuration.performerSuccessHandler) {
        configuration.performerSuccessHandler = nil;
    }    
}

#pragma mark Getter/Setter

- (__kindof ZIKRouteConfiguration*)configuration {
    return [_configuration copy];
}

- (__kindof ZIKRouteConfiguration*)_nocopy_configuration {
    return _configuration;
}

- (__kindof ZIKRouteConfiguration*)removeConfiguration {
    return [_removeConfiguration copy];
}

- (__kindof ZIKRouteConfiguration*)_nocopy_removeConfiguration {
    return _removeConfiguration;
}

#pragma mark Debug

+ (NSString *)descriptionOfState:(ZIKRouterState)state {
    NSString *description;
    switch (state) {
        case ZIKRouterStateNotRoute:
            description = @"NotRoute";
            break;
        case ZIKRouterStateRouting:
            description = @"Routing";
            break;
        case ZIKRouterStateRouted:
            description = @"Routed";
            break;
        case ZIKRouterStateRouteFailed:
            description = @"RouteFailed";
            break;
        case ZIKRouterStateRemoving:
            description = @"Removing";
            break;
        case ZIKRouterStateRemoved:
            description = @"Removed";
            break;
        case ZIKRouterStateRemoveFailed:
            description = @"RemoveFailed";
            break;
    }
    return description;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: state:%@, destinaton:%@, configuration:(%@)",[super description],[[self class] descriptionOfState:self.state],self.destination,self._nocopy_configuration];
}

@end

@implementation ZIKRouteConfiguration

- (instancetype)init {
    if (self = [super init]) {
        NSAssert(class_conformsToProtocol([self class], @protocol(NSCopying)), @"configuration must conforms to NSCopying, because it will be deep copied when router is initialized.");
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone {
    ZIKRouteConfiguration *config = [[self class] new];
    config.providerErrorHandler = self.providerErrorHandler;
    config.providerSuccessHandler = self.providerSuccessHandler;
    config.performerErrorHandler = self.performerErrorHandler;
    config.performerSuccessHandler = self.performerSuccessHandler;
    config.stateNotifier = [self.stateNotifier copy];
    return config;
}

@end

bool ZIKRouter_replaceMethodWithMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    bool originIsClassMethod = false;
    if (!originalMethod) {
        originIsClassMethod = true;
        originalMethod = class_getClassMethod(originalClass, originalSelector);
        //        originalClass = objc_getMetaClass(object_getClassName(originalClass));
    }
    if (!originalMethod) {
        NSLog(@"replace failed, can't find original method:%@",NSStringFromSelector(originalSelector));
        return false;
    }
    
    if (!swizzledMethod) {
        swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    }
    if (!swizzledMethod) {
        NSLog(@"replace failed, can't find swizzled method:%@",NSStringFromSelector(swizzledSelector));
        return false;
    }
    
    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    int cmpResult = strcmp(originalType, swizzledType);
    if (cmpResult != 0) {
        NSLog(@"warning：method signature not match, please confirm！original method:%@\n signature:%s\nswizzled method:%@\nsignature:%s",NSStringFromSelector(originalSelector),originalType,NSStringFromSelector(swizzledSelector),swizzledType);
        swizzledType = originalType;
    }
    if (originalIMP == swizzledIMP) {//original class was already swizzled, or originalSelector's implementation is in super class but super class was already swizzled
        return true;
    }
    if (originIsClassMethod) {
        originalClass = objc_getMetaClass(class_getName(originalClass));
    }
    class_replaceMethod(originalClass,swizzledSelector,originalIMP,originalType);
    class_replaceMethod(originalClass,originalSelector,swizzledIMP,swizzledType);
    return true;
}

bool ZIKRouter_replaceMethodWithMethodType(Class originalClass, SEL originalSelector, bool originIsClassMethod, Class swizzledClass, SEL swizzledSelector, bool swizzledIsClassMethod) {
    Method originalMethod;
    Method swizzledMethod;
    if (originIsClassMethod) {
        originalMethod = class_getClassMethod(originalClass, originalSelector);
    } else {
        originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    }
    if (swizzledIsClassMethod) {
        swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    } else {
        swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    }
    if (!originalMethod) {
        NSLog(@"replace failed, can't find original method:%@",NSStringFromSelector(originalSelector));
        return false;
    }
    if (!swizzledMethod) {
        NSLog(@"replace failed, can't find swizzled method:%@",NSStringFromSelector(swizzledSelector));
        return false;
    }
    
    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    int cmpResult = strcmp(originalType, swizzledType);
    if (cmpResult != 0) {
        NSLog(@"warning：method signature not match, please confirm！original method:%@\n signature:%s\nswizzled method:%@\nsignature:%s",NSStringFromSelector(originalSelector),originalType,NSStringFromSelector(swizzledSelector),swizzledType);
        swizzledType = originalType;
    }
    if (originalIMP == swizzledIMP) {//original class was already swizzled, or originalSelector's implementation is in super class but super class was already swizzled
        return true;
    }
    if (originIsClassMethod) {
        originalClass = objc_getMetaClass(class_getName(originalClass));
    }
    class_replaceMethod(originalClass,swizzledSelector,originalIMP,originalType);
    class_replaceMethod(originalClass,originalSelector,swizzledIMP,swizzledType);
    return true;
}

IMP ZIKRouter_replaceMethodWithMethodAndGetOriginalImp(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    NSCParameterAssert(!(originalClass == swizzledClass && originalSelector == swizzledSelector));
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    bool originIsClassMethod = false;
    if (!originalMethod) {
        originIsClassMethod = true;
        originalMethod = class_getClassMethod(originalClass, originalSelector);
        //        originalClass = objc_getMetaClass(object_getClassName(originalClass));
    }
    if (!originalMethod) {
        NSLog(@"replace failed, can't find original method:%@",NSStringFromSelector(originalSelector));
        return NULL;
    }
    
    if (!swizzledMethod) {
        swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    }
    if (!swizzledMethod) {
        NSLog(@"replace failed, can't find swizzled method:%@",NSStringFromSelector(swizzledSelector));
        return NULL;
    }
    
    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    int cmpResult = strcmp(originalType, swizzledType);
    if (cmpResult != 0) {
        NSLog(@"warning：method signature not match, please confirm！original method:%@\n signature:%s\nswizzled method:%@\nsignature:%s",NSStringFromSelector(originalSelector),originalType,NSStringFromSelector(swizzledSelector),swizzledType);
        swizzledType = originalType;
    }
    if (originalIMP == swizzledIMP) {//original class was already swizzled, or originalSelector's implementation is in super class but super class was already swizzled
        return NULL;
    }
    if (originIsClassMethod) {
        originalClass = objc_getMetaClass(class_getName(originalClass));
    }
    BOOL success = class_addMethod(originalClass, originalSelector, swizzledIMP, swizzledType);
    if (success) {
        //method is in originalClass's superclass chain
        success = class_addMethod(originalClass, swizzledSelector, originalIMP, originalType);
        NSCAssert(success, @"swizzledSelector shouldn't exist in original class before hook");
        return NULL;
    } else {
        //method is in originalClass
        success = class_addMethod(originalClass, swizzledSelector, originalIMP, originalType);
        NSCAssert(success, @"swizzledSelector shouldn't exist in original class before hook");
        method_setImplementation(originalMethod, swizzledIMP);
        return originalIMP;
    }
}

void ZIKRouter_enumerateClassList(void(^handler)(Class class)) {
    NSCParameterAssert(handler);
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    // from http://stackoverflow.com/a/8731509/46768
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    for (NSInteger i = 0; i < numClasses; i++) {
        Class class = classes[i];
        handler(class);
    }
    
    free(classes);
}

void ZIKRouter_enumerateProtocolList(void(^handler)(Protocol *protocol)) {
    NSCParameterAssert(handler);
    unsigned int outCount;
    Protocol *__unsafe_unretained *protocols = objc_copyProtocolList(&outCount);
    for (int i = 0; i < outCount; i++) {
        Protocol *protocol = protocols[i];
        handler(protocol);
    }
    free(protocols);
}

bool ZIKRouter_classIsSubclassOfClass(Class class, Class parentClass) {
    Class superClass = class;
    do {
        superClass = class_getSuperclass(superClass);
    } while (superClass && superClass != parentClass);
    
    if (superClass == nil) {
        return false;
    }
    return true;
}

NSArray *ZIKRouter_subclassesComformToProtocol(NSArray<Class> *classes, Protocol *protocol) {
    NSMutableArray *result = [NSMutableArray array];
    for (Class class in classes) {
        if (class_conformsToProtocol(class, protocol)) {
            [result addObject:class];
        }
    }
    return result;
}
