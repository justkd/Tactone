//
//  kdTableView.m
//
//  Created by Cady Holmes on 1/2/18.
//  Copyright © 2018 Cady Holmes. All rights reserved.
//

#import "kdTableView.h"

@implementation kdTableView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)didMoveToSuperview {
    dummyKey = @"_____--..qwd9198j1ijd1j----@^&^@*&(---KDTABLEVIEWREORDERDUMMY--wdwdwq@#&^%*()(@)()(@!(*fff1fveqkk---__d11noi89j19klkmclkankn1i2o12____";
    delegateError = @"Remember to set the kdTableViewDelegate you louse.";
    
    if (!self.data) {
        self.data = [[NSMutableArray alloc] init];
    }
    if (!self.font) {
        self.font = @"HelveticaNeue-UltraLight";
    }
    if (!self.animDuration) {
        self.animDuration = .3;
    }
    if (!self.fontSize) {
        self.fontSize = 20;
    }
    if (!self.topMargin) {
        self.topMargin = 70;
    }
    if (!self.bottomMargin) {
        self.bottomMargin = 100;
    }
    if (!self.canReorder) {
        self.canReorder = NO;
    }
    if (!self.animate) {
        self.animate = NO;
    }
    if (!self.hasCloseButton) {
        self.hasCloseButton = NO;
    }
    if (!self.allowsEditing) {
        self.allowsEditing = NO;
    }
    if (!self.hasSeparators) {
        self.hasSeparators = NO;
    }
    
    if (!self.showType) {
        self.showType = kdModalShow_Pop;
    }
    
    if (!self.cellBorderSize) {
        self.cellBorderSize = 0;
    }
    
    if (!self.cellBorderColor) {
        self.cellBorderColor = [UIColor clearColor];
    }
    
    if (!self.cellBackgroundColor) {
        self.cellBackgroundColor = [UIColor clearColor];
    }
    
    self.backgroundColor = [UIColor whiteColor];
    
    if (self.hasCloseButton) {
        float closeSize = 50;
        float marginSize = 20;
        UILabel *close = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width-closeSize-marginSize, marginSize, closeSize, closeSize)];
        [close setFont:[UIFont fontWithName:self.font size:self.fontSize*1.5]];
        [close setUserInteractionEnabled:YES];
        [close setText:@"X"];
        [close setTextAlignment:NSTextAlignmentCenter];
        
        UITapGestureRecognizer *tapClose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeTable:)];
        [close addGestureRecognizer:tapClose];
        
        [self addSubview:close];
    }
    
    [self makeTableViewOnView:self];
    
    [self hide];
}

- (void)show {
    [tableView reloadData];
    isOpen = YES;
    if (self.showType == kdModalShow_Pop) {
        [self animateViewGrowAndShow:self];
    } else {
        [self slide:self amountX:0 amountY:0];
    }
}
- (void)hide {
    isOpen = NO;
    switch (self.showType) {
        case kdModalShow_Pop:
            [self animateViewShrinkAndWink:self andRemoveFromSuperview:NO];
            break;
        case kdModalShow_Slide_Up:
            [self slide:self amountX:0 amountY:self.frame.size.height];
            break;
        case kdModalShow_Slide_Down:
            [self slide:self amountX:0 amountY:-self.frame.size.height];
            break;
        case kdModalShow_Slide_Left:
            [self slide:self amountX:-self.bounds.size.width amountY:0];
            break;
        case kdModalShow_Slide_Right:
            [self slide:self amountX:self.frame.size.width amountY:0];
            break;
        default:
            break;
    }
}

- (void)makeTableViewOnView:(UIView*)view {
    tableView = [[kdSetupTableView alloc] init];
    tableView.frame = CGRectMake(self.bounds.origin.x,self.bounds.origin.y+self.topMargin,self.bounds.size.width-15,self.bounds.size.height-self.bottomMargin);
    
    tableView.canReorder = self.canReorder;
    if (self.hasSeparators) {
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    } else {
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [tableView reloadData];
    [view addSubview:tableView];
}

- (void)addData:(id)data forKey:(NSString*)key canEdit:(BOOL)canEdit {
    NSArray *array = @[key,data,[NSNumber numberWithBool:canEdit]];
    [self.data addObject:array];
    [tableView reloadData];
}
- (void)insertData:(id)data forKey:(NSString*)key atIndex:(int)index canEdit:(BOOL)canEdit {
    NSArray *array = @[key,data,[NSNumber numberWithBool:canEdit]];
    [self.data insertObject:array atIndex:index];
    [tableView reloadData];
}
- (void)replaceData:(id)data forKey:(NSString*)key atIndex:(int)index canEdit:(BOOL)canEdit {
    NSArray *array = @[key,data,[NSNumber numberWithBool:canEdit]];
    [self.data replaceObjectAtIndex:index withObject:array];
    [tableView reloadData];
}
- (void)deleteDataAtIndex:(int)index {
    [self.data removeObjectAtIndex:index];
    [tableView reloadData];
}
- (void)reloadData {
    [tableView reloadData];
}

- (id)saveObjectAndInsertBlankRowAtIndexPath:(NSIndexPath *)indexPath {
    id object = [self.data objectAtIndex:indexPath.row];
    [self.data replaceObjectAtIndex:indexPath.row withObject:dummyKey];
    return object;
}
- (void)moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    id object = [self.data objectAtIndex:fromIndexPath.row];
    
    [self.data removeObjectAtIndex:fromIndexPath.row];
    [self.data insertObject:object atIndex:toIndexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(kdTableView:movedRowFromIndex:toIndex:)]) {
        [self.delegate kdTableView:self movedRowFromIndex:(int)fromIndexPath.row toIndex:(int)toIndexPath.row];
    } else {
        NSLog(@"%@",delegateError);
    }
}
- (void)finishReorderingWithObject:(id)object atIndexPath:(NSIndexPath *)indexPath; {
    [self.data replaceObjectAtIndex:indexPath.row withObject:object];
    
    if ([self.delegate respondsToSelector:@selector(kdTableView:finishedMovingRowTo:)]) {
        [self.delegate kdTableView:self finishedMovingRowTo:(int)indexPath.row];
    } else {
        NSLog(@"%@",delegateError);
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.data.count;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier   forIndexPath:indexPath] ;
    
    // You will have to manually configure what the 'empty' row looks like in this
    // method. Your dummy object can be something entirely different. It doesn't
    // have to be a string.
    
    cell.textLabel.font = [UIFont fontWithName:self.font size:self.fontSize];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.contentView.layer setBorderColor:self.cellBorderColor.CGColor];
    [cell.contentView.layer setBorderWidth:self.cellBorderSize];
    cell.contentView.backgroundColor = self.cellBackgroundColor;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.tag = indexPath.row;
    
    if ([[self.data objectAtIndex:indexPath.row] isKindOfClass:[NSString class]] &&
        [[self.data objectAtIndex:indexPath.row] isEqualToString:dummyKey]) {
        cell.textLabel.text = @"";
        cell.contentView.backgroundColor = [UIColor clearColor];
    } else {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        cell.textLabel.text=[[self.data objectAtIndex:indexPath.row] objectAtIndex:0];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    int index = (int)indexPath.row;
//    id obj = [[self.data objectAtIndex:index] objectAtIndex:1];
//    NSString *key = [[self.data objectAtIndex:index] objectAtIndex:0];
    
    [self jiggle:[tableView cellForRowAtIndexPath:indexPath] amount:1.05];
    
    if ([self.delegate respondsToSelector:@selector(kdTableView:didSelectRowAtIndex:)]) {
        [self.delegate kdTableView:self didSelectRowAtIndex:(int)indexPath.row];
    } else {
        NSLog(@"%@",delegateError);
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL edit = NO;
    
    if (self.allowsEditing) {
        if ([[self.data objectAtIndex:indexPath.row] isKindOfClass:[NSString class]] &&
            [[self.data objectAtIndex:indexPath.row] isEqualToString:dummyKey]) {
            
        } else {
            edit = [[[self.data objectAtIndex:indexPath.row] objectAtIndex:2] boolValue];
        }
    }

    return edit;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){

        deleteIndex = indexPath;
        
        UIView *view = [self makeDialoguePopup];
        float sw = view.bounds.size.width;
        float sh = view.bounds.size.height;
        float buttonSize = sw / 2;
        [self animateViewGrowAndShow:view];

        UILabel *text = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, sw, buttonSize)];
        [text setFont:[UIFont fontWithName:self.font size:self.fontSize]];
        [text setText:@"Are you sure?"];
        [text setTextAlignment:NSTextAlignmentCenter];
        [text setCenter:CGPointMake(sw/2, sh/3)];

        float y = view.bounds.size.height/2;
        UILabel *yes = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, buttonSize, buttonSize)];
        [yes setFont:[UIFont fontWithName:self.font size:self.fontSize]];
        [yes setText:@"Yes"];
        [yes setTextAlignment:NSTextAlignmentCenter];
        [yes setCenter:CGPointMake(sw/3, y)];
        [yes setTag:1];
        [yes setUserInteractionEnabled:YES];

        UILabel *no = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, buttonSize, buttonSize)];
        [no setFont:[UIFont fontWithName:self.font size:self.fontSize]];
        [no setText:@"No"];
        [no setTextAlignment:NSTextAlignmentCenter];
        [no setCenter:CGPointMake(sw-(sw/3), y)];
        [no setTag:0];
        [no setUserInteractionEnabled:YES];

        UITapGestureRecognizer *tapYes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reallyDelete:)];
        UITapGestureRecognizer *tapNo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reallyDelete:)];

        [yes addGestureRecognizer:tapYes];
        [no addGestureRecognizer:tapNo];

        [view addSubview:text];
        [view addSubview:yes];
        [view addSubview:no];
        [self addSubview:view];
    }];
    //deleteAction.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"trashcan"]];

    UITableViewRowAction *renameAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Rename" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        [self openRenameDialogueWithTag:(int)indexPath.row];
    }];

    return @[deleteAction,renameAction];
}

- (void)reallyDelete:(UITapGestureRecognizer*)sender {
    [self jiggle:sender.view amount:1.05];
    if (sender.view.tag > 0) {
        [self.data removeObjectAtIndex:(int)deleteIndex.row];
        [tableView deleteRowsAtIndexPaths:@[deleteIndex] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadData];
        
        if ([self.delegate respondsToSelector:@selector(kdTableView:didDeleteDataAtIndex:)]) {
            [self.delegate kdTableView:self didDeleteDataAtIndex:(int)deleteIndex.row];
        } else {
            NSLog(@"%@",delegateError);
        }
        
        deleteIndex = nil;
    }
    [self animateViewShrinkAndWink:sender.view.superview andRemoveFromSuperview:YES];
}

- (UIView*)makeDialoguePopup {
    UIView *view = [[UIView alloc] initWithFrame:self.frame];
    [view setBackgroundColor:[UIColor whiteColor]];

    float closeSize = 50;
    float marginSize = 20;
    UILabel *close = [[UILabel alloc] initWithFrame:CGRectMake(view.bounds.size.width-closeSize-marginSize+7, marginSize, closeSize, closeSize)];
    [close setFont:[UIFont fontWithName:self.font size:self.fontSize*1.5]];
    [close setUserInteractionEnabled:YES];
    [close setText:@"X"];
    [close setTextAlignment:NSTextAlignmentCenter];
    
    [view addSubview:close];
    
    UITapGestureRecognizer *tapClose = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClose:)];
    [view addGestureRecognizer:tapClose];
    
    return view;
}

- (void)openRenameDialogueWithTag:(int)tag {
    UIView *view = [self makeDialoguePopup];
    float sw = view.bounds.size.width;
    float textFieldMargin = 50;
    float textFieldHeight = 100;
    UITextField *textfield = [[UITextField alloc] initWithFrame:CGRectMake(textFieldMargin, view.bounds.size.height/3, sw-textFieldMargin, textFieldHeight)];
    textfield.font = [UIFont fontWithName:self.font size:self.fontSize*1.25];
    textfield.autocorrectionType = UITextAutocorrectionTypeNo;
    textfield.keyboardType = UIKeyboardTypeDefault;
    textfield.returnKeyType = UIReturnKeyDone;
    textfield.clearButtonMode = UITextFieldViewModeWhileEditing;
    textfield.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textfield.delegate = self;
    textfield.borderStyle = UITextBorderStyleNone;
    textfield.tintColor = [UIColor blackColor];
    
    NSString *place = @"   Rename";
    textfield.placeholder = place;
    textfield.tag = tag;
    [view addSubview:textfield];
    
    [self animateViewGrowAndShow:view];
    [self addSubview:view];
    [textfield becomeFirstResponder];
}

- (void)openSaveDialogue {
    UIView *view = [self makeDialoguePopup];
    float sw = view.bounds.size.width;
    float textFieldMargin = 50;
    float textFieldHeight = 100;
    UITextField *textfield = [[UITextField alloc] initWithFrame:CGRectMake(textFieldMargin, view.bounds.size.height/3, sw-textFieldMargin, textFieldHeight)];
    textfield.font = [UIFont fontWithName:self.font size:self.fontSize*1.25];
    textfield.autocorrectionType = UITextAutocorrectionTypeNo;
    textfield.keyboardType = UIKeyboardTypeDefault;
    textfield.returnKeyType = UIReturnKeyDone;
    textfield.clearButtonMode = UITextFieldViewModeWhileEditing;
    textfield.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textfield.delegate = self;
    textfield.borderStyle = UITextBorderStyleNone;
    textfield.tintColor = [UIColor blackColor];
    
    NSString *place = @"   Save As";
    textfield.placeholder = place;
    textfield.tag = -1;
    [view addSubview:textfield];
    
    [self animateViewGrowAndShow:view];
    [self.superview addSubview:view];
    [textfield becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.tag < 0) {
        if ([self.delegate respondsToSelector:@selector(kdTableView:didSaveWithKey:)]) {
            [self.delegate kdTableView:self didSaveWithKey:textField.text];
        } else {
            NSLog(@"%@",delegateError);
        }
        [self animateViewShrinkAndWink:textField.superview andRemoveFromSuperview:YES];
    } else {
        NSString *str = textField.text;
        
        NSMutableArray *temp = [NSMutableArray arrayWithArray:[self.data objectAtIndex:textField.tag]];
        [temp replaceObjectAtIndex:0 withObject:str];
        
        [self.data replaceObjectAtIndex:textField.tag withObject:temp];
        
        if (tableView) {
            [tableView reloadData];
        }
        
        [self animateViewShrinkAndWink:textField.superview andRemoveFromSuperview:YES];
        
        if ([self.delegate respondsToSelector:@selector(kdTableView:didRenameDataAtIndex:)]) {
            [self.delegate kdTableView:self didRenameDataAtIndex:(int)textField.tag];
        } else {
            NSLog(@"%@",delegateError);
        }
    }

    return YES;
}

- (void)tapClose:(UITapGestureRecognizer *)sender {
    [self animateViewShrinkAndWink:sender.view andRemoveFromSuperview:YES];
}
- (void)closeTable:(UITapGestureRecognizer *)sender {
    [self animateViewShrinkAndWink:sender.view.superview andRemoveFromSuperview:NO];
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

- (void)slide:(UIView*)view amountX:(float)x amountY:(float)y {
    
    if (!x) {
        x = 0;
    }
    if (!y) {
        y = 0;
    }
    
    if (self.animate) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:self.animDuration
                                  delay:0.0f
                 usingSpringWithDamping:.7f
                  initialSpringVelocity:.2f
                                options:(UIViewAnimationOptionAllowUserInteraction |
                                         UIViewAnimationOptionCurveEaseInOut)
                             animations:^{
                                 view.transform = CGAffineTransformMakeTranslation(x, y);
                             }
                             completion:^(BOOL finished) {
                                 
                             }];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            view.transform = CGAffineTransformMakeTranslation(x, y);
        });
    }
}

- (void)animateViewGrowAndShow:(UIView*)view {
    if (self.animate) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{}];
        if (view) {
            [view.layer addAnimation:showAnimation() forKey:nil];
            view.layer.opacity = 1;
        }
        [CATransaction commit];
    } else {
        view.layer.transform = CATransform3DMakeScale(1, 1, 1.0);
        view.layer.opacity = 1;
    }
}

- (void)animateViewShrinkAndWink:(UIView*)view andRemoveFromSuperview:(BOOL)removeFromSuperview {
    if (self.animate) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            if (view) {
                [view.layer removeAnimationForKey:@"opacity"];
                [view.layer removeAnimationForKey:@"transform"];
                if (removeFromSuperview) {
                    [view removeFromSuperview];
                }
            }
        }];
        
        if (view) {
            [view.layer addAnimation:hideAnimation() forKey:nil];
            view.layer.opacity = 0;
        }
        [CATransaction commit];
    } else {
        view.layer.transform = CATransform3DMakeScale(0, 0, 1.0);
        view.layer.opacity = 0;
    }
}

//- (void)wait:(double)delayInSeconds then:(void(^)(void))callback {
//    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//    dispatch_after(delayTime, dispatch_get_main_queue(), ^(void){
//        if(callback){
//            callback();
//        }
//    });
//
//    /*
//     [self wait:<#(double)#> then:^{
//
//     }];
//     */
//}

static CAAnimation* showAnimation()
{
    CAKeyframeAnimation *transform = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05, 1.05, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    transform.values = values;
    
    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [opacity setFromValue:@0.3];
    [opacity setToValue:@1.0];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.duration = .2;
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

@end
