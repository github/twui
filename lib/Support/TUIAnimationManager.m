//
//  TUIAnimationManager.m
//
//  Created by Justin Spahr-Summers on 10.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import "TUIAnimationManager.h"

/**
 * Disables implicit AppKit animations on every run loop iteration.
 */
static void mainRunLoopObserverCallback (CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    [[NSAnimationContext currentContext] setDuration:0];
}

@interface TUIAnimationManager ()
/**
 * The observer associated with the main run loop, responsible for invoking the
 * mainRunLoopObserverCallback.
 */
@property (nonatomic) CFRunLoopObserverRef mainRunLoopObserver;

/**
 * Invoked on the defaultManager when the application has finished launching.
 */
- (void)applicationDidFinishLaunchingNotification:(NSNotification *)notification;

/**
 * Registers an observer on the main run loop which will invoke the
 * mainRunLoopObserverCallback.
 */
- (void)registerRunLoopObserver;
@end

@implementation TUIAnimationManager

#pragma mark Properties

@synthesize mainRunLoopObserver = m_mainRunLoopObserver;

- (void)setMainRunLoopObserver:(CFRunLoopObserverRef)observer {
    if (observer == m_mainRunLoopObserver)
        return;

    if (m_mainRunLoopObserver) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), m_mainRunLoopObserver, kCFRunLoopCommonModes);
        CFRelease(m_mainRunLoopObserver);
    }

    if (observer)
        CFRetain(observer);

    m_mainRunLoopObserver = observer;
}

#pragma mark Lifecycle

+ (void)load {
	@autoreleasepool {
		[[NSNotificationCenter defaultCenter]
			addObserver:[self defaultManager]
			selector:@selector(applicationDidFinishLaunchingNotification:)
			name:NSApplicationDidFinishLaunchingNotification
			object:nil
		];
	}
}

+ (TUIAnimationManager *)defaultManager; {
    static id singleton = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        singleton = [[self alloc] init];
    });

    return singleton;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.mainRunLoopObserver = NULL;
}

#pragma mark Run Loop Observer

- (void)registerRunLoopObserver; {
    // set up an observer on the main run loop that can disable implicit
    // animations
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(
        NULL,
        kCFRunLoopBeforeTimers,
        YES,
        10000,
        &mainRunLoopObserverCallback,
        NULL
    );

    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);

    self.mainRunLoopObserver = observer;
    CFRelease(observer);
}

#pragma mark Notifications

- (void)applicationDidFinishLaunchingNotification:(NSNotification *)notification; {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notification.name object:nil];
    [self registerRunLoopObserver];
}

@end
