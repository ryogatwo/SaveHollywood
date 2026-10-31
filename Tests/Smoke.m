// Copyright (c) 2026 James Marculewicz. See ../LICENSE.
#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
#import <AVFoundation/AVFoundation.h>
#import "SHSettings.h"
#import "SHPlayingAssetsRegister.h"
#import <objc/runtime.h>
static SHSettings *testSettings;
static SHSettings *isolatedSettings(id self, SEL cmd) { return testSettings; }
static void check(BOOL condition, NSString *message) {
    if (!condition) { NSLog(@"FAIL: %@",message); exit(1); }
}
static void pump(double seconds) {
    NSDate *end=[NSDate dateWithTimeIntervalSinceNow:seconds];
    while (end.timeIntervalSinceNow>0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
}
int main(int argc, const char **argv) { @autoreleasepool {
    if (argc!=2) return 2;
    [NSApplication sharedApplication];
    NSBundle *bundle=[NSBundle bundleWithPath:[NSString stringWithUTF8String:argv[1]]];
    check([bundle load],@"load bundle");
    Class settingsClass=[bundle classNamed:@"SHSettings"];
    testSettings=[[settingsClass alloc] initWithDictionaryRepresentation:@{@"assets.randomOrder":@NO,@"movie.volume.value":@0.375}];
    check(fabs(testSettings.audioVolume-0.375)<0.00001,@"fractional volume survives load");
    NSDictionary *roundtrip=testSettings.dictionaryRepresentation;
    check(fabs([roundtrip[@"movie.volume.value"] doubleValue]-0.375)<0.00001,@"fractional volume round trip");
    NSDictionary *resume=@{@"asset.url":[NSURL fileURLWithPath:@"/tmp/movie.mov"],@"asset.time":[NSValue valueWithCMTime:CMTimeMake(3,2)]};
    for (NSNumber *secure in @[@NO,@YES]) {
        NSData *data=[NSKeyedArchiver archivedDataWithRootObject:resume requiringSecureCoding:secure.boolValue error:NULL];
        NSDictionary *decoded=[NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:NSDictionary.class,NSString.class,NSURL.class,NSValue.class,NSNumber.class,nil] fromData:data error:NULL];
        check([decoded isEqual:resume],@"old and secure resume archives decode");
    }
    [testSettings resetSettings];
    method_setImplementation(class_getClassMethod(settingsClass,@selector(settings)),(IMP)isolatedSettings);
    Class viewClass=bundle.principalClass;
    check([viewClass isSubclassOfClass:ScreenSaverView.class],@"screen saver principal class");
    ScreenSaverView *preview=[[viewClass alloc] initWithFrame:NSMakeRect(0,0,640,360) isPreview:YES];
    NSWindow *sheet=preview.configureSheet;
    check(sheet!=nil,@"localized configuration nib loads");
    [preview startAnimation]; [preview startAnimation];
    check(preview.isAnimating,@"idempotent start");
    pump(0.1); [preview stopAnimation]; [preview stopAnimation];
    check(!preview.isAnimating,@"idempotent stop");
    // Exercise video playback, end notifications, asynchronous metadata and restart.
    NSString *clip=[NSTemporaryDirectory() stringByAppendingPathComponent:@"SaveHollywood-smoke.mov"];
    [NSFileManager.defaultManager removeItemAtPath:clip error:NULL];
    NSError *error=nil;
    AVAssetWriter *writer=[AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:clip] fileType:AVFileTypeQuickTimeMovie error:&error];
    AVAssetWriterInput *input=[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:@{AVVideoCodecKey:AVVideoCodecTypeH264,AVVideoWidthKey:@64,AVVideoHeightKey:@64}];
    AVAssetWriterInputPixelBufferAdaptor *adaptor=[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:input sourcePixelBufferAttributes:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB),(id)kCVPixelBufferWidthKey:@64,(id)kCVPixelBufferHeightKey:@64}];
    [writer addInput:input]; check([writer startWriting],@"generate test movie"); [writer startSessionAtSourceTime:kCMTimeZero];
    CVPixelBufferRef pixel=NULL;
    check(CVPixelBufferPoolCreatePixelBuffer(NULL,adaptor.pixelBufferPool,&pixel)==kCVReturnSuccess,@"allocate test frame");
    CVPixelBufferLockBaseAddress(pixel,0); memset(CVPixelBufferGetBaseAddress(pixel),128,CVPixelBufferGetBytesPerRow(pixel)*64); CVPixelBufferUnlockBaseAddress(pixel,0);
    for(int i=0;i<30;i++) { while(!input.readyForMoreMediaData) pump(0.01); check([adaptor appendPixelBuffer:pixel withPresentationTime:CMTimeMake(i,30)],@"write test frame"); }
    CVPixelBufferRelease(pixel); [input markAsFinished];
    __block BOOL done=NO; [writer finishWritingWithCompletionHandler:^{done=YES;}]; while(!done) pump(0.05);
    check(writer.status==AVAssetWriterStatusCompleted,@"finish test movie");
    testSettings.assets=[NSMutableArray arrayWithObject:clip]; testSettings.showMetadata=YES;
    testSettings.showMetadataMode=kMovieFrameShowMetadataPeriodically;
    ScreenSaverView *full=[[viewClass alloc] initWithFrame:NSMakeRect(0,0,640,360) isPreview:NO];
    [full startAnimation]; pump(1.5);
    AVPlayerLayer *layer=[full valueForKey:@"_AVPlayerLayer"];
    check(layer.player.currentItem!=nil,@"movie becomes current player item");
    check(layer.player.currentItem.status==AVPlayerItemStatusReadyToPlay && CMTimeGetSeconds(layer.player.currentTime)>0.1,@"movie playback clock advances");
    [full stopAnimation]; pump(0.2); check([full valueForKey:@"_timer"]==nil,@"timer released on stop");
    [full startAnimation]; pump(0.2); [full stopAnimation]; pump(0.2);
    [NSFileManager.defaultManager removeItemAtPath:clip error:NULL];
    NSLog(@"PASS: bundle load, options nib, fractional volume, start/stop, movie playback, metadata stop/restart.");
} return 0; }
