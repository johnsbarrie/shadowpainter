//
//  SecondWindowController.h
//  ShadowPainter
//
//  Created by javanai on 10/05/15.
//  Copyright (c) 2015 lamenagerie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "FullscreenWindow.h"

@protocol SecondWindowControllerDelegate

-(void) leavingFullScreen;

@end

@interface SecondWindowController : NSObject <FullscreenWindowDelegate>{
    FullscreenWindow *myWindow;
    QCComposition* _qc;
    QCView* _qcView;
    BOOL applicationHasReduced;
    
}

@property (retain) id <SecondWindowControllerDelegate> delegate;

-(void)openWindow;
-(void) setImage:(NSImage*) imgRep;
-(void) setQuartz:(NSString*) dirLocation;

@end
