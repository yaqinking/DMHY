//
//  FileItem.m
//  DMHY
//
//  Created by 小笠原やきん on 3/26/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "FileItem.h"

@implementation FileItem

- (instancetype)initWithURL:(NSURL *)url fileName:(NSString *)name modifyDate:(NSDate *)date {
    self = [super init];
    if (self) {
        _url = url;
        _fileName = name;
        _modifyDate = date;
    }
    return self;
}

@end
