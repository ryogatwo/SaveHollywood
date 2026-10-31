// Copyright (c) 2026 James Marculewicz. See ../LICENSE.
#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
#import <AVFoundation/AVFoundation.h>
#import "SHSettings.h"
#import "SHPlayingAssetsRegister.h"
#import <objc/runtime.h>
@interface ScreenSaverView (SHPlaybackTest)
- (BOOL)playNextAsset:(NSDictionary *)asset canPlaySameRandomMovieTwice:(BOOL)allowSame;
@end
static SHSettings *testSettings;
static SHSettings *isolatedSettings(id self, SEL cmd) { return testSettings; }
static BOOL reportsStopped(id self, SEL cmd) { return NO; }
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
    AVAssetWriterInput *audio=[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:@{AVFormatIDKey:@(kAudioFormatMPEG4AAC),AVSampleRateKey:@44100,AVNumberOfChannelsKey:@1,AVEncoderBitRateKey:@64000}];
    [writer addInput:input]; [writer addInput:audio];
    check([writer startWriting],@"generate test movie"); [writer startSessionAtSourceTime:kCMTimeZero];
    CVPixelBufferRef pixel=NULL;
    check(CVPixelBufferPoolCreatePixelBuffer(NULL,adaptor.pixelBufferPool,&pixel)==kCVReturnSuccess,@"allocate test frame");
    CVPixelBufferLockBaseAddress(pixel,0); memset(CVPixelBufferGetBaseAddress(pixel),128,CVPixelBufferGetBytesPerRow(pixel)*64); CVPixelBufferUnlockBaseAddress(pixel,0);
    for(int i=0;i<30;i++) { while(!input.readyForMoreMediaData) pump(0.01); check([adaptor appendPixelBuffer:pixel withPresentationTime:CMTimeMake(i,30)],@"write test frame"); }
    CVPixelBufferRelease(pixel); [input markAsFinished];
    AudioStreamBasicDescription pcm={44100,kAudioFormatLinearPCM,kAudioFormatFlagIsSignedInteger|kAudioFormatFlagIsPacked,2,1,2,1,16,0};
    CMAudioFormatDescriptionRef format=NULL;
    check(CMAudioFormatDescriptionCreate(NULL,&pcm,0,NULL,0,NULL,NULL,&format)==noErr,@"create audio format");
    for (int chunk=0;chunk<10;chunk++) {
        CMBlockBufferRef block=NULL;
        check(CMBlockBufferCreateWithMemoryBlock(NULL,NULL,8820,kCFAllocatorDefault,NULL,0,8820,kCMBlockBufferAssureMemoryNowFlag,&block)==kCMBlockBufferNoErr,@"allocate audio samples");
        char *bytes=NULL;
        check(CMBlockBufferGetDataPointer(block,0,NULL,NULL,&bytes)==kCMBlockBufferNoErr && bytes!=NULL,@"access audio samples");
        for(int n=0;n<4410;n++) ((int16_t *)bytes)[n]=(int16_t)(1500*sin(2*M_PI*440*(chunk*4410+n)/44100.0));
        CMSampleTimingInfo timing={CMTimeMake(1,44100),CMTimeMake(chunk*4410,44100),kCMTimeInvalid};
        size_t size=2; CMSampleBufferRef samples=NULL;
        check(CMSampleBufferCreateReady(NULL,block,format,4410,1,&timing,1,&size,&samples)==noErr,@"create audio sample buffer");
        while(!audio.readyForMoreMediaData) pump(0.01);
        check([audio appendSampleBuffer:samples],@"encode audio track");
        CFRelease(samples); CFRelease(block);
    }
    CFRelease(format); [audio markAsFinished];
    __block BOOL done=NO; [writer finishWritingWithCompletionHandler:^{done=YES;}]; while(!done) pump(0.05);
    check(writer.status==AVAssetWriterStatusCompleted,@"finish test movie");
    check([[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:clip] options:nil] tracksWithMediaType:AVMediaTypeAudio].count==1,@"test movie contains audio");
    testSettings.assets=[NSMutableArray arrayWithObject:clip]; testSettings.showMetadata=YES;
    testSettings.showMetadataMode=kMovieFrameShowMetadataPeriodically;
    ScreenSaverView *full=[[viewClass alloc] initWithFrame:NSMakeRect(0,0,640,360) isPreview:NO];
    [full startAnimation];
    AVPlayerLayer *layer=[full valueForKey:@"_AVPlayerLayer"];
    for(int wait=0;wait<100 && !(layer.player.currentItem.status==AVPlayerItemStatusReadyToPlay && CMTimeGetSeconds(layer.player.currentTime)>0.1);wait++) pump(0.05);
    NSLog(@"Audio/video player status=%ld rate=%g time=%g error=%@",(long)layer.player.currentItem.status,layer.player.rate,CMTimeGetSeconds(layer.player.currentTime),layer.player.currentItem.error);
    check(layer.player.currentItem!=nil,@"movie becomes current player item");
    check(layer.player.currentItem.status==AVPlayerItemStatusReadyToPlay && CMTimeGetSeconds(layer.player.currentTime)>0.1,@"movie playback clock advances");
    AVPlayer *stoppedPlayer=layer.player;
    // A host can reset its animation flag before asking the module to clean up.
    Class stoppedHost=objc_allocateClassPair(viewClass,"SHStoppedHostTest",0);
    class_addMethod(stoppedHost,@selector(isAnimating),(IMP)reportsStopped,"c@:");
    objc_registerClassPair(stoppedHost);
    object_setClass(full,stoppedHost);
    [full stopAnimation];
    object_setClass(full,viewClass);
    pump(0.2);
    check(stoppedPlayer.muted && stoppedPlayer.currentItem==nil,@"stop releases media even when host reports not animating");
    check([full valueForKey:@"_timer"]==nil,@"timer released on stop");
    // Newer hosts can detach a view without calling stopAnimation at all.
    NSWindow *host=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,640,360) styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
    [host.contentView addSubview:full];
    [full startAnimation]; pump(0.3);
    AVPlayer *detachedPlayer=((AVPlayerLayer *)[full valueForKey:@"_AVPlayerLayer"]).player;
    check(detachedPlayer.currentItem!=nil,@"detachment test starts media");
    [full removeFromSuperview]; pump(0.2);
    check(detachedPlayer.muted && detachedPlayer.currentItem==nil,@"detaching view stops audio and releases media");
    [full startAnimation]; pump(0.3);
    AVPlayer *dismissedPlayer=((AVPlayerLayer *)[full valueForKey:@"_AVPlayerLayer"]).player;
    check(dismissedPlayer.currentItem!=nil,@"dismissal test starts media");
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.screensaver.willstop" object:nil userInfo:nil deliverImmediately:YES];
    for(int wait=0;wait<60 && dismissedPlayer.currentItem!=nil;wait++) pump(0.05);
    check(dismissedPlayer.muted && dismissedPlayer.currentItem==nil,@"system dismissal stops audio without host stopAnimation");
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    pump(0.1);
    check([full valueForKey:@"_AVPlayerLayer"]==nil,@"late completion cannot restart stopped playback");
    [full startAnimation]; pump(0.3);
    AVPlayer *replacedPlayer=((AVPlayerLayer *)[full valueForKey:@"_AVPlayerLayer"]).player;
    check([full playNextAsset:nil canPlaySameRandomMovieTwice:YES],@"replace playing movie");
    check(replacedPlayer.muted && replacedPlayer.currentItem==nil,@"movie replacement retires previous audio player");
    AVPlayer *fallbackPlayer=((AVPlayerLayer *)[full valueForKey:@"_AVPlayerLayer"]).player;
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.screensaver.didstop" object:nil userInfo:nil deliverImmediately:YES];
    for(int wait=0;wait<60 && (fallbackPlayer.currentItem!=nil || !fallbackPlayer.muted);wait++) pump(0.05);
    // AVFoundation may report a stale desired rate for an empty player in a VM.
    // Muting plus removal of its media item guarantees it cannot produce audio.
    NSLog(@"Fallback player rate=%g item=%@ active=%@",fallbackPlayer.rate,fallbackPlayer.currentItem,[full valueForKey:@"_playbackActive"]);
    check(fallbackPlayer.muted && fallbackPlayer.currentItem==nil,@"didstop fallback releases media");
    [full startAnimation]; pump(0.2); [full stopAnimation]; pump(0.2);
    [NSFileManager.defaultManager removeItemAtPath:clip error:NULL];
    NSLog(@"PASS: bundle/options, preferences, audio/video playback, host-flag cleanup, view detachment, system dismissal, late callbacks and restart.");
} return 0; }
