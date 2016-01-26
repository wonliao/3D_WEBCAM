#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>


@interface CamView : NSView {
	@public AVCaptureSession* captureSession;
	AVCaptureVideoPreviewLayer* previewLayer;
	NSMenu* camList;
    
    AVCaptureMovieFileOutput *captureOutput;
    NSURL *fileUrl;
}

-(void)setCamera:(id)sender;
-(void)setup;
-(void)showCamera:(AVCaptureDevice*)dev;

-(void)startVideoRecord;
-(void)stopVideoRecord;
-(void)outputFile:(NSString *) outputFileName;

@end
