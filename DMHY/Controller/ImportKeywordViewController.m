//
//  ImportKeywordViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 7/18/16.
//  Copyright © 2016 yaqinking. All rights reserved.
//

#import "ImportKeywordViewController.h"
#import "DMHYCoreDataStackManager.h"

@interface ImportKeywordViewController ()

@property (unsafe_unretained) IBOutlet NSTextView *jsonTextView;
@property (weak) IBOutlet NSTextField *infoTextField;


@end

@implementation ImportKeywordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = NSMakeSize(617, 489);
}

- (IBAction)import:(id)sender {
    NSString *text = self.jsonTextView.textStorage.string;
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        [NSApp presentError:error];
        return;
    }
    NSArray<NSDictionary *> *sites = json[@"sites"];
    [[DMHYCoreDataStackManager sharedManager] importFromSites:sites success:^{
        [[DMHYCoreDataStackManager sharedManager] saveContext];
        self.infoTextField.stringValue = @"导入完毕";
    } failure:^(NSError *error) {
        self.infoTextField.stringValue = @"导入失败";
    }];
}

@end
