//
//  NNEasyPD.m
//
//  Created by Cady Holmes.
//  Copyright (c) 2015 Cady Holmes.
//

#import "NNEasyPD.h"

@implementation NNEasyPD

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self createDispatcher];
    }
    return self;
}

- (instancetype)initWithPatch:(NSString*)patchName
{
    self = [super init];
    if (self) {
        self.patch = patchName;
        [self createDispatcher];
        [self loadPatch:patchName];
    }
    return self;
}

- (void)sendFloat:(float)f toReceiver:(NSString*)r {
    [PdBase sendFloat:f toReceiver:r];
}
- (void)sendBangToReceiver:(NSString*)r {
    [PdBase sendBangToReceiver:r];
}
- (void)sendSymbol:(NSString*)s toReceiver:(NSString*)r {
    [PdBase sendSymbol:s toReceiver:r];
}
- (void)sendMessage:(NSString*)s withArguments:(NSArray*)a toReceiver:(NSString*)r {
    [PdBase sendMessage:s withArguments:a toReceiver:r];
}


- (UIViewController *)currentTopViewController {
    UIViewController *topVC = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

- (void)simpleAlert:(NSString*)title message:(NSString*)message {
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:title
                                  message:message
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    [alert addAction:ok];
    
    [[self currentTopViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)createDispatcher {
    /* Account for the 48k native sampling rate on iPhone 6s */
    float sr = 44100;
    UIViewController *currentTopVC = [self currentTopViewController];
    if ([[currentTopVC.view traitCollection] forceTouchCapability] == UIForceTouchCapabilityAvailable) {
        sr = 48000;
    }
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationWillTerminate:)
     name:UIApplicationWillTerminateNotification
     object:[UIApplication sharedApplication]];
    
    audioController = [[PdAudioController alloc] init];
    if ([audioController configurePlaybackWithSampleRate:sr
                                          numberChannels:2
                                            inputEnabled:NO
                                           mixingEnabled:YES] != PdAudioOK )
//    if ([audioController configureAmbientWithSampleRate:sr
//                                         numberChannels:2
//                                          mixingEnabled:YES] != PdAudioOK )
    {
        [self simpleAlert:@"Audio Error" message:@"Failed to initialize PD audio controller."];
    } else {
        [self setActive:YES];
        dispatcher = [[PdDispatcher alloc] init];
        [PdBase setDelegate:self];
        [PdBase setMidiDelegate:self];
    }
    
    self.patches = [[NSMutableArray alloc] init];
}

- (void)listenToReceivers:(NSArray*)receivers {
    self.receivers = [NSMutableArray arrayWithArray:receivers];
    for (NSString *str in receivers) {
        [PdBase subscribe:str];
    }
}

- (void)loadPatch:(NSString*)patchString {
    
    patchFile = [PdBase openFile:patchString path:[[NSBundle mainBundle] resourcePath]];
    if (!patchFile) {
        [self simpleAlert:@"PD Error" message:@"Failed to load patch."];
    }
}
- (void)addPatchToPatches:(NSString*)patch {
    PdFile *patche = [PdFile openFileNamed:patch path:[[NSBundle mainBundle] resourcePath]];
    if (!patche) {
        [self simpleAlert:@"PD Error" message:@"Failed to load patch."];
    } else {
        NSLog(@"opened patch with $0 = %d", [patche dollarZero]);
        [self.patches addObject:patche];
    }
}
- (int)dollarZeroForPatchAtIndex:(int)index {
    PdFile *file = [self.patches objectAtIndex:index];
    int dollarZero = [file dollarZero];
    return dollarZero;
}

- (void)unloadPatch {
    [PdBase closeFile:patchFile];
    patchFile = nil;
}

- (void)unloadPatches {
    if (self.patches.count > 0) {
        [self.patches removeAllObjects];
    }
}

- (void)setActive:(BOOL)isActive {
    if (isActive == YES) {
        audioController.active = YES;
    } else {
        audioController.active = NO;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self setActive:NO];
    [self unloadPatch];
    audioController = nil;
    dispatcher = nil;
    patchFile = nil;
    self.patch = nil;
    self.patches = nil;
}

#pragma mark - PdRecieverDelegate

// uncomment this to get print statements from pd
- (void)receivePrint:(NSString *)message {
    //NSLog(@"%@", message);
    
    NSArray *objects = @[@"Print",message];
    NSArray *keys = @[@"receive",@"message"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receiveBangFromSource:(NSString *)source {
    //NSLog(@"Bang from %@", source);
   
    NSArray *objects = @[source,@"bang"];
    NSArray *keys = @[@"receive",@"message"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receiveFloat:(float)received fromSource:(NSString *)source {
    //NSLog(@"Float from %@: %f", source, received);
    
    NSArray *objects = @[source,[NSNumber numberWithFloat:received]];
    NSArray *keys = @[@"receive",@"float"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receiveSymbol:(NSString *)symbol fromSource:(NSString *)source {
    //NSLog(@"Symbol from %@: %@", source, symbol);
    
    NSArray *objects = @[source,symbol];
    NSArray *keys = @[@"receive",@"symbol"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receiveList:(NSArray *)list fromSource:(NSString *)source {
    //NSLog(@"List from %@", source);

    NSArray *objects = @[source,list];
    NSArray *keys = @[@"receive",@"list"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receiveMessage:(NSString *)message withArguments:(NSArray *)arguments fromSource:(NSString *)source {
    //NSLog(@"Message to %@ from %@", message, source);
    
    NSArray *objects = @[source,message,arguments];
    NSArray *keys = @[@"receive",@"message",@"arguments"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receiveNoteOn:(int)pitch withVelocity:(int)velocity forChannel:(int)channel{
    //NSLog(@"NoteOn: %d %d %d", channel, pitch, velocity);

    NSArray *objects = @[@"midi-note-on",[NSNumber numberWithInt:channel],[NSNumber numberWithInt:pitch],[NSNumber numberWithInt:velocity]];
    NSArray *keys = @[@"receive",@"channel",@"note",@"velocity"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receiveControlChange:(int)value forController:(int)controller forChannel:(int)channel{
    //NSLog(@"Control Change: %d %d %d", channel, controller, value);

    NSArray *objects = @[@"midi-control-change",[NSNumber numberWithInt:channel],[NSNumber numberWithInt:controller],[NSNumber numberWithInt:value]];
    NSArray *keys = @[@"receive",@"channel",@"controller",@"value"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receiveProgramChange:(int)value forChannel:(int)channel{
    //NSLog(@"Program Change: %d %d", channel, value);

    NSArray *objects = @[@"midi-program-change",[NSNumber numberWithInt:channel],[NSNumber numberWithInt:value]];
    NSArray *keys = @[@"receive",@"channel",@"value"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receivePitchBend:(int)value forChannel:(int)channel{
    //NSLog(@"Pitch Bend: %d %d", channel, value);
    
    NSArray *objects = @[@"midi-pitch-bend",[NSNumber numberWithInt:channel],[NSNumber numberWithInt:value]];
    NSArray *keys = @[@"receive",@"channel",@"value"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receiveAftertouch:(int)value forChannel:(int)channel{
    //NSLog(@"Aftertouch: %d %d", channel, value);
    
    NSArray *objects = @[@"midi-aftertouch",[NSNumber numberWithInt:channel],[NSNumber numberWithInt:value]];
    NSArray *keys = @[@"receive",@"channel",@"value"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receivePolyAftertouch:(int)value forPitch:(int)pitch forChannel:(int)channel{
    //NSLog(@"Poly Aftertouch: %d %d %d", channel, pitch, value);
    
    NSArray *objects = @[@"midi-poly-aftertouch",[NSNumber numberWithInt:pitch],[NSNumber numberWithInt:value]];
    NSArray *keys = @[@"receive",@"note",@"value"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

- (void)receiveMidiByte:(int)byte forPort:(int)port{
    //NSLog(@"Midi Byte: %d 0x%X", port, byte);
    
    NSArray *objects = @[@"midi-byte",[NSNumber numberWithInt:port],[NSString stringWithFormat:@"0x%X",byte]];
    NSArray *keys = @[@"receive",@"port",@"byte"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    id<NNEasyPDDelegate> strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(receive:)]) {
        [strongDelegate receive:dict];
    }
}

@end
