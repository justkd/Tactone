//
//  kdTableView.h
//
//  Created by Cady Holmes on 1/2/18.
//  Copyright © 2018 Cady Holmes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "kdSetupTableView.h"

typedef enum {
    kdModalShow_Pop,
    kdModalShow_Slide_Down,
    kdModalShow_Slide_Left,
    kdModalShow_Slide_Right,
    kdModalShow_Slide_Up
}kdModalShow;

@protocol kdTableViewDelegate;
@interface kdTableView : UIView <UITableViewDataSource, kdSetupTableViewDelegate, UITextFieldDelegate> {
    kdSetupTableView *tableView;
    
    NSString *dummyKey;
    NSString *delegateError;
    
    NSIndexPath *deleteIndex;
    BOOL isOpen;
}

@property (nonatomic, assign) id <kdTableViewDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *data;
@property (nonatomic, strong) NSString *font;

@property (nonatomic) float fontSize;
@property (nonatomic) float animDuration;
@property (nonatomic) float topMargin;
@property (nonatomic) float bottomMargin;

@property (nonatomic, strong) UIColor *cellBorderColor;
@property (nonatomic, strong) UIColor *cellBackgroundColor;
@property (nonatomic) float cellBorderSize;

@property (nonatomic) BOOL hasSeparators;
@property (nonatomic) BOOL canReorder;
@property (nonatomic) BOOL animate;
@property (nonatomic) BOOL hasCloseButton;
@property (nonatomic) BOOL allowsEditing;

@property (nonatomic) kdModalShow showType;

- (void)addData:(id)data forKey:(NSString*)key canEdit:(BOOL)canEdit;
- (void)insertData:(id)data forKey:(NSString*)key atIndex:(int)index canEdit:(BOOL)canEdit;
- (void)replaceData:(id)data forKey:(NSString*)key atIndex:(int)index canEdit:(BOOL)canEdit;
- (void)deleteDataAtIndex:(int)index;
- (void)reloadData;

- (void)openSaveDialogue;
- (void)show;
- (void)hide;

@end

@protocol kdTableViewDelegate <NSObject>
-(void)kdTableView:(kdTableView*)tableView didSaveWithKey:(NSString*)key;
-(void)kdTableView:(kdTableView*)tableView didSelectRowAtIndex:(int)index;
-(void)kdTableView:(kdTableView*)tableView movedRowFromIndex:(int)fromIndex toIndex:(int)toIndex;
-(void)kdTableView:(kdTableView*)tableView finishedMovingRowTo:(int)index;
-(void)kdTableView:(kdTableView*)tableView didDeleteDataAtIndex:(int)index;
-(void)kdTableView:(kdTableView*)tableView didRenameDataAtIndex:(int)index;
@end





