//
//  FileItem.h
//  DMHY
//
//  Created by 小笠原やきん on 3/26/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileItem : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSDate *modifyDate;

- (instancetype )initWithURL:(NSURL *)url fileName:(NSString *)name modifyDate:(NSDate *)date;

@end
