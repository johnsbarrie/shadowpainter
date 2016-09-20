//
//  FullscreenWindow.h
//  ShadowPainter
//
//  Created by javanai on 10/05/15.
//  Copyright (c) 2015 lamenagerie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol FullscreenWindowDelegate

    -(void) windowDoubleClicked;

@end

@interface FullscreenWindow : NSWindow{
    id <FullscreenWindowDelegate> _clickdelegate;
}

@property (assign) id  <FullscreenWindowDelegate> clickdelegate;
@end
