//
//  TUIAnimationManager.h
//
//  Created by Justin Spahr-Summers on 10.03.12.
//  Copyright (c) 2012 Bitswift. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * This private class is responsible for disabling implicit NSView animations.
 *
 * This class may be expanded in the future to add other global animation
 * capabilities.
 */
@interface TUIAnimationManager : NSObject

/*
 * Returns the singleton instance of this class.
 */
+ (TUIAnimationManager *)defaultManager;

@end
