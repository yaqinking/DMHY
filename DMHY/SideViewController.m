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
    [self setupMenuItems];
}

- (void)expandOutlineViewItem {
    for (int i = 0 ; i < self.keywords.count; i++) {
        [self.outlineView expandItem:self.keywords[i]];
    }
}

#pragma mark - IBAction

- (IBAction)addKeyword:(id)sender {
    NSString *newKeyword = self.keywordTextField.stringValue;
    if ([newKeyword isEqualToString:@""]) {
        return;
    }
    NSMenuItem *selectedItem = [self.parentKeywordsPopUpButton selectedItem];
    NSInteger selectedKeywordIndex = [self.parentKeywordsPopUpButton indexOfItem:selectedItem];
    
    DMHYKeyword *parentKeyword = self.keywords[selectedKeywordIndex];
//    NSLog(@"parentkeyword %@",parentKeyword.keyword);
    DMHYKeyword *subKeyword = [NSEntityDescription insertNewObjectForEntityForName:DMHYKeywordEntityKey
                                                            inManagedObjectContext:self.managedObjectContext];
    
    subKeyword.keyword = newKeyword;
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

- (void)setupMenuItems {
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *editMenuItem = [mainMenu itemWithTitle:@"Edit"];
    NSMenu *editSubMenu = [editMenuItem submenu];
    unichar deleteKey = NSBackspaceCharacter;
    NSString *delete = [NSString stringWithCharacters:&deleteKey length:1];
    NSMenuItem *removeSubKeywordMenuItem = [[NSMenuItem alloc] initWithTitle:@"删除关键字"
                                                                      action:@selector(deleteSubKeyword)
                                                               keyEquivalent:delete];
    
    [editSubMenu addItem:removeSubKeywordMenuItem];
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
    NSString *newKeyword = object;
    
    if (!keyword.isSubKeyword.boolValue || [newKeyword isEqualToString:@""]) {
        return;
    }
    
    NSString *identifier = tableColumn.identifier;
    if ([identifier isEqualToString:@"Keyword"]) {
        keyword.keyword = newKeyword;
        [self saveData];
    }
}

#pragma mark - NSOutlineViewDelegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    DMHYKeyword *selectedKeyword = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
    NSString *keyword = selectedKeyword.keyword;
    if (!selectedKeyword.isSubKeyword.boolValue || keyword.length == 0) {
        return;
    }
    NSNumber *isSubKeyword = selectedKeyword.isSubKeyword;
    NSDictionary *userInfo = @{kSelectKeyword             : keyword,
                               kSelectKeywordIsSubKeyword : isSubKeyword};
    
    [DMHYNotification postNotificationName:DMHYSelectKeywordChangedNotification userInfo:userInfo];
    
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return ((DMHYKeyword *)item).isSubKeyword.boolValue ? YES : NO;
}

#pragma mark - Notification

- (void)observeNotification {
    [DMHYNotification addObserver:self selector:@selector(handleInitialWeekdayComplete) name:DMHYInitialWeekdayCompleteNotification];
    [DMHYNotification addObserver:self selector:@selector(handleThemeChanged) name:DMHYThemeChangedNotification];
    [DMHYNotification addObserver:self selector:@selector(handleSeasonKeywordAdded) name:DMHYSearsonKeywordAddedNotification];
    
}

- (void)handleSeasonKeywordAdded {
    NSLog(@"handleSeasonKeywordAdded");
    self.keywords = nil;
    [self reloadData];
}

- (void)handleInitialWeekdayComplete {
    self.keywords = nil;
    [self setupPopupButtonData];
    [self reloadData];
    
}

- (void)handleThemeChanged {
    [self.view setNeedsDisplay:YES];
}

#pragma mark - MenuItem

- (void)deleteSubKeyword {
    NSInteger selectKeywordIndex = [self.outlineView selectedRow];
    DMHYKeyword *keyword = [self.outlineView itemAtRow:selectKeywordIndex];
    if ([keyword.isSubKeyword boolValue]) {
        DMHYKeyword *parentKeyword = [self.outlineView parentForItem:keyword];
        [parentKeyword removeSubKeywordsObject:keyword];
        [self.managedObjectContext deleteObject:keyword];
        [self saveData];
        [self reloadData];
        [DMHYNotification postNotificationName:DMHYDatabaseChangedNotification];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    NSString *title = [menuItem title];
    if ([title isEqualToString:@"删除关键字"]) {
        //什么都没选的时候
        if (self.outlineView.selectedRow == -1) {
            return NO;
        }
        DMHYKeyword *keyword = [self.outlineView itemAtRow:[self.outlineView selectedRow]];
        //记得使用 boolValue 获取 BOOL 值 >_<
        if (![keyword.isSubKeyword boolValue]) {
            return NO;
        }
    }
    return YES;
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
        _context.undoManager = nil;
    }
    return _context;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidEndEditing:(NSNotification *)notification {
    if ([notification.userInfo[@"NSTextMovement"] intValue] == NSReturnTextMovement) {
        [self addKeyword:nil];
    }
}

#pragma mark - Utils

- (void)saveData {
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges]) {
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Side View Controller Error %@",[error localizedDescription]);
        }
    }
}

- (void)reloadData {
    [self.outlineView reloadData];
}
@end
