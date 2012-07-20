#import "TUIView.h"
#import "TUIAnimationAssembler.h"

// This category provides extra methods on TUIView which
// make it very easy to use the TUIAnimationAssembler
// pre-built animations, and is completely seperate from
// inherent TUIView animations blocks and contexts.
@interface TUIView (AnimationAdditions)

// Slides the view in from the *direction* edge or corner of the screen.
- (void)slideInFrom:(TUIAnimationDirection)direction
           duration:(NSTimeInterval)duration
           delegate:(id)delegate;

// Slides the view in from a specified edge or corner of the screen.
- (void)slideInFrom:(TUIAnimationDirection)direction
           duration:(NSTimeInterval)duration
           delegate:(id)delegate
      startSelector:(SEL)startSelector
       stopSelector:(SEL)stopSelector;

// Slides the view out to the direction edge or corner of the screen.
- (void)slideOutTo:(TUIAnimationDirection)direction
          duration:(NSTimeInterval)duration
          delegate:(id)delegate;

// Slides the view out to a specified edge or corner of the screen.
- (void)slideOutTo:(TUIAnimationDirection)direction
          duration:(NSTimeInterval)duration
          delegate:(id)delegate
     startSelector:(SEL)startSelector
      stopSelector:(SEL)stopSelector;

// Slides the view in from the direction edge or corner of the enclosingView.
- (void)slideInFrom:(TUIAnimationDirection)direction
             inView:(TUIView *)enclosingView
           duration:(NSTimeInterval)duration
           delegate:(id)delegate
      startSelector:(SEL)startSelector
       stopSelector:(SEL)stopSelector;

// Slides the view out of the enclosingView to the direction edge or corner.
- (void)slideOutTo:(TUIAnimationDirection)direction
            inView:(TUIView *)enclosingView
          duration:(NSTimeInterval)duration
          delegate:(id)delegate
     startSelector:(SEL)startSelector
      stopSelector:(SEL)stopSelector;

// Backs the view out to a specified edge or corner of the screen.
// The view will make a slight movement in the opposite
// direction before sliding offscreen.
- (void)backOutTo:(TUIAnimationDirection)direction
         withFade:(BOOL)fade
         duration:(NSTimeInterval)duration
         delegate:(id)delegate;

// Backs the view out to a specified edge or corner of the screen.
// The view will make a slight movement in the opposite
// direction before sliding offscreen.
- (void)backOutTo:(TUIAnimationDirection)direction
         withFade:(BOOL)fade
         duration:(NSTimeInterval)duration
         delegate:(id)delegate
    startSelector:(SEL)startSelector
     stopSelector:(SEL)stopSelector;

// Backs the view in from a specified edge or corner of the screen.
// The view will make a slight movement in the opposite
// direction before sliding onscreen.
- (void)backInFrom:(TUIAnimationDirection)direction
          withFade:(BOOL)fade
          duration:(NSTimeInterval)duration
          delegate:(id)delegate;

// Backs the view in from a specified edge or corner of the screen.
// The view will make a slight movement in the opposite
// direction before sliding onscreen.
- (void)backInFrom:(TUIAnimationDirection)direction
          withFade:(BOOL)fade
          duration:(NSTimeInterval)duration
          delegate:(id)delegate
     startSelector:(SEL)startSelector
      stopSelector:(SEL)stopSelector;

// Backs the view off of a specified edge or corner of the enclosingView.
// The view will make a slight movement in the opposite
// direction before sliding off of the enclosingView.
- (void)backOutTo:(TUIAnimationDirection)direction
           inView:(TUIView *)enclosingView
         withFade:(BOOL)fade
         duration:(NSTimeInterval)duration
         delegate:(id)delegate
    startSelector:(SEL)startSelector
     stopSelector:(SEL)stopSelector;

// Backs the view in from a specified edge or corner of the enclosingView.
// The view will make a slight movement in the opposite
// direction before sliding over the enclosingView.
- (void)backInFrom:(TUIAnimationDirection)direction
            inView:(TUIView *)enclosingView
          withFade:(BOOL)fade
          duration:(NSTimeInterval)duration
          delegate:(id)delegate
     startSelector:(SEL)startSelector
      stopSelector:(SEL)stopSelector;

// Causes the view to fade in from invisible to fully opaque.
- (void)fadeIn:(NSTimeInterval)duration
      delegate:(id)delegate;

// Causes the view to fade in from invisible to fully opaque.
- (void)fadeIn:(NSTimeInterval)duration
      delegate:(id)delegate
 startSelector:(SEL)startSelector
  stopSelector:(SEL)stopSelector;

// Causes the view to fade out until it is invisible.
- (void)fadeOut:(NSTimeInterval)duration
       delegate:(id)delegate;

// Causes the view to fade out until it is invisible.
- (void)fadeOut:(NSTimeInterval)duration
       delegate:(id)delegate
  startSelector:(SEL)startSelector
   stopSelector:(SEL)stopSelector;

// Causes the background color of the view to fade in from invisible to completely opaque.
- (void)fadeBackgroundColorIn:(NSTimeInterval)duration
                     delegate:(id)delegate;

// Causes the background color of the view to fade in from invisible to completely opaque.
- (void)fadeBackgroundColorIn:(NSTimeInterval)duration
                     delegate:(id)delegate
                startSelector:(SEL)startSelector
                 stopSelector:(SEL)stopSelector;

// Causes the background color of the view to fade out until it is invisible.
- (void)fadeBackgroundColorOut:(NSTimeInterval)duration
                      delegate:(id)delegate;

// Causes the background color of the view to fade out until it is invisible.
- (void)fadeBackgroundColorOut:(NSTimeInterval)duration
                      delegate:(id)delegate
                 startSelector:(SEL)startSelector
                  stopSelector:(SEL)stopSelector;

// Pops the view in from the center of the screen similar
// to the animation of a UIAlertView. The view will start
// invisible and small in the center of the screen, and it
// will be animated to its final size with a rubber
// band bounce at the end.
- (void)popIn:(NSTimeInterval)duration
     delegate:(id)delegate;

// Pops the view in from the center of the screen similar
// to the animation of a UIAlertView. The view will start
// invisible and small in the center of the screen, and it
// will be animated to its final size with a rubber
// band bounce at the end.
- (void)popIn:(NSTimeInterval)duration
     delegate:(id)delegate
startSelector:(SEL)startSelector
 stopSelector:(SEL)stopSelector;

// This is the reverse of the popIn animation. The view
// will scale to a slightly larger size before
// shrinking to nothing in the middle of the screen.
- (void)popOut:(NSTimeInterval)duration
      delegate:(id)delegate;

// This is the reverse of the popIn animation. The view
// will scale to a slightly larger size before
// shrinking to nothing in the middle of the screen.
- (void)popOut:(NSTimeInterval)duration
      delegate:(id)delegate
 startSelector:(SEL)startSelector
  stopSelector:(SEL)stopSelector;

// The view will fade in and shrink from double its size
// down to its regular size. This makes it appear as
// though the view is falling onto the screen from
// the user's vantage point.
- (void)fallIn:(NSTimeInterval)duration
      delegate:(id)delegate;

// The view will fade in and shrink from double its size
// down to its regular size. This makes it appear as
// though the view is falling onto the screen from
// the user's vantage point.
- (void)fallIn:(NSTimeInterval)duration
      delegate:(id)delegate
 startSelector:(SEL)startSelector
  stopSelector:(SEL)stopSelector;

// The view will shrink to nothing in the middle of the screen and disappear.
- (void)fallOut:(NSTimeInterval)duration
       delegate:(id)delegate;

// The view will shrink to nothing in the middle of the screen and disappear.
- (void)fallOut:(NSTimeInterval)duration
       delegate:(id)delegate
  startSelector:(SEL)startSelector
   stopSelector:(SEL)stopSelector;

// The view will scale up to twice its size while fading to invisible.
- (void)flyOut:(NSTimeInterval)duration
      delegate:(id)delegate;

// The view will scale up to twice its size while fading to invisible.
- (void)flyOut:(NSTimeInterval)duration
      delegate:(id)delegate
 startSelector:(SEL)startSelector
  stopSelector:(SEL)stopSelector;

@end
