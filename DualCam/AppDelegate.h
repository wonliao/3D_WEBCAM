#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

#import "CamView.h"
#import "DualCamViewController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
	CamView* cam1;
	CamView* cam2;
	DualCamViewController* dualCamViewController;
    //AVAssetExportSession *exporter;
    NSTimer *timer;
}

-(IBAction)toggleLevel:(id)sender;
-(void)windowDidResize:(NSNotification *)notification;
- (void) monitorProgress;


-(IBAction)startRecode:(id)sender;
-(IBAction)stopRecode:(id)sender;
-(IBAction)mergeVideoFile:(id)sender;

@end

