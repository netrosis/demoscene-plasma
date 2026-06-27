#import "Window.h"
#import <AppKit/AppKit.h>

static NSWindow* gWindow = nil;
static bool gShouldClose = false;

@interface PixelBufferView : NSView {
    uint8_t* localBuffer;
    int bufferWidth;
    int bufferHeight;
}
- (void)updateBuffer:(const color4B*)newBuffer width:(int)w height:(int)h;
@end

@implementation PixelBufferView

- (void)dealloc {
    if (localBuffer) free(localBuffer);
}

- (void)updateBuffer:(const color4B*)newBuffer width:(int)w height:(int)h {
    bufferWidth = w;
    bufferHeight = h;
    size_t size = w * h * 4;
    
    if (!localBuffer) {
        localBuffer = (uint8_t*)malloc(size);
    }
    memcpy(localBuffer, newBuffer, size);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay:YES];
    });
}

- (void)drawRect:(NSRect)dirtyRect {
    if (!localBuffer) return;

    CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
    
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
    
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);

    NSRect bounds = [self bounds];
    float targetAspect = (float)bufferWidth / (float)bufferHeight; // 160.0 / 144.0
    
    float renderWidth = bounds.size.width;
    float renderHeight = bounds.size.width / targetAspect;
    
    if (renderHeight > bounds.size.height) {
        renderHeight = bounds.size.height;
        renderWidth = bounds.size.height * targetAspect;
    }
    
    float xOffset = (bounds.size.width - renderWidth) / 2.0;
    float yOffset = (bounds.size.height - renderHeight) / 2.0;
    NSRect targetRect = NSMakeRect(xOffset, yOffset, renderWidth, renderHeight);

    NSBitmapImageRep* rep = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:&localBuffer
                      pixelsWide:bufferWidth
                      pixelsHigh:bufferHeight
                   bitsPerSample:8
                 samplesPerPixel:4
                        hasAlpha:YES
                        isPlanar:NO
                  colorSpaceName:NSDeviceRGBColorSpace
                     bitmapFormat:NSBitmapFormatAlphaNonpremultiplied
                      bytesPerRow:bufferWidth * 4
                     bitsPerPixel:32];

    [rep drawInRect:targetRect];
}
@end

@interface WindowDelegate : NSObject <NSWindowDelegate>
@end

@implementation WindowDelegate
- (void)windowWillClose:(NSNotification *)notification {
    gShouldClose = true;
}
@end

void WindowBridge::initWindow(int width, int height) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    int scale = 3;
    NSRect frame = NSMakeRect(0, 0, width * scale, height * scale);
    
    NSUInteger styleMask = NSWindowStyleMaskTitled |
                           NSWindowStyleMaskClosable |
                           NSWindowStyleMaskResizable |
                           NSWindowStyleMaskMiniaturizable;

    gWindow = [[NSWindow alloc] initWithContentRect:frame
                                          styleMask:styleMask
                                            backing:NSBackingStoreBuffered
                                              defer:NO];
    
    [gWindow setTitle:@"Demoscene Plasma"];
    [gWindow center];
    
    PixelBufferView* view = [[PixelBufferView alloc] initWithFrame:frame];
    [gWindow setContentView:view];
    
    WindowDelegate* delegate = [[WindowDelegate alloc] init];
    [gWindow setDelegate:delegate];

    [gWindow makeKeyAndOrderFront:nil];
    [NSApp finishLaunching];
}

void WindowBridge::updateFramebuffer(const color4B* buffer) {
    PixelBufferView* view = (PixelBufferView*)[gWindow contentView];
    [view updateBuffer:buffer width:160 height:144];
}

bool WindowBridge::shouldClose() {
    return gShouldClose;
}

void WindowBridge::pollEvents() {
    @autoreleasepool {
        NSEvent* event;
        while ((event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                           untilDate:[NSDate distantPast]
                                              inMode:NSDefaultRunLoopMode
                                             dequeue:YES])) {
            [NSApp sendEvent:event];
        }
    }
}
