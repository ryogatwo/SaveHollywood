#import <Cocoa/Cocoa.h>
int main(int argc,const char **argv) { @autoreleasepool {
 if(argc!=2) return 2;
 [NSApplication sharedApplication];
 NSBundle *b=[NSBundle bundleWithPath:[NSString stringWithUTF8String:argv[1]]];
 if(![b load]) return 2;
 for(NSString *name in @[@"SHSecondaryBox",@"SHLightGrayBackgroundView"]) {
  NSView *v=[[[b classNamed:name] alloc] initWithFrame:NSMakeRect(0,0,20,20)];
  if(!v) { NSLog(@"Missing class %@",name); return 3; }
  v.appearance=[NSAppearance appearanceNamed:NSAppearanceNameAqua];
  NSBitmapImageRep *bitmap=[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:100 pixelsHigh:100 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
  [NSColor.blackColor setFill]; NSRectFill(NSMakeRect(0,0,100,100));
  [v drawRect:NSMakeRect(0,0,100,100)];
  [NSGraphicsContext restoreGraphicsState];
  NSLog(@"%@ inside=%@",name,[bitmap colorAtX:10 y:90]);
  NSColor *inside=[[bitmap colorAtX:10 y:90] colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
  if(inside.redComponent<0.1) { NSLog(@"FAIL: %@ lost its background fill",name); return 1; }
  NSColor *outside=[[bitmap colorAtX:50 y:50] colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
  if(outside.redComponent>0.01 || outside.greenComponent>0.01 || outside.blueComponent>0.01) { NSLog(@"FAIL: %@ paints over neighboring controls",name); return 1; }
 }
 NSLog(@"PASS: section backgrounds stay inside their bounds");
 } return 0; }
