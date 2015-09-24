//
//  SideViewController.m
//  DMHY
//
//  Created by 小笠原やきん on 9/19/15.
//  Copyright © 2015 yaqinking. All rights reserved.
//

#import "SideViewController.h"
#import "DMHYKeyword+CoreDataProperties.h"
#import "DMHYCoreDataStackManager.h"
#import "DMHYAPI.h"

@interface SideViewController ()

@property (weak) IBOutlet NSTextField   *keywordTextField;
@property (weak) IBOutlet NSPopUpButton *parentKeywordsPopUpButton;
@property (weak) IBOutlet NSOutlineView *outlineView;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong  ) NSMutableArray         *keywords;

@end

@implementation SideViewController

@synthesize managedObjectContext = _context;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self observeNotification];
    [self setupPopupButtonData];
    [self expandOutlineViewItem];
}

- (void)expandOutlineViewItem {
    for (int i = 0 ; i < self.keywords.count; i++) {
        [self.outlineView expandItem:self.keywords[i]];
    }
}

#pragma mark - IBAction

- (IBAction)addKeyword:(id)sender {
    NSMenuItem *selectedItem = [self.parentKeywordsPopUpButton selectedItem];
    NSInteger selectedKeywordIndex = [self.parentKeywordsPopUpButton indexOfItem:selectedItem];
    
    DMHYKeyword *parentKeyword = self.keywords[selectedKeywordIndex];
//    NSLog(@"parentkeyword %@",parentKeyword.keyword);
    DMHYKeyword *subKeyword = [NSEntityDescription insertNewObjectForEntityForName:DMHYKeywordEntityKey
                                                            inManagedObjectContext:self.managedObjectContext];
    subKeyword.keyword = self.keywordTextField.stringValue;
    subKeyword.createDate = [NSDate new];
    subKeyword.isSubKeyword = [NSNumber numberWithBool:YES];
    [parentKeyword addSubKeywordsObject:subKeyword];
    [self saveData];
    [self reloadData];
}

#pragma mark - Setup Data

- (void)setupPopupButtonData {
//    NSLog(@"keywords count %lu",self.keywords.count);
    NSMutableArray *keywordsName = [[NSMutableArray alloc] init];
    for (DMHYKeyword *weekday in self.keywords) {
        [keywordsName addObject:weekday.keyword];
    }
    [self.parentKeywordsPopUpButton addItemsWithTitles:keywordsName];
//    NSLog(@"popupButtonData end");
}


#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(DMHYKeyword *) item {
    return !item ? [self.keywords count] : [item.subKeywords count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(DMHYKeyword *)item {
    return !item ? YES : [item.subKeywords count] != 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(DMHYKeyword *)item {
//    NSLog(@"item -> keyword %@",item.keyword);
    NSArray *subKeywords = [item.subKeywords allObjects];
//    NSLog(@"%@",subKeywords);
    return !item ? self.keywords[index] : subKeywords[index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    DMHYKeyword *weekday = item;
    NSString *identifier = tableColumn.identifier;
    if ([identifier isEqualToString:@"Keyword"]) {
        return weekday.keyword;
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    DMHYKeyword *keyword = item;
    NSString *identifier = tableColumn.identifier;
    if ([identifier isEqualToString:@"Keyword"]) {
        keyword.keyword = object;
        [self saveData];
    }
}

#pragma mark - NSOutlineViewDelegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    DMHYKeyword *selectedKeyword = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    NSString *keyword = selectedKeyword.keyword;
    NSNumber *isSubKeyword = selectedKeyword.isSubKeyword;
    NSDictionary *userInfo = @{kSelectKeyword             : keyword,
                               kSelectKeywordIsSubKeyword : isSubKeyword};
    [notificationCenter postNotificationName:DMHYSelectKeywordChangedNotification
                                      object:self
                                    userInfo:userInfo];
    
//    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
//    NSMenuItem *fileMenuItem = [mainMenu itemWithTitle:@"File"];
//    NSMenuItem *removeSubKeywordMenuItem = [[fileMenuItem submenu] itemWithTitle:@"删除关键字"];
//    removeSubKeywordMenuItem.enabled = NO;
//    NSLog(@"删除关键 MenuItem Title %@",[removeSubKeywordMenuItem title]);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    return YES;
}

#pragma mark - Notification

- (void)observeNotification {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleInitialWeekdayComplete:)
                               name:DMHYInitialWeekdayCompleteNotification
                             object:nil];
}

- (void)handleInitialWeekdayComplete:(NSNotification *)noti {
    self.keywords = nil;
    NSLog(@"InitialWeekdayCompleteNotification");
    [self setupPopupButtonData];
    [self reloadData];
    
}

#pragma mark - Properties

- (NSMutableArray *)keywords {

    if (!_keywords) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:DMHYKeywordEntityKey];
        NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"createDate" ascending:YES];
        request.sortDescriptors = @[sortDesc];
        request.predicate = [NSPredicate predicateWithFormat:@"isSubKeyword != YES"];
        _keywords = [[self.managedObjectContext executeFetchRequest:request
                                                              error:NULL] mutableCopy];
    }
    return _keywords;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_context) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _context.persistentStoreCoordinator = [[DMHYCoreDataStackManager sharedManager] persistentStoreCoordinator];
    }
    return _context;
}

#pragma mark - Utils

- (void)saveData {
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error %@",[error localizedDescription]);
    }
}

- (void)reloadData {
    [self.outlineView reloadData];
}
@end
