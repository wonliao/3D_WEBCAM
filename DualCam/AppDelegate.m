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



/*
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
*/


// 合併檔案
-(IBAction)mergeVideoFile:(id)sender {
    
    //Here we load our movie Assets using AVURLAsset
    
    AVURLAsset* firstAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"right2" ofType:@"mov"]] options:nil];
    AVURLAsset * secondAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"left2" ofType:@"mov"]] options:nil];
    
    //Create AVMutableComposition Object.This object will hold our multiple AVMutableCompositionTrack.
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    
    //Here we are creating the first AVMutableCompositionTrack.See how we are adding a new track to our AVMutableComposition.
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //Now we set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to out newly created track at kCMTimeZero so video plays from the start of the track.
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //Now we repeat the same process for the 2nd track as we did above for the first track.
    AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAsset.duration) ofTrack:[[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //See how we are creating AVMutableVideoCompositionInstruction object.This object will contain the array of our AVMutableVideoCompositionLayerInstruction objects.You set the duration of the layer.You should add the lenght equal to the lingth of the longer asset in terms of duration.
    
    
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    
    //We will be creating 2 AVMutableVideoCompositionLayerInstruction objects.Each for our 2 AVMutableCompositionTrack.here we are creating AVMutableVideoCompositionLayerInstruction for out first track.see how we make use of Affinetransform to move and scale our First Track.so it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
    //Note: You have to apply transformation to scale and move according to your video size.
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    CGAffineTransform Scale = CGAffineTransformMakeScale(0.2f,0.2f);
    CGAffineTransform Move = CGAffineTransformMakeTranslation(320,0);
    [FirstlayerInstruction setTransform:CGAffineTransformConcat(Scale,Move) atTime:kCMTimeZero];
    
    //Here we are creating AVMutableVideoCompositionLayerInstruction for out second track.see how we make use of Affinetransform to move and scale our second Track.
    AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
    CGAffineTransform SecondScale = CGAffineTransformMakeScale(0.2f,0.2f);
    CGAffineTransform SecondMove = CGAffineTransformMakeTranslation(0,0);
    [SecondlayerInstruction setTransform:CGAffineTransformConcat(SecondScale,SecondMove) atTime:kCMTimeZero];
    
    
    //Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];;
    
    //Now we create AVMutableVideoComposition object.We can add mutiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = CGSizeMake(640, 480);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:@"overlapVideo.mov"];
    
    
    
    if([[NSFileManager defaultManager] fileExistsAtPath:myPathDocs])
    {
        [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
    }
    
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    [exporter setVideoComposition:MainCompositionInst];
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             [self exportDidFinish:exporter];
         });
     }];
}
//here you have the outputURL of the final overlapped vide0. add your desired task here.
- (void)exportDidFinish:(AVAssetExportSession*)session
{
    NSLog(@"export did finish...");
    NSLog(@"%li", (long)session.status);
    NSLog(@"%@", session.error);
    NSURL *outputURL = session.outputURL;
    
    NSLog(@"outputURL(%@)", outputURL.relativePath);
    //[self setMoviePlayer:outputURL];
}

@end
