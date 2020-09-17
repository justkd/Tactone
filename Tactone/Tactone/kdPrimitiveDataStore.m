//
//  kdPrimitiveDataStore.m
//
//  Created by Cady Holmes on 1/2/18.
//  Copyright © 2018 Cady Holmes. All rights reserved.
//

#import "kdPrimitiveDataStore.h"

@implementation kdPrimitiveDataStore

- (id)initWithFile:(NSString*)file {
    self = [super init];
    if (self) {
        self.fileName = file;
        
        NSString *filepath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        filepath = [filepath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",self.fileName]];
        path = filepath;
        //NSLog(@"%@",path);
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) {
            self.data = [[NSArray alloc] initWithContentsOfFile:path];
        }
    }
    return self;
}

- (void)save:(NSArray*)newData {
    self.data = [NSArray arrayWithArray:newData];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:nil];
    }
    
    [fileManager createFileAtPath:path
                         contents:nil
                       attributes:nil];
    
    [self.data writeToFile:path atomically:YES];
}

- (void)load {

    NSArray *array = @[];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        array = [[NSArray alloc] initWithContentsOfFile:path];
    } else {
        NSLog(@"File not found");
    }
    
    self.data = [NSArray arrayWithArray:array];
}

@end
