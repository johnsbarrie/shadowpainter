//  AppDelegate.h
//  ShadowPainter
//
//  Created by javanai on 06/05/15.
//  Copyright (c) 2015 lamenagerie. All rights reserved.

#import <Cocoa/Cocoa.h>
#import <libfreenect/libfreenect.h>
#import <Quartz/Quartz.h>
#import "SecondWindowController.h"
@interface ShadowView : NSView

@end

@interface AppDelegate : NSObject <NSApplicationDelegate, SecondWindowControllerDelegate> {
    IBOutlet NSSlider *dSlider;

    IBOutlet NSTextField *dDigits;
    IBOutlet NSSlider *tSlider;
    IBOutlet NSTextField *tDigits;
    NSBitmapImageRep *imgRep;
    NSBitmapImageRep *depthimgRep;
    SecondWindowController *secondWindowController;
    NSMutableDictionary * configDictionary;
    freenect_context *f_ctx;
    freenect_device *f_dev;
    double freenect_angle;
    NSThread *freenectThread;
    
    QCView * _qcView;
    QCComposition* _qc;
    BOOL die;
        BOOL running;
    BOOL _fullscreen;
}
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *startbutton;
@property (assign) IBOutlet NSButton *openbutton;

@property (assign) IBOutlet ShadowView *view;

@property (assign) IBOutlet NSView *quartzHolder;
@property (retain) QCView *qcView;
@property (retain) QCComposition *qc;

- (IBAction)startStopKinect:(id)sender;
-(void) refreshView;
- (IBAction)openWindow:(id)sender;

- (IBAction)changeDepthTh:(id)sender;
- (IBAction)changeTilt:(id)sender;
- (void) setQuartz;

@end

