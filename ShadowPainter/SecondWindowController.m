//
//  SecondWindowController.m
//  ShadowPainter
//
//  Created by javanai on 10/05/15.
//  Copyright (c) 2015 lamenagerie. All rights reserved.
#import "SecondWindowController.h"

@implementation SecondWindowController
@synthesize delegate;

- (instancetype)init {
    self = [super init];
    if (self) {
        myWindow = [[FullscreenWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1, 1)
                                                       styleMask:NSBorderlessWindowMask
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO
                                                          screen:[NSScreen mainScreen]];
        myWindow.clickdelegate=self;
        [myWindow setLevel:NSMainMenuWindowLevel+1];
        [myWindow setOpaque:YES];
        [myWindow setHidesOnDeactivate:NO];
        [myWindow setBackgroundColor:[NSColor blackColor]];
        [myWindow makeKeyAndOrderFront:nil];
        [NSTimer scheduledTimerWithTimeInterval:4.0f target:self selector:@selector(reduceWindowAfterLaunch) userInfo:nil repeats:NO];
        // self.fullscreen=YES;
        // [self setQuartz];
        //[self.quartzHolder addSubview:self.qcView];
    }
    return self;
}

-(void)openWindow {
    [NSCursor hide];
    [myWindow setFrame:[[NSScreen mainScreen] frame] display:YES];
    [_qcView startRendering];
}

-(void) windowDoubleClicked {
    if(applicationHasReduced){
        [NSCursor unhide];
        [_qcView stopRendering];
    
        [myWindow setFrame:NSMakeRect(0, 0, 1, 1) display:YES];
        [self.delegate leavingFullScreen];
    }
}

-(void) setQuartz:(NSString*) dirLocation {
    [myWindow setFrame:[[NSScreen mainScreen] frame] display:YES];
    if (!_qcView ){
        _qcView = [[[QCView alloc] initWithFrame:[[NSScreen mainScreen] frame]] autorelease];
        _qcView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    }
    
    if( !_qc){
        NSString *path = [[NSBundle mainBundle] pathForResource:@"kinectQuartz"
                                                         ofType:@"qtz"];
        
        _qc = [QCComposition compositionWithFile:path];
        [_qcView loadComposition:_qc];
    }
    
    [[myWindow contentView] addSubview:_qcView positioned:NSWindowAbove relativeTo:nil];

    [_qcView setValue:dirLocation forInputKey:@"Directory_Location"];
    [_qcView startRendering];
}

-(void) reduceWindowAfterLaunch{

    [myWindow setFrame:NSMakeRect(0, 0, 1, 1) display:YES];
    applicationHasReduced=YES;
}

-(void) setImage:(NSImage*) imgRep {
    [_qcView setValue:imgRep forInputKey:@"backgroundImage"];
}

@end
