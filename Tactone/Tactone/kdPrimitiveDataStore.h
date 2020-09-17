//
//  kdPrimitiveDataStore.h
//
//  Created by Cady Holmes on 1/2/18.
//  Copyright © 2018 Cady Holmes. All rights reserved.
//

#import <Foundation/Foundation.h>

//@protocol kdPrimitiveDataStoreDelegate;
@interface kdPrimitiveDataStore : NSObject {
    NSString *path;
}

@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSArray *data;

- (id)initWithFile:(NSString*)file;
- (void)save:(NSArray*)newData;
- (void)load;

@end

//@protocol kdPrimitiveDataStoreDelegate <NSObject>
//
//@end

