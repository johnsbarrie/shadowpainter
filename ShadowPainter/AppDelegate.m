//  AppDelegate.m
//  ShadowPainter
//
//  Created by John Barrie on 2013/08/13.
//  Copyright (c) 2015, John Barrie. All rights reserved.
#import "AppDelegate.h"
#import <math.h>

static int got_rgb = 0, got_depth = 0;
static uint16_t *depth_back, *depth_front;
static uint8_t *rgb_back, *rgb_front;
static ShadowView *myView;
static NSLock *imgLock;
static NSInteger depthTh = 1280;
static AppDelegate* application;

static void depth_cb (freenect_device *dev, void *v_depth, uint32_t timestamp) {
    [imgLock lock];
    depth_back = depth_front;
    freenect_set_depth_buffer(dev, depth_back);
    depth_front = (uint16_t *)v_depth;
    got_depth++;
    
    [imgLock unlock];
}

static void rgb_cb (freenect_device *dev, void *rgb, uint32_t timestamp) {
    [imgLock lock];
    rgb_back = rgb_front;
    freenect_set_video_buffer(dev, rgb_back);
    rgb_front = (uint8_t*)rgb;
    got_rgb++;
    if (got_depth){
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [application refreshView];
        });
    }
    [imgLock unlock];
}

@implementation AppDelegate

- (void) refreshView {
    [myView setNeedsDisplay:YES];
}

- (void)dealloc {
    [imgRep release];
    [imgLock release];
    [super dealloc];
}

- (NSBitmapImageRep *) maskedImage {
    if (!imgRep) return nil;
    [imgLock lock];
    unsigned char *buf = [imgRep bitmapData];
    memcpy(buf, rgb_front, 640*480*3);
    
    got_depth = got_rgb = 0;
    [imgLock unlock];
    
    for (int i = 0; i < 640*480; i ++) {
        if (depth_front[i] > depthTh){
            memset(&buf[i*3], 0, 3);
        }
        else if (depth_front[i] < 1){
            memset(&buf[i*3], 0, 3);
        }else{
            double maxDouble = fmax((255.*(float)depth_front[i]/ (float)depthTh)+25., 255.);
            memset(&buf[i*3], maxDouble , 3);
        };
    }
    
    NSImage * image = [[[NSImage alloc] initWithCGImage:[imgRep CGImage] size:NSMakeSize(640,480)] autorelease];
    if (_fullscreen) {
        [secondWindowController setImage:image];
    } else {
        [self.qcView setValue:image  forInputKey:@"backgroundImage"];
    }
    return imgRep;
}

- (void) freenectThread: (id) arg {
    die=NO;
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    freenectThread = [[NSThread currentThread] retain];
    freenect_set_depth_callback(f_dev, depth_cb);
    freenect_set_video_callback(f_dev, rgb_cb);
    freenect_set_video_mode(f_dev, freenect_find_video_mode( FREENECT_RESOLUTION_MEDIUM, FREENECT_VIDEO_RGB ));
    freenect_set_depth_mode(f_dev, freenect_find_depth_mode( FREENECT_RESOLUTION_MEDIUM, FREENECT_DEPTH_REGISTERED ));
    freenect_set_video_buffer (f_dev, rgb_back);
    freenect_set_depth_buffer (f_dev, depth_back);
    
    if (freenect_start_video(f_dev)) { [self writeLog:@"Could not start video."]; [NSApp terminate:nil]; };
    if (freenect_start_depth(f_dev)) { [self writeLog:@"Could not start depth."]; [NSApp terminate:nil]; };
    freenect_set_led(f_dev, LED_RED);
    unsigned long count = 0;
    while (!die && freenect_process_events(f_ctx) >= 0) if (count++ > 600) {
        count = 0;
        [pool release];
        pool = [[NSAutoreleasePool alloc] init];
    }
    
    freenect_stop_depth (f_dev);
    freenect_stop_video (f_dev);
    freenect_set_led (f_dev, LED_GREEN);
    freenect_close_device (f_dev);
    freenect_shutdown (f_ctx);
    [pool release];
}

- (void) writeConfigFile {
    NSString * folderPath = [self applicationDocumentFolder];
    NSString * filePath = [folderPath stringByAppendingPathComponent:@"config.plist"];
    [configDictionary writeToFile:filePath atomically:true];
}

- (void) readConfigFile {
    NSString * folderPath=[self applicationDocumentFolder];
    BOOL isDir;
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDir] ){
        if ( ![[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:NULL] )
        [self writeLog: [NSString stringWithFormat: @"Error: Create folder failed %@", folderPath]];
        configDictionary = [[NSMutableDictionary dictionary] retain];
        [configDictionary setObject:@"2000" forKey:@"depth"];
        
        [self writeConfigFile];
    } else {
        NSString * filePath = [folderPath stringByAppendingPathComponent:@"config.plist"];
        configDictionary= [[NSMutableDictionary dictionaryWithContentsOfFile:filePath] retain];
    }
}

- (NSString *) applicationDocumentFolder {
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString *folderPath = [documentsDirectory stringByAppendingPathComponent:@"ShadowPainter"];
    return folderPath;
}

- (void) writeLog: (NSString *) logMessage {
    NSString * folderPath = [self applicationDocumentFolder];
    NSString * fileName = [NSString stringWithFormat:@"%@/logs.txt", folderPath];
    
    NSError * error = nil;
    NSString * contents = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
        contents=@"";
    }
    
    NSDateFormatter * formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];
    
    NSString * dateString = [formatter stringFromDate:[NSDate date]];
    contents = [contents stringByAppendingString:[NSString stringWithFormat:@"%@ %@\r", logMessage, dateString]];
    [contents writeToFile:fileName atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
}

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification {
    [self readConfigFile];
    NSNumber* depth = [configDictionary objectForKey:@"depth"];
    [dSlider setDoubleValue:[depth doubleValue]];
    depthTh = [depth doubleValue];
    [dDigits setIntegerValue:[depth doubleValue]];
    
    depth_back = (uint16_t*) malloc (640 * 480 * sizeof(uint16_t));
    depth_front = (uint16_t*) malloc (640 * 480 * sizeof(uint16_t));
    rgb_back = (uint8_t*)malloc(640 * 480 * 3);
    rgb_front = (uint8_t*)malloc(640 * 480 * 3);
    uint8_t *imgBuf = (uint8_t*)malloc(640*480*3);
    
    imgRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:(unsigned char *[]){imgBuf}
                                                     pixelsWide:640 pixelsHigh:480 bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO
                                                 colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:640*3 bitsPerPixel:24];
    
    [self setQuartz];
    secondWindowController = [[SecondWindowController alloc] init];
    
    NSString* imageFolder= [NSString stringWithFormat:@"%@/images/", [self applicationDocumentFolder]];
    [secondWindowController setQuartz:imageFolder];
    
    imgLock = [[NSLock alloc] init];
    [NSTimer scheduledTimerWithTimeInterval:2.f target:self selector:@selector(fakestart) userInfo:nil repeats:NO];
    secondWindowController.delegate= self;
}

- (void) fakestart {
    [self startKinect];
    [NSTimer scheduledTimerWithTimeInterval:2.f target:self selector:@selector(stopKinect) userInfo:nil repeats:NO];
}

- (void) stopKinect {
    die=YES;
}

- (void) applicationWillTerminate: (NSNotification *)aNotification {
    die = YES;
    do { usleep(100000); }
    while ([freenectThread isExecuting]);
    free(depth_back);
    free(depth_front);
    free(rgb_back);
    free(rgb_front);
}

- (IBAction) startStopKinect: (id)sender {
    if(!running){
        [self startKinect];
        [self.startbutton setTitle:@"Arreter"];
    } else {
        die=YES;
        [self.startbutton setTitle:@"Demarrer"];
    }
    running=!running;
}

- (void) startKinect {
    if (freenect_init(&f_ctx, NULL) < 0){ [self writeLog:@"Could not initialize FREENECT."]; [NSApp terminate:nil];}
    freenect_select_subdevices(f_ctx, FREENECT_DEVICE_CAMERA|FREENECT_DEVICE_MOTOR);
    
    if (freenect_num_devices(f_ctx) < 1) { [self writeLog:@"Could find no Kinect device."]; [NSApp terminate:nil];}
    if (!imgRep) { [self writeLog:@"Could not allocate NSBitmapImageRep."]; [NSApp terminate:nil]; }
    if (freenect_open_device(f_ctx, &f_dev, 0) < 0) { [self writeLog:@"Could not open Kinect device."]; [NSApp terminate:nil]; }
    if (freenect_set_led(f_dev, LED_OFF)) { [self writeLog:@"Could not change LED color."]; [NSApp terminate:nil]; }
    if (!(myView = self.view)) { [self writeLog:@"Could not find view object."]; [NSApp terminate:nil]; }
    if (! (application = self)){ [self writeLog:@"Could not find application object."]; [NSApp terminate:nil]; }
    
    [dSlider setIntegerValue:depthTh];
    [dDigits setIntegerValue:depthTh];
    freenect_update_tilt_state(f_dev);
    freenect_angle = freenect_get_tilt_degs(freenect_get_tilt_state(f_dev));
    [tSlider setDoubleValue:freenect_angle];
    [tDigits setDoubleValue:freenect_angle];
    [NSThread detachNewThreadSelector:@selector(freenectThread:) toTarget:self withObject:nil];
}

- (IBAction) openWindow: (id)sender {
    _fullscreen=YES;
    [secondWindowController openWindow];
    [self.qcView stopRendering];
}

- (void) leavingFullScreen {
    _fullscreen=NO;
    [self.qcView startRendering];
}

- (IBAction) changeDepthTh: (id)sender {
    depthTh = [dSlider doubleValue];
    [configDictionary setObject:[NSNumber numberWithDouble:depthTh ] forKey:@"depth"];
    [self writeConfigFile];
    depthTh = [dSlider doubleValue];
    [dDigits setIntegerValue:depthTh];
}

- (IBAction) changeTilt: (id)sender {
    double v = round([tSlider doubleValue]);
    if (v == freenect_angle) return;
    [tDigits setDoubleValue:(freenect_angle = v)];
    freenect_set_tilt_degs(f_dev, freenect_angle);
}

- (void) setQuartz {
    if (!self.qcView){
        self.qcView = [[[QCView alloc] initWithFrame:self.quartzHolder.bounds] autorelease];
        self.qcView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self.quartzHolder addSubview:self.qcView];
    }
    
    if (!self.qc) {
        NSString * path = [[NSBundle mainBundle] pathForResource:@"kinectQuartz" ofType:@"qtz"];
        self.qc = [QCComposition compositionWithFile:path];
        [self.qcView loadComposition:self.qc];
        
        NSString* imageFolder= [NSString stringWithFormat:@"%@/images/", [self applicationDocumentFolder]];
        [self.qcView setValue:imageFolder forInputKey:@"Directory_Location"];
    }
    
    [self.qcView startRendering];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) app {
    return YES;
}

@end

@implementation ShadowView

- (void) drawRect:(NSRect)dirtyRect {
    [[(AppDelegate *)[NSApp delegate] maskedImage]
     drawInRect:[self bounds] fromRect:(NSRect){0, 0, 586, 440}
     operation:NSCompositeCopy fraction:1. respectFlipped:NO hints:@{}];
}

@end
