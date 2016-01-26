#import "AppDelegate.h"


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	dualCamViewController = [[DualCamViewController alloc] init];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidEndLiveResizeNotification object:self.window];
	
	cam1 = [[CamView alloc] init];
	[self.window.contentView addSubview:cam1];
	NSRect cam1Bounds = [self.window.contentView bounds];
	cam1Bounds.size.width /= 2;
    cam1Bounds.origin.x = 10;
	cam1.frame = cam1Bounds;
	[cam1 setup];
    [cam1 outputFile:@"video_left"];
	
	cam2 = [[CamView alloc] init];
	[self.window.contentView addSubview:cam2];
	NSRect cam2Bounds = [self.window.contentView bounds];
	cam2Bounds.size.width /= 2;
	cam2Bounds.origin.x = cam1Bounds.size.width-10;
	cam2.frame = cam2Bounds;
	[cam2 setup];
    [cam2 outputFile:@"video_right"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[cam1->captureSession stopRunning];
	[cam2->captureSession stopRunning];
}


- (IBAction)toggleLevel:(id)sender {
	if (self.window.level == 0) {
		self.window.level = kCGFloatingWindowLevelKey;
	}
	else {
		self.window.level = 0;
	}
}

- (void)windowDidResize:(NSNotification *)notification {
    NSRect cam1Bounds = [self.window.contentView bounds];
    cam1Bounds.size.width /= 2;
    cam1.frame = cam1Bounds;
    [cam1 setup];
    
    NSRect cam2Bounds = [self.window.contentView bounds];
    cam2Bounds.size.width /= 2;
    cam2Bounds.origin.x = cam1Bounds.size.width;
    cam2.frame = cam2Bounds;
    [cam2 setup];
    
    [cam1->previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [cam2->previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

// 開始錄影
-(IBAction)startRecode:(id)sender {
    NSLog(@"startRecode");
    [cam1 startVideoRecord];
    [cam2 startVideoRecord];
}

// 停止錄影
-(IBAction)stopRecode:(id)sender{
    NSLog(@"stopRecode");
    [cam1 stopVideoRecord];
    [cam2 stopVideoRecord];
}




// 合併檔案
-(IBAction)mergeVideoFile:(id)sender {
    NSLog(@"mergeVideoFile");
    

    // Initial array of movie URLs
    NSString* filePath1 = [[NSBundle mainBundle] pathForResource:@"left2" ofType:@"mov"];
    NSString* filePath2 = [[NSBundle mainBundle] pathForResource:@"right2" ofType:@"mov"];
    
    NSArray *myMovieURLs = [NSArray arrayWithObjects:
                            [NSURL fileURLWithPath:filePath1],
                            [NSURL fileURLWithPath:filePath2], nil];
    
    // Create the composition & A/V tracks
    AVMutableComposition *comp =  [[AVMutableComposition alloc] init];// [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [comp addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTrack = [comp addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // A reference for insertion start time
    CMTime startTime = kCMTimeZero;
    
    for (int i=0; i< [myMovieURLs count]; i++){
        // Get asset
        NSURL *movieURL = [myMovieURLs objectAtIndex:i];
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:movieURL options:nil];
        
        // Get video and audio tracks (assuming video exists - test for audio as an empty track will crash the program!) and insert in composition tracks
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        bool success = [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:videoTrack atTime:startTime error:nil];
        
   
        
        if ([[asset tracksWithMediaType:AVMediaTypeAudio]count]){
            AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            success = [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:audioTrack atTime:startTime error:nil];
        }
        
        
        // increment the start time to the end of this first video
        startTime = CMTimeAdd(startTime, [asset duration]);
    }
    
    
    
    //NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    //NSURL *outputURL = [[tmpDirURL URLByAppendingPathComponent:@"output"] URLByAppendingPathExtension:@"mov"];
    
    
    //Set the output URL
    NSURL *outputURL = [NSURL fileURLWithPath:@"/var/folders/g4/6brln56n3cgdbz9v3rm5lwg40000gn/T/output.mov"];
    [self removeFile:outputURL];
    
    

    
   // [_assetExport exportAsynchronouslyWithCompletionHandler:
   //  ^(void ) {
    
    /* Create the exporter.
     Note the preset type is up to you to choose.  If you wanted, you could check the asset's size (with [asset naturalSize]) or other values above and use that to base your preset on.
     Use exportPresetsCompatibleWithAsset: to get a list of presets that are compatible with a specific asset.
     */
    NSLog(@"Compat presets you could use: %@", [AVAssetExportSession exportPresetsCompatibleWithAsset:comp]);
    exporter = [[AVAssetExportSession alloc] initWithAsset:comp presetName:AVAssetExportPresetPassthrough];
    
    
    [exporter setOutputURL:outputURL];
    [exporter setOutputFileType:AVFileTypeQuickTimeMovie];
    [exporter setShouldOptimizeForNetworkUse:YES];
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        switch ([exporter status]) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Export failed: %@", [[exporter error] localizedDescription]);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export canceled");
                break;
            default:
                break;
        }
    }];
    
    // This is just a simple timer that will call a method to log the progress
    timer=[NSTimer scheduledTimerWithTimeInterval:5
                                           target:self
                                         selector:@selector(monitorProgress)
                                         userInfo:nil
                                          repeats:YES];
}

- (void) removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            NSLog(@"removeItemAtPath %@ error:%@", filePath, error);
        }
    }
}


-(void)monitorProgress{ 
    if ([exporter progress] == 1.0){
        [timer invalidate];
    }
    
    NSLog(@"Progress: %f",[exporter progress]* 100);
}

@end
