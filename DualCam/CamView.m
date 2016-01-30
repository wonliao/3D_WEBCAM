#import "CamView.h"

@implementation CamView

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.wantsLayer = YES;
		
		captureSession = [[AVCaptureSession alloc] init];
        [self setCaptureConfig];    // 設定影片品質
        
        // 攝影機列表
        camList = [[NSMenu alloc] init];
		NSArray* devs = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
		for (id dev in devs) {
			if ([dev isKindOfClass:[AVCaptureDevice class]]) {
				AVCaptureDevice *device = (AVCaptureDevice*)dev;
				NSMenuItem* entry = [[NSMenuItem alloc] initWithTitle:[device localizedName] action:@selector(setCamera:) keyEquivalent:@""];
				entry.representedObject = device;
				entry.target = self;
				[camList addItem:entry];
			}
		}
		
		self.menu = camList;
	}
	return self;
}

- (void)setCamera:(id)sender {
	if ([[sender representedObject] isKindOfClass:[AVCaptureDevice class]]) {
		AVCaptureDevice* camDev = (AVCaptureDevice*)[sender representedObject];
		[self showCamera:camDev];
	}
}

-(void)setup {
	previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
	previewLayer.frame = [self bounds];
	[[self layer] addSublayer:previewLayer];
}

-(void)showCamera:(AVCaptureDevice*)dev {
	[captureSession stopRunning];
	
	for (id i in [captureSession inputs]) {
		if ([i isKindOfClass:[AVCaptureInput class]]) {
			AVCaptureInput* input = (AVCaptureInput*)i;
			[captureSession removeInput:input];
		}
	}
	AVCaptureDeviceInput* cap = [AVCaptureDeviceInput deviceInputWithDevice:dev error:nil];
	[captureSession addInput:cap];
	[captureSession startRunning];
	
	previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}


// 設定影片品質
-(void)setCaptureConfig
{
    // 設定影片品質
    /*
     Preset                          3G      3GS     4 back      4 front
     AVCaptureSessionPresetHigh      400x304	640x480	1280x720    640x480
     AVCaptureSessionPresetMedium	400x304	480x360	480x360     480x360
     AVCaptureSessionPresetLow       400x306	192x144	192x144     192x144
     AVCaptureSessionPreset640x480	NA      640x480	640x480     640x480
     AVCaptureSessionPreset1280x720	NA      NA      1280x720	NA
     AVCaptureSessionPresetPhoto     NA      NA      NA          NA
     */
    [captureSession setSessionPreset:AVCaptureSessionPresetHigh];
}

// 設定影片輸出檔
-(void)outputFile:(NSString *) outputFileName
{
    captureOutput = [[AVCaptureMovieFileOutput alloc] init];
   
    NSString *filePath;
    
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    fileUrl = [[tmpDirURL URLByAppendingPathComponent:outputFileName] URLByAppendingPathExtension:@"mov"];
    filePath = [fileUrl path];
    /*
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    */

    NSLog(@"recording to %@",fileUrl);
    
    [captureSession addOutput:captureOutput];
}

// 開始錄影
-(void)startVideoRecord
{
    NSLog(@"startVideoRecord");
    [captureSession startRunning];
    [captureOutput startRecordingToOutputFileURL:fileUrl
                               recordingDelegate:self];
}

// 停止錄影
-(void)stopVideoRecord
{
    NSLog(@"stopVideoRecord");
    [captureSession stopRunning];
    [captureOutput stopRecording];
}




@end
