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
    
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    
    NSURL *firstFileUrl = [[tmpDirURL URLByAppendingPathComponent:@"video_right"] URLByAppendingPathExtension:@"mov"];
    NSURL *secondFileUrl = [[tmpDirURL URLByAppendingPathComponent:@"video_left"] URLByAppendingPathExtension:@"mov"];
    NSLog(@"firstFileUrl(%@) secondFileUrl(%@)", [firstFileUrl path], [secondFileUrl path]);
    
    AVURLAsset* firstAsset = [AVURLAsset URLAssetWithURL:firstFileUrl options:nil];
    AVURLAsset* secondAsset = [AVURLAsset URLAssetWithURL:secondFileUrl options:nil];
    
    CMTime minDuration;
    if(firstAsset.duration.value <= secondAsset.duration.value) {
        minDuration = firstAsset.duration;
    } else {
        minDuration = secondAsset.duration;
    }
    
    //Create AVMutableComposition Object.This object will hold our multiple AVMutableCompositionTrack.
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    
    //Here we are creating the first AVMutableCompositionTrack.See how we are adding a new track to our AVMutableComposition.
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //Now we set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to out newly created track at kCMTimeZero so video plays from the start of the track.
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, minDuration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //Now we repeat the same process for the 2nd track as we did above for the first track.
    AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, minDuration) ofTrack:[[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    // 影片寬高
    CGFloat vidoeWidth = firstTrack.naturalSize.width;
    CGFloat vidoeHeight = firstTrack.naturalSize.height;
    
    //See how we are creating AVMutableVideoCompositionInstruction object.This object will contain the array of our AVMutableVideoCompositionLayerInstruction objects.You set the duration of the layer.You should add the lenght equal to the lingth of the longer asset in terms of duration.
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, minDuration);
    
    //We will be creating 2 AVMutableVideoCompositionLayerInstruction objects.Each for our 2 AVMutableCompositionTrack.here we are creating AVMutableVideoCompositionLayerInstruction for out first track.see how we make use of Affinetransform to move and scale our First Track.so it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
    //Note: You have to apply transformation to scale and move according to your video size.
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    CGAffineTransform Scale = CGAffineTransformMakeScale(0.5f,0.5f);
    CGAffineTransform Move = CGAffineTransformMakeTranslation(vidoeWidth/2.0f,0);
    [FirstlayerInstruction setTransform:CGAffineTransformConcat(Scale,Move) atTime:kCMTimeZero];
    
    //Here we are creating AVMutableVideoCompositionLayerInstruction for out second track.see how we make use of Affinetransform to move and scale our second Track.
    AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
    CGAffineTransform SecondScale = CGAffineTransformMakeScale(0.5f,0.5f);
    CGAffineTransform SecondMove = CGAffineTransformMakeTranslation(0,0);
    [SecondlayerInstruction setTransform:CGAffineTransformConcat(SecondScale,SecondMove) atTime:kCMTimeZero];
    
    //Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];;
    
    //Now we create AVMutableVideoComposition object.We can add mutiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = CGSizeMake(vidoeWidth, vidoeHeight/2.0f);
    
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
}

@end
