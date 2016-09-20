//
//  FullscreenWindow.m
//  ShadowPainter
//
//  Created by javanai on 10/05/15.
//  Copyright (c) 2015 lamenagerie. All rights reserved.
//

#import "FullscreenWindow.h"

@implementation FullscreenWindow
@synthesize clickdelegate=_clickdelegate;

- (void)mouseUp:(NSEvent *)event
{
    NSInteger clickCount = [event clickCount];
    if (2 == clickCount) {
        [_clickdelegate windowDoubleClicked];
    }
}

@end
