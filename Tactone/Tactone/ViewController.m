//
//  ViewController.m
//
//  Created by Cady Holmes on 12/28/17.
//  Copyright © 2017 Cady Holmes. All rights reserved.
//

#import "ViewController.h"
#import "HapticHelper.h"
#import "NNSlider.h"
#import "NNEasyPD.h"
#import "kdTableView.h"
#import "kdPrimitiveDataStore.h"
#import <StoreKit/StoreKit.h>

@interface ViewController () <UITextFieldDelegate, kdTableViewDelegate>
{
    float sw;
    float sh;
    
    float bpm;
    float maxBeats;
    float maxBPM;
    
    float fontSize;
    NSString *globalFont;
    
    NNSlider *bpmDial;
    NNSlider *beatDial;
    NNSlider *upBeatDial;
    
    UIView *helpButton;
    UIView *startButton;
    UILabel *startLabel;
    
    UILabel *hamburger;
    
    UITextField *currentTextField;
    
    UIImageView *hapticButton;
    UIImageView *soundButton;
    UIImageView *soundTypeButton;
    
    BOOL haptics;
    BOOL sound;
    
    NSTimer *timer;
    
    UIView *tapView;
    UILabel *tapViewLabel;
    NSTimer *tapTimer;
    NSMutableArray *tapTimes;
    int tapCount;
    double lastTime;
    
    int beats;
    int upbeat;
    int count;
    int type;
    
    NSArray *menu;
    UIView *saveMenu;
    
    NNEasyPD *pd;
    
    kdTableView *tableView;
    kdTableView *tableViewMini;
    
    kdPrimitiveDataStore *globalSettings;
    kdPrimitiveDataStore *lastSettings;
    kdPrimitiveDataStore *tableSettings;
    
    NSArray *currentSettings;
    
    BOOL hamburgerWasOpen;
    
    UILabel *warningLabel;
    BOOL showingWarning;
}

@end

@implementation ViewController

-(BOOL)shouldAutorotate {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadDefaults];
    [self addDials];
    [self addHamburger];
    [self addMenuButtons];
    [self addTapForBPM];
    [self addHelpButton];
    [self addTables];
    [self handleOpenCount];
}

- (void)handleOpenCount {
    if (!globalSettings.data) {
        int openCount = 1;
        [globalSettings save:@[[NSNumber numberWithInt:openCount]]];
    } else {
        int openCount = [[globalSettings.data lastObject] intValue];
        openCount++;
        openCount = openCount % 10;
        openCount = MAX(openCount, 1);
        
        [globalSettings save:@[[NSNumber numberWithInt:openCount]]];
        
        if (openCount == 3) {
            [SKStoreReviewController requestReview];
        }
    }
}

- (void)checkHaptics {
    if (![HapticHelper checkForHapticFeedback]) {
        hapticButton.alpha = .3;
    }
}

- (void)addTables {
    lastSettings = [[kdPrimitiveDataStore alloc] initWithFile:@"lastSettings"];
    tableSettings = [[kdPrimitiveDataStore alloc] initWithFile:@"tableSettings"];
    
    tableView = [[kdTableView alloc] initWithFrame:CGRectMake(0, 0, sw, sh)];
    tableView.canReorder = YES;
    tableView.animate = YES;
    tableView.allowsEditing = YES;
    tableView.hasCloseButton = YES;
    tableView.delegate = self;
    
    tableViewMini = [[kdTableView alloc] initWithFrame:CGRectMake(0, 80, sw*.375, sh*.275)];
    tableViewMini.fontSize = 16;
    tableViewMini.topMargin = 10;
    tableViewMini.bottomMargin = 10;
    tableViewMini.showType = kdModalShow_Slide_Left;
    tableViewMini.delegate = self;
    
    if (tableSettings.data.count > 0) {
        tableView.data = [[NSMutableArray alloc]  initWithArray:tableSettings.data];
        tableViewMini.data = [[NSMutableArray alloc]  initWithArray:tableSettings.data];
    }
    
    if (lastSettings.data.count == 0) {
        [self saveCurrentSettings];
    } else {
        currentSettings = [[NSArray alloc] initWithArray:lastSettings.data];
        [self updateSettings];
        [self updateUI];
    }
    
    [self.view addSubview:tableView];
    [self.view addSubview:tableViewMini];
    [tableViewMini show];
}

- (void)addTapForBPM {
    float w = sw * .4;
    float h = sh * .3;
    
    tapView = [[UIView alloc] initWithFrame:CGRectMake(0, sh - h, w, h)];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapForBPM:)];
    [tapView addGestureRecognizer:tap];
    
    tapViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tapView.bounds.size.width, fontSize*1.1)];
    tapViewLabel.textAlignment = NSTextAlignmentCenter;
    tapViewLabel.font = [UIFont fontWithName:globalFont size:fontSize];
    tapViewLabel.text = @"Tap for BPM";
    tapViewLabel.center = CGPointMake(tapView.bounds.size.width/2, tapView.bounds.size.height/2);
    [self fade:tapViewLabel alpha:0 duration:.2];
    [tapView addSubview:tapViewLabel];
    
    tapTimes = [[NSMutableArray alloc] init];
    
    [self.view addSubview:tapView];
}
- (void)tapForBPM:(UITapGestureRecognizer*)sender {
    int history = 3;
    
    if (tapTimer) {
        [tapTimer invalidate];
        tapTimer = nil;
    }

    double time = CACurrentMediaTime();
    if (lastTime) {
        double deltaTime = time - lastTime;
        if (tapTimes.count > history - 1) {
            [tapTimes replaceObjectAtIndex:tapCount withObject:[NSNumber numberWithDouble:deltaTime]];
            tapCount++;
            tapCount = tapCount % history;
        } else {
            [tapTimes addObject:[NSNumber numberWithDouble:deltaTime]];
        }
    }
    lastTime = time;
    
    if (tapTimes.count > 0) {
        NSNumber *avg = [tapTimes valueForKeyPath:@"@avg.self"];
        float result = [avg floatValue];
        result = 60 / result;
        result = (int)result;

        result = MIN(bpmDial.valueScale+bpmDial.minimumValue, result);
        result = MAX(1,result);
        bpm = result;
        float value = bpm / (bpmDial.valueScale+bpmDial.minimumValue);
        [bpmDial updateValueTo:value];
    }
    
    tapTimer = [NSTimer scheduledTimerWithTimeInterval:1.4 repeats:NO block:^(NSTimer*t){
        tapCount = 0;
        lastTime = 0;
        [tapTimes removeAllObjects];
        tapTimer = nil;
        [self fade:tapViewLabel alpha:0 duration:.6];
        
        if (timer) {
            [self startTimer];
        }
    }];
    
    [self jiggle:tapViewLabel amount:1.05];
    [self fade:tapViewLabel alpha:.5 duration:.2];
}

- (void)loadDefaults {
    sw = self.view.frame.size.width;
    sh = self.view.frame.size.height;
    
    maxBeats = 32;
    maxBPM = 400;
    fontSize = 20;
    count = 0;
    
    tapCount = 0;
    
    globalFont = @"HelveticaNeue-UltraLight";
    pd = [[NNEasyPD alloc] initWithPatch:@"tactone.pd"];
    
    bpm = 120;
    upbeat = 3;
    beats = 4;
    type = 0;
    haptics = YES;
    sound = YES;
    
    globalSettings = [[kdPrimitiveDataStore alloc] initWithFile:@"globalSettings"];
}

- (void)saveCurrentSettings {
    currentSettings = @[[NSNumber numberWithFloat:bpm],
                        [NSNumber numberWithFloat:upbeat],
                        [NSNumber numberWithFloat:beats],
                        [NSNumber numberWithFloat:type],
                        [NSNumber numberWithBool:haptics],
                        [NSNumber numberWithBool:sound]
                        ];
    [lastSettings save:currentSettings];
}

- (void)updateSettings {
    bpm     = [[currentSettings objectAtIndex:0] floatValue];
    upbeat  = [[currentSettings objectAtIndex:1] floatValue];
    beats   = [[currentSettings objectAtIndex:2] floatValue];
    type    = [[currentSettings objectAtIndex:3] floatValue];
    haptics = [[currentSettings objectAtIndex:4] boolValue];
    sound   = [[currentSettings objectAtIndex:5] boolValue];
}
- (void)updateUI {
    float bpmValue = bpm / maxBPM;
    float upbeatValue = upbeat / maxBeats;
    float beatValue = beats / maxBeats;
    
    
    [self wait:.2 then:^{
        [bpmDial updateValueTo:bpmValue];
        [upBeatDial updateValueTo:upbeatValue];
        [beatDial updateValueTo:beatValue];
        
        float dur = .3;
        float alpha = .3;
        if (haptics) {
            alpha = 1;
        }
        [self fade:hapticButton alpha:alpha duration:dur];
        
        alpha = .3;
        if (sound) {
            alpha = 1;
        }
        [self fade:soundButton alpha:alpha duration:dur];

        if (hamburger.tag > 9998) {
            switch (type) {
                case 0:
                    [self rotate:soundTypeButton degrees:0 duration:dur];
                    break;
                case 1:
                    [self rotate:soundTypeButton degrees:270 duration:dur];
                    break;
                case 2:
                    [self rotate:soundTypeButton degrees:180 duration:dur];
                    break;
                case 3:
                    [self rotate:soundTypeButton degrees:90 duration:dur];
                    break;
                default:
                    break;
            }
        }
    }];
}

- (void)addDials {
    NSMutableArray *dials = [[NSMutableArray alloc] init];
    float frameSize, fontSizeMod, x, y, w, h;
    int tag = 0;
    
    ///////////////////////////////
    //create settings
    float initialBPM    = bpm;
    float initialUpbeat = upbeat;
    float initialBeats  = beats;
    
    float bpmFrameSize      = sw * .7;
    float bpmX              = sw - (sw / 3);
    float bpmY              = sh / 4.5;
    float bpmFontSizeMod    = 1;
    
    float upbeatFrameSize   = sw * .4;
    float upbeatX           = sw - (sw / 4);
    float upbeatY           = sh - (sh / 1.9);
    float upbeatFontSizeMod = .8;
    
    float beatFrameSize     = sw * .6;
    float beatX             = sw / 3;
    float beatY             = sh - (sh / 2.25);
    float beatFontSizeMod   = 1;
    
    float startFrameSize    = sw * .7;
    float startX            = sw - (sw / 3);
    float startY            = sh - (sh / 5);
    float startFontSizeMod  = 2;
    
    BOOL iPad = [self iPadCheck];
    if (iPad) {
        bpmFrameSize = sw * .5;
        upbeatFrameSize = sw * .3;
        beatFrameSize = sw * .4;
        startFrameSize = sw * .5;
    }
    
    NSArray *dialText = @[@"BPM",
                          @"Upbeat",
                          @"Beats",
                          @"Start"];
    
    ///////////////////////////////
    //make dials
    NSArray *dialSettings = @[
                              @[[dialText objectAtIndex:0], [NSNumber numberWithFloat:maxBPM], [NSNumber numberWithFloat:initialBPM],
                                @[[NSNumber numberWithFloat:bpmFrameSize],
                                  [NSNumber numberWithFloat:bpmX],
                                  [NSNumber numberWithFloat:bpmY],
                                  [NSNumber numberWithFloat:bpmFontSizeMod]]
                                ],
                              @[[dialText objectAtIndex:1], [NSNumber numberWithFloat:maxBeats], [NSNumber numberWithFloat:initialUpbeat],
                                @[[NSNumber numberWithFloat:upbeatFrameSize],
                                  [NSNumber numberWithFloat:upbeatX],
                                  [NSNumber numberWithFloat:upbeatY],
                                  [NSNumber numberWithFloat:upbeatFontSizeMod]]
                                ],
                              @[[dialText objectAtIndex:2], [NSNumber numberWithFloat:maxBeats], [NSNumber numberWithFloat:initialBeats],
                                @[[NSNumber numberWithFloat:beatFrameSize],
                                  [NSNumber numberWithFloat:beatX],
                                  [NSNumber numberWithFloat:beatY],
                                  [NSNumber numberWithFloat:beatFontSizeMod]]
                                ]
                              ];
    
    for (int i = 0; i < dialSettings.count; i++) {
        NSArray *settings = [NSArray arrayWithArray:[dialSettings objectAtIndex:tag]];
        NSArray *frameSettings = [NSArray arrayWithArray:[settings objectAtIndex:3]];
        frameSize   = [[frameSettings objectAtIndex:0] floatValue];
        x           = [[frameSettings objectAtIndex:1] floatValue];
        y           = [[frameSettings objectAtIndex:2] floatValue];
        fontSizeMod = [[frameSettings objectAtIndex:3] floatValue];
        
        NNSlider *dial = [[NNSlider alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
        [dial addTarget:self action:@selector(sliderAction:withEvent:) forControlEvents:UIControlEventValueChanged];
        [dial addTarget:self action:@selector(sliderTouchDown:withEvent:) forControlEvents:UIControlEventTouchDown];
        [dial addTarget:self action:@selector(sliderTouchDrag:withEvent:) forControlEvents:UIControlEventTouchDragInside|UIControlEventTouchDragOutside];
        [dial addTarget:self action:@selector(sliderTouchEnd:withEvent:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
        dial.isDial = YES;
        dial.knobColor = [UIColor clearColor];
        dial.isClockwise = NO;
        dial.shouldFlip = YES;
        dial.hasLabel = YES;
        dial.minimumValue = 1;
        dial.isInt = YES;
        dial.valueScale = [[settings objectAtIndex:1] floatValue] - dial.minimumValue;
        dial.value = [[settings objectAtIndex:2] floatValue] / (dial.valueScale + dial.minimumValue);
        [dial setTag:tag];
        [dial setCenter:CGPointMake(x, y)];
        
        NNSlider *dial2 = [[NNSlider alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
        dial2.isDial = YES;
        dial2.knobColor = [UIColor clearColor];
        dial2.isClockwise = NO;
        dial2.shouldFlip = YES;
        dial2.hasLabel = NO;
        dial2.value = 1;
        dial2.alpha = .1;
        [dial2 setCenter:CGPointMake(dial.bounds.size.width/2, dial.bounds.size.height/2)];
        [dial2 setUserInteractionEnabled:NO];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDial:)];
        [tap setNumberOfTapsRequired:2];
        [dial addGestureRecognizer:tap];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frameSize, fontSize)];
        w = dial.bounds.size.width;
        h = dial.bounds.size.height;
        x = w / 2;
        y = (h - (h / 3));
        [label setFont:[UIFont fontWithName:globalFont size:fontSize*fontSizeMod]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setCenter:CGPointMake(x, y)];
        [label setText:[settings objectAtIndex:0]];
        
        [dial addSubview:dial2];
        [dial addSubview:label];
        [dials addObject:dial];
        tag++;
    }
    
    bpmDial     = [dials objectAtIndex:0];
    upBeatDial  = [dials objectAtIndex:1];
    beatDial    = [dials objectAtIndex:2];
    startButton = [self startButtonWithSize:startFrameSize
                                          x:startX
                                          y:startY
                                fontSizeMod:startFontSizeMod
                                        tag:tag];
    [self.view addSubview:bpmDial];
    [self.view addSubview:upBeatDial];
    [self.view addSubview:beatDial];
    [self.view addSubview:startButton];
}

- (UIView*)startButtonWithSize:(float)frameSize x:(float)x y:(float)y fontSizeMod:(float)fontSizeMod tag:(int)tag {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
    [view setTag:tag];
    [view setCenter:CGPointMake(x, y)];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDial:)];
    [view addGestureRecognizer:tap];
    
    NNSlider *dial = [[NNSlider alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
    dial.isDial = YES;
    dial.knobColor = [UIColor clearColor];
    dial.isClockwise = NO;
    dial.shouldFlip = YES;
    dial.hasLabel = NO;
    dial.value = 1;
    [dial setCenter:CGPointMake(view.bounds.size.width/2, view.bounds.size.height/2)];
    [dial setUserInteractionEnabled:NO];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
    [label setFont:[UIFont fontWithName:globalFont size:fontSize*fontSizeMod]];
    [label setText:@"Start"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setCenter:CGPointMake(view.bounds.size.width/2, view.bounds.size.height/2)];
    startLabel = label;
    
    [view addSubview:dial];
    [view addSubview:startLabel];
    
    return view;
}

- (void)addHamburger {
    float frameSize = fontSize * 2;
    float x = 45;
    float y = 55;
    hamburger = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
    [hamburger setCenter:CGPointMake(x, y)];
    [hamburger setTextAlignment:NSTextAlignmentCenter];
    [hamburger setFont:[UIFont fontWithName:globalFont size:fontSize*2]];
    [hamburger setText:@"≡"];
    [hamburger setUserInteractionEnabled:YES];
    [hamburger setTag:9998];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHamburger:)];
    [hamburger addGestureRecognizer:tap];
    
    [self.view addSubview:hamburger];
}

- (void)tapHamburger:(UITapGestureRecognizer *)sender {
    [self handleHamburger];
}

- (void)handleHamburger {
    if (hamburger.tag < 9999) {
        [self openHamburger];
    } else {
        [self closeHamburger];
    }
}
- (void)openHamburger {
    float degrees = 270;
    float dur = .2;
    float delay = .07;
    
    hamburger.tag = 9999;
    for (int i = 0; i < menu.count; i++) {
        [tableViewMini hide];
        [self slide:saveMenu amountX:0 amountY:0 duration:.3];
        [self slide:helpButton amountX:0 amountY:0 duration:.3];
        [self checkHaptics];
        [self wait:delay*i then:^{
            [self slide:[menu objectAtIndex:i] amountX:0 amountY:0 duration:dur];
            if (i == menu.count - 1) {
                [self wait:delay*(i+1) then:^{
                    switch (type) {
                        case 0:
                            //[self rotate:soundTypeButton degrees:0 duration:dur];
                            //[self jiggle:soundTypeButton amount:1.15];
                            break;
                        case 1:
                            [self rotate:soundTypeButton degrees:270 duration:dur];
                            break;
                        case 2:
                            [self rotate:soundTypeButton degrees:180 duration:dur];
                            break;
                        case 3:
                            [self rotate:soundTypeButton degrees:90 duration:dur];
                            break;
                        default:
                            break;
                    }
                }];
            }
        }];
    }
    [self rotate:hamburger degrees:degrees duration:.3];
}
- (void)closeHamburger {
    float degrees = 0;
    float delay = .07;
    hamburger.tag = 9998;
    [tableViewMini show];
    for (int i = 0; i < menu.count; i++) {
        [self slide:saveMenu amountX:-sw amountY:0 duration:.3];
        [self slide:helpButton amountX:-80 amountY:0 duration:.3];
        [self wait:delay*i then:^{
            [self slide:[menu objectAtIndex:i] amountX:-80 amountY:0 duration:.2];
        }];
    }
    [self rotate:hamburger degrees:degrees duration:.3];
}

- (void)addHelpButton {
    float frameSize = fontSize * 2;
    float x = 45;
    float y = sh - 55;
    
    helpButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
    [helpButton setCenter:CGPointMake(x, y)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
    [label setFont:[UIFont fontWithName:globalFont size:fontSize*2]];
    [label setText:@"?"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setCenter:CGPointMake(helpButton.bounds.size.width/2, (helpButton.bounds.size.height-(helpButton.bounds.size.height/3)))];
    
    [helpButton addSubview:label];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHelp:)];
    [helpButton addGestureRecognizer:tap];
    
    [self slide:helpButton amountX:-80 amountY:0 duration:.3];
    
    [self.view addSubview:helpButton];
}

- (void)addMenuButtons {
    float frameSize = fontSize * 2;
    float x = 45;
    float y = 55 + (frameSize * 1) + 20;

    UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
    image.image = [UIImage imageNamed:@"haptic"];
    image.center = CGPointMake(x, y);
    image.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHapticButton:)];
    [image addGestureRecognizer:tap];
    hapticButton = image;

    y = 55 + (frameSize * 2) + 45;
    image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
    image.image = [UIImage imageNamed:@"sound"];
    image.center = CGPointMake(x, y);
    image.userInteractionEnabled = YES;
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSoundButton:)];
    [image addGestureRecognizer:tap];
    soundButton = image;
    
    y = 55 + (frameSize * 3) + 70;
    image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frameSize, frameSize)];
    image.image = [UIImage imageNamed:@"drum"];
    image.center = CGPointMake(x, y);
    image.userInteractionEnabled = YES;
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSoundTypeButton:)];
    [image addGestureRecognizer:tap];
    soundTypeButton = image;
    
    menu = @[hapticButton,soundButton,soundTypeButton];
    
    float offset = -80;
    float duration = .1;
    for (UILabel *label in menu) {
        [self slide:label amountX:offset amountY:0 duration:duration];
        [self.view addSubview:label];
    }
    
    
    NSArray *saveMenuArray = @[@"save  ⤒",@"⤓  load"];
    float menuWidth = sw*.8;
    saveMenu = [[UIView alloc] init];
    [saveMenu setFrame:CGRectMake(sw-menuWidth, 0, menuWidth, frameSize)];
    [saveMenu setAlpha:1];
    //[saveMenu setBackgroundColor:[UIColor blueColor]];
    
    [saveMenu setCenter:CGPointMake(saveMenu.center.x, hamburger.center.y)];
    [saveMenu setBackgroundColor:[UIColor whiteColor]];
    y = saveMenu.bounds.size.height/2;
    for (int i = 0; i < saveMenuArray.count; i++) {
        UITapGestureRecognizer *tapSaveLoad = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSaveLoad:)];
        float x = (menuWidth/(saveMenuArray.count+1)) * (i+1);
        UILabel *icon = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, menuWidth/3, frameSize)];
        [icon setTag:i];
        [icon setTextAlignment:NSTextAlignmentCenter];
        [icon setFont:[UIFont fontWithName:globalFont size:fontSize]];
        [icon setCenter:CGPointMake(x, y)];
        [icon setText:[saveMenuArray objectAtIndex:i]];
        [icon setUserInteractionEnabled:YES];
        [icon addGestureRecognizer:tapSaveLoad];
        
        //[icon setBackgroundColor:[UIColor redColor]];
        
        [saveMenu addSubview:icon];
    }
    [self slide:saveMenu amountX:-sw amountY:0 duration:0];
    [self.view addSubview:saveMenu];
}

- (void)tapSaveLoad:(UITapGestureRecognizer*)sender {
    switch (sender.view.tag) {
        case 0:
            [tableView openSaveDialogue];
            break;
        case 1:
            [tableView show];
            break;
        default:
            break;
    }
    
    [self jiggle:sender.view amount:1.05];
}

-(void)kdTableView:(kdTableView*)tableView didSaveWithKey:(NSString*)key {
    [tableView addData:currentSettings forKey:key canEdit:YES];
    [tableSettings save:tableView.data];
    [self updateMiniTable];
}
-(void)kdTableView:(kdTableView*)tableView didSelectRowAtIndex:(int)index {
    [timer invalidate];
    timer = nil;
    startLabel.text = @"Start";
    
    currentSettings = [[NSArray alloc] initWithArray:[[tableSettings.data objectAtIndex:index] objectAtIndex:1]];
    [self updateSettings];
    [self updateUI];
    [self saveCurrentSettings];
    
    if (tableView.hasCloseButton) {
        [tableView hide];
    }
}
-(void)kdTableView:(kdTableView*)tableView movedRowFromIndex:(int)fromIndex toIndex:(int)toIndex {
    
}
-(void)kdTableView:(kdTableView*)tableView finishedMovingRowTo:(int)index {
    [tableSettings save:tableView.data];
    [self updateMiniTable];
}
-(void)kdTableView:(kdTableView*)tableView didDeleteDataAtIndex:(int)index {
    [tableSettings save:tableView.data];
    [self updateMiniTable];
}
-(void)kdTableView:(kdTableView*)tableView didRenameDataAtIndex:(int)index {
    [tableSettings save:tableView.data];
    [self updateMiniTable];
}
-(void)updateMiniTable {
    tableViewMini.data = [[NSMutableArray alloc]  initWithArray:tableSettings.data];
    [tableViewMini reloadData];
}

- (void)tapHapticButton:(UITapGestureRecognizer *)sender {
    if ([HapticHelper checkForHapticFeedback]) {
        haptics = !haptics;
        float dur = .3;
        float alpha = .3;
        if (haptics) {
            alpha = 1;
        }
        
        [self fade:sender.view alpha:alpha duration:dur];
        
        [self saveCurrentSettings];
    } else {
        if (![HapticHelper checkDeviceForHapticFeedback]) {
            [self showWarning:@"Haptics not supported on this device!"];
        } else if (![HapticHelper checkVersionForHapticFeedback]) {
            [self showWarning:@"Haptics requires iOS 10+!"];
        }
    }
    
    [self jiggle:sender.view amount:1.2];
}
- (void)tapSoundButton:(UITapGestureRecognizer *)sender {
    sound = !sound;
    float dur = .3;
    float alpha = .3;
    if (sound) {
        alpha = 1;
    }
    [self jiggle:sender.view amount:1.2];
    [self fade:sender.view alpha:alpha duration:dur];
    
    [self saveCurrentSettings];
}
- (void)tapSoundTypeButton:(UITapGestureRecognizer *)sender {
    type++;
    type = type % 4;
    [pd sendFloat:type toReceiver:@"type"];
    
    float dur = .3;

    switch (type) {
        case 0:
            [self rotate:sender.view degrees:0 duration:dur];
            break;
        case 1:
            [self rotate:sender.view degrees:270 duration:dur];
            break;
        case 2:
            [self rotate:sender.view degrees:180 duration:dur];
            break;
        case 3:
            [self rotate:sender.view degrees:90 duration:dur];
            break;
            
        default:
            break;
    }
    
    [self saveCurrentSettings];
}

- (void)startTimer {
    
    if (sound) {
        [self checkVolume];
    }
    
    count = -1;
    
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    startLabel.text = @"and";

    [pd sendFloat:type toReceiver:@"type"];

    timer = [NSTimer scheduledTimerWithTimeInterval:60/bpm repeats:YES block:^(NSTimer*t){
        count++;
        count = count % beats;
        startLabel.text = [NSString stringWithFormat:@"%d",count+1];
        
        float animAmount = 1.1;
        FeedbackType type = FeedbackType_Impact_Light;
        NSString *receiver = @"up";
        
        if (count == upbeat-1) {
            animAmount = 1.3;
            type = FeedbackType_Impact_Medium;
            receiver = @"upbeat";
        }
        if (count == 0) {
            animAmount = 1.6;
            type = FeedbackType_Impact_Heavy;
            receiver = @"down";
        }
        
        if (haptics) {
            [HapticHelper generateFeedback:type];
        }
        if (sound) {
            [pd sendBangToReceiver:receiver];
        }
        
        [self jiggle:startLabel amount:animAmount];
        
        if (!haptics && !sound) {
            float amount = 1.05;
            if (count == upbeat-1) {
                amount = 1.1;
            }
            if (count == 0) {
                amount = 1.15;
            }
            [self jiggle:bpmDial amount:amount];
            [self jiggle:beatDial amount:amount];
            [self jiggle:upBeatDial amount:amount];
            [self jiggle:startButton amount:amount];
        }
    }];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)sliderAction:(NNSlider *)dial withEvent:(UIEvent*)event {
    switch (dial.tag) {
        case 0:
            bpm = dial.value + dial.minimumValue;
            break;
        case 1:
            upbeat = dial.value + dial.minimumValue;
            [self checkUpbeat];
            break;
        case 2:
            beats = dial.value + dial.minimumValue;
            [self checkUpbeat];
            break;
            
        default:
            break;
    }
    [self saveCurrentSettings];
}
- (void)checkUpbeat {
    if (upbeat > beats) {
        [self fade:upBeatDial alpha:.2 duration:.3];
    } else {
        if (upBeatDial.alpha < 1) {
            [self fade:upBeatDial alpha:1 duration:.3];
        }
    }
}
- (void)sliderTouchDown:(NNSlider*)dial withEvent:(UIEvent*)event {
}
- (void)sliderTouchDrag:(NNSlider*)dial withEvent:(UIEvent*)event {
}
- (void)sliderTouchEnd:(NNSlider*)dial withEvent:(UIEvent*)event {
    //reset timer unless only upbeat changed
    if (dial.tag != 1) {
        if (timer) {
            [self startTimer];
        }
    }
}

- (void)tapDial:(UITapGestureRecognizer*)sender {
    int tag = (int)sender.view.tag;
    if (tag == 3) {
        [self tapStart];
    } else {
        [self openDialogueWithTag:tag];
    }
}

- (void)tapStart {
    if (!timer) {
        [self startTimer];
    } else {
        [timer invalidate];
        timer = nil;
        startLabel.text = @"Start";
    }
    [self jiggle:startButton amount:1.05];
    [self jiggle:startLabel amount:1.45];
}
- (void)openDialogueWithTag:(int)tag {
    UIView *view = [self makeDialoguePopup:YES];
    
    float textFieldMargin = 50;
    float textFieldHeight = 100;
    UITextField *textfield = [[UITextField alloc] initWithFrame:CGRectMake(textFieldMargin, view.bounds.size.height/3, sw-textFieldMargin, textFieldHeight)];
    textfield.font = [UIFont fontWithName:globalFont size:fontSize*1.25];
    textfield.autocorrectionType = UITextAutocorrectionTypeNo;
    textfield.keyboardType = UIKeyboardTypeNumberPad;
    textfield.clearButtonMode = UITextFieldViewModeWhileEditing;
    textfield.returnKeyType = UIReturnKeyDone;
    textfield.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textfield.delegate = self;
    textfield.borderStyle = UITextBorderStyleNone;
    textfield.tintColor = [UIColor blackColor];
    
    UIToolbar* toolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, sw, 50)];
    toolbar.barStyle = UIBarStyleDefault;
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelNumberPad:)];
    UIBarButtonItem *done = [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStylePlain target:self action:@selector(doneWithNumberPad:)];
    cancel.tag = tag;
    done.tag = tag;
    toolbar.items = @[cancel,
                    [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      done];
    [toolbar sizeToFit];
    textfield.inputAccessoryView = toolbar;
    
    NSString *place = @" ";
    switch (tag) {
        case 0:
            place = @"   BPM";
            break;
        case 1:
            place = @"   Upbeat";
            break;
        case 2:
            place = @"   Beats";
            break;
        default:
            break;
    }

    textfield.placeholder = place;
    textfield.tag = tag;
    
    currentTextField = textfield;
    [view addSubview:currentTextField];
    
    if (tag == 0) {
        NSArray *strings = @[@"Largo",
                             @"Adagio",
                             @"Andante",
                             @"Moderato",
                             @"Allegro",
                             @"Vivace"
                             ];
        NSArray *strings2 = @[@"40 - 60",
                             @"60 - 76",
                             @"76 - 108",
                             @"108 - 120",
                             @"120 - 156",
                             @"156 - 176"
                             ];
        for (int i = 0; i < strings.count; i++) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(sw*.25, (80+(fontSize*i))+(4*i), sw*.25, fontSize*1.1)];
            label.font = [UIFont fontWithName:globalFont size:fontSize];
            label.text = [strings objectAtIndex:i];
            [view addSubview:label];
        }
        for (int i = 0; i < strings2.count; i++) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(sw*.5, (80+(fontSize*i))+(4*i), sw*.25, fontSize*1.1)];
            label.font = [UIFont fontWithName:globalFont size:fontSize];
            label.text = [strings2 objectAtIndex:i];
            label.textAlignment = NSTextAlignmentRight;
            [view addSubview:label];
        }
    }
    
    [self animateViewGrowAndShow:view];
    [self.view addSubview:view];
    [currentTextField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self handleClose:currentTextField];
    return YES;
}

-(void)cancelNumberPad:(UIBarButtonItem*)button {
    [self removeTextfieldPopup:currentTextField.superview];
}

-(void)doneWithNumberPad:(UIBarButtonItem*)button {
    [self handleClose:currentTextField];
}

- (UIView*)makeDialoguePopup:(BOOL)close {
    UIView *view = [[UIView alloc] initWithFrame:self.view.frame];
    [view setBackgroundColor:[UIColor whiteColor]];
    
    if (close) {
        float closeSize = 50;
        float marginSize = 20;
        UILabel *close = [[UILabel alloc] initWithFrame:CGRectMake(view.bounds.size.width-closeSize-marginSize+7, marginSize, closeSize, closeSize)];
        [close setFont:[UIFont fontWithName:globalFont size:fontSize*1.5]];
        [close setUserInteractionEnabled:YES];
        [close setText:@"X"];
        [close setTextAlignment:NSTextAlignmentCenter];
        
        [view addSubview:close];
    }
    
    UITapGestureRecognizer *tapClose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClose:)];
    [view addGestureRecognizer:tapClose];
    
    return view;
}
- (void)tapClose:(UITapGestureRecognizer *)sender {
    [self handleClose:sender.view];
    [self cancelWarning];
}
- (void)handleClose:(UIView*)view {
    int tag = (int)view.tag;
    if (tag < 100) {
        
        if ([self checkIfNumber:currentTextField.text]) {
            switch (currentTextField.tag) {
                case 0:
                    [self handleCloseBPM:currentTextField];
                    break;
                case 1:
                    [self handleCloseUpbeat:currentTextField];
                    break;
                case 2:
                    [self handleCloseBeats:currentTextField];
                    break;
                default:
                    break;
            }
            
            if (timer) {
                [self startTimer];
            }
            
            [self saveCurrentSettings];
        } else {
            currentTextField.text = @"";
            [self showWarning:@"Numbers only please."];
        }
    } else {
        [self handleCloseHelp:view];
    }
}

- (void)handleCloseBPM:(UITextField*)textField {
    if (textField.text.length > 0) {
        NSString *str = textField.text;
        bpm = [str floatValue];
        bpm = MIN(bpmDial.valueScale+bpmDial.minimumValue, bpm);
        bpm = MAX(1,bpm);
        float value = bpm / (bpmDial.valueScale+bpmDial.minimumValue);
        [bpmDial updateValueTo:value];
    }
    
    [self removeTextfieldPopup:textField.superview];
}
- (void)handleCloseBeats:(UITextField*)textField {
    if (textField.text.length > 0) {
        NSString *str = textField.text;
        beats = [str floatValue];
        beats = MIN(beatDial.valueScale+beatDial.minimumValue, beats);
        beats = MAX(1,beats);
        float value = beats / (beatDial.valueScale+beatDial.minimumValue);
        [beatDial updateValueTo:value];
    }
    
    [self removeTextfieldPopup:textField.superview];
}
- (void)handleCloseUpbeat:(UITextField*)textField {
    if (textField.text.length > 0) {
        NSString *str = textField.text;
        upbeat = [str floatValue];
        upbeat = MIN(upBeatDial.valueScale+upBeatDial.minimumValue, upbeat);
        upbeat = MAX(1,upbeat);
        float value = upbeat / (upBeatDial.valueScale+upBeatDial.minimumValue);
        [upBeatDial updateValueTo:value];
    }
    
    [self removeTextfieldPopup:textField.superview];
}
- (void)removeTextfieldPopup:(UIView*)view {
    [self animateViewShrinkAndWink:view andRemoveFromSuperview:YES then:nil];
    currentTextField = nil;
}
- (void)handleCloseHelp:(UIView*)view {
    [self animateViewShrinkAndWink:view andRemoveFromSuperview:YES then:nil];
    
    if (!hamburgerWasOpen) {
        [self closeHamburger];
    }
    
    hamburgerWasOpen = nil;
}

- (void)tapHelp:(UITapGestureRecognizer*)sender {
    [self jiggle:sender.view amount:1.05];
    [self openHelp];
}

- (void)openHelp {
    
    if (hamburger.tag < 9999) {
        hamburgerWasOpen = NO;
        [self openHamburger];
    } else {
        hamburgerWasOpen = YES;
    }
    
    UIView *view = [self makeDialoguePopup:NO];
    view.tag = 100;
    
    view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.75];
    
    UIFont *font = [UIFont fontWithName:@"BradleyHandITCTT-Bold" size:fontSize * .9];
    
    float h = fontSize * 1.1;
    float w = sw * .6;
    float b = 5;
    
    //////////////////////////////////////
    //
    float x = sw *.05;
    float y = beatDial.center.y + h + (h / 2);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"drag a dial up and down"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    y = y + h + b;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"(or double tap it"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    y = y + h + b;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"to type in a number)"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    //////////////////////////////////////
    //
    x = sw - (sw * .6);
    y = upBeatDial.center.y - (h / 2);
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"select the upbeat"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    y = y + h + b;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"(for an audio cue)"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    
    //////////////////////////////////////
    //
    x = sw - (sw * .6);
    y = bpmDial.center.y - h - h - b;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"save and load"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    y = y + h + b;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"(edit the load list:"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    y = y + h + b;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"long press to reorder"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    y = y + h + b;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"swipe to delete)"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    
    //////////////////////////////////////
    //
    UIView *icon = [menu objectAtIndex:0];
    x = 30;
    y = icon.center.y;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"toggle haptics"];
    [label setTextAlignment:NSTextAlignmentLeft];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    icon = [menu objectAtIndex:1];
    y = icon.center.y;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"toggle sound"];
    [label setTextAlignment:NSTextAlignmentLeft];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    icon = [menu objectAtIndex:2];
    y = icon.center.y;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"change sound"];
    [label setTextAlignment:NSTextAlignmentLeft];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    
    //////////////////////////////////////
    //
    x = tapView.center.x;
    y = tapView.center.y - h - b;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"Start tapping"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(x, y)];
    [view addSubview:label];

    y = y + h + b;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, w, h)];
    [label setFont:font];
    [label setText:@"here to set BPM"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(x, y)];
    [view addSubview:label];
    
    //////////////////////////////////////
    //
    x = 20;
    y = sh - h - b;
    label = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, sw, h)];
    [label setFont:[UIFont fontWithName:globalFont size:fontSize*.9]];
    [label setText:@"superofficial@notnatural.co"];
    [label setTextAlignment:NSTextAlignmentLeft];
    [label setTextColor:[UIColor whiteColor]];
    [label setCenter:CGPointMake(label.center.x, y)];
    [view addSubview:label];
    
    [self animateViewGrowAndShow:view];
    [self.view addSubview:view];
}

- (void)jiggle:(UIView*)view amount:(float)amount {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.1f
                              delay:0.0f
             usingSpringWithDamping:.5f
              initialSpringVelocity:4.f
                            options:(UIViewAnimationOptionAllowUserInteraction |
                                     UIViewAnimationOptionCurveEaseOut)
                         animations:^{
                             view.transform = CGAffineTransformScale(CGAffineTransformIdentity, amount, amount);
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.12f
                                                   delay:0.0f
                                  usingSpringWithDamping:.3f
                                   initialSpringVelocity:10.0f
                                                 options:(UIViewAnimationOptionAllowUserInteraction |
                                                          UIViewAnimationOptionCurveEaseOut)
                                              animations:^{
                                                  view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
                                              }
                                              completion:^(BOOL finished) {
                                              }];
                         }];
    });
}
- (void)rotate:(UIView*)view degrees:(float)degrees duration:(float)dur {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:dur
                              delay:0.0f
             usingSpringWithDamping:.3f
              initialSpringVelocity:7.f
                            options:(UIViewAnimationOptionCurveEaseOut)
                         animations:^{
                             view.transform = CGAffineTransformMakeRotation(degrees * M_PI/180);
                         }
                         completion:^(BOOL finished) {
                         }];
    });
}

- (void)fade:(UIView*)view alpha:(float)alpha duration:(float)dur {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:dur
                              delay:0.0f
                            options:(UIViewAnimationOptionAllowUserInteraction |
                                     UIViewAnimationOptionCurveEaseInOut)
                         animations:^{
                             view.alpha = alpha;
                         }
                         completion:^(BOOL finished) {
                         }];
    });
}

- (void)slide:(UIView*)view amountX:(float)x amountY:(float)y duration:(float)dur {
    
    if (!x) {
        x = 0;
    }
    if (!y) {
        y = 0;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:dur
                              delay:0.0f
             usingSpringWithDamping:.7f
              initialSpringVelocity:4.f
                            options:(UIViewAnimationOptionAllowUserInteraction |
                                     UIViewAnimationOptionCurveEaseInOut)
                         animations:^{
                             view.transform = CGAffineTransformMakeTranslation(x, y);
                         }
                         completion:^(BOOL finished) {
                         }];
    });
}

- (void)animateViewGrowAndShow:(UIView*)view {
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{}];
    if (view) {
        [view.layer addAnimation:showAnimation() forKey:nil];
        view.layer.opacity = 1;
    }
    [CATransaction commit];
}

- (void)animateViewShrinkAndWink:(UIView*)view andRemoveFromSuperview:(BOOL)removeFromSuperview then:(void(^)(void))callback {
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [CATransaction begin];
        if (view) {
            [view.layer removeAnimationForKey:@"opacity"];
            [view.layer removeAnimationForKey:@"transform"];
            if (removeFromSuperview) {
                [view removeFromSuperview];
            }
        }
        [CATransaction setCompletionBlock:^{
            if(callback){
                callback();
            }
        }];
        
        [CATransaction commit];
    }];
    
    if (view) {
        [view.layer addAnimation:hideAnimation() forKey:nil];
        view.layer.opacity = 0;
    }
    [CATransaction commit];
}

- (void)wait:(double)delayInSeconds then:(void(^)(void))callback {
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(delayTime, dispatch_get_main_queue(), ^(void){
        if(callback){
            callback();
        }
    });
    
    /*
     [self wait:<#(double)#> then:^{
     
     }];
     */
}

static CAAnimation* showAnimation()
{
    CAKeyframeAnimation *transform = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05, 1.05, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    transform.values = values;
    
    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [opacity setFromValue:@0.0];
    [opacity setToValue:@1.0];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = 0.2;
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [group setAnimations:@[transform, opacity]];
    return group;
}

static CAAnimation* hideAnimation()
{
    CAKeyframeAnimation *transform = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.00, 1.00, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05, 1.05, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1.0)]];
    transform.values = values;
    
    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [opacity setFromValue:@1.0];
    [opacity setToValue:@0.0];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = 0.2;
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [group setAnimations:@[transform, opacity]];
    return group;
}

- (void)checkVolume {
    float vol = [self getVolume];
    if (vol < .4) {
        [self showWarning:@"Your device volume may be too low!"];
    }
}

- (float)getVolume {
    float vol = [[AVAudioSession sharedInstance] outputVolume];
    return vol;
}

- (void)showWarning:(NSString*)text {
    if (!showingWarning) {
        showingWarning = YES;
        
        warningLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, sw, fontSize*3)];
        warningLabel.textAlignment = NSTextAlignmentCenter;
        warningLabel.font = [UIFont fontWithName:globalFont size:fontSize];
        warningLabel.textColor = [UIColor whiteColor];
        warningLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.75];
        warningLabel.center = self.view.center;
        warningLabel.text = text;
        
        [self.view addSubview:warningLabel];
        
        [self animateViewGrowAndShow:warningLabel];
        [self wait:2 then:^{
            [self cancelWarning];
        }];
    }
}

- (void)cancelWarning {
    if (showingWarning) {
        [self animateViewShrinkAndWink:warningLabel andRemoveFromSuperview:YES then:^{
            warningLabel = nil;
            showingWarning = NO;
        }];
    }
}

- (BOOL)iPadCheck {
    BOOL ipad = NO;
    if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
        ipad = YES;
    }
    return ipad;
}

- (BOOL)checkIfNumber:(NSString*)numberString {
    BOOL isNumber = NO;
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([numberString rangeOfCharacterFromSet:notDigits].location == NSNotFound) {
        isNumber = YES;
    }
    return isNumber;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end

