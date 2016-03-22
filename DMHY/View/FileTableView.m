//
//  FileTableView.m
//  DMHY
//
//  Created by 小笠原やきん on 3/27/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "FileTableView.h"
#import "AppDelegate.h"

@implementation FileTableView

- (void)keyDown:(NSEvent *)theEvent
{
    NSString *key = [theEvent charactersIgnoringModifiers];
    if ([key isEqual:@" "])
    {
        [[NSApp delegate] togglePreviewPanel:self];
    }
    else
    {
        [super keyDown:theEvent];
    }
}

@end
