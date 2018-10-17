/*
 Copyright 2018 Vector Creations Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ContactsViewController.h"

#import "RiotDesignValues.h"
#import "RageShakeManager.h"
#import "Analytics.h"
#import "ContactTableViewCell.h"
#import "ContactsDataSource.h"

#import "GeneratedInterface-Swift.h"

@interface ContactsViewController () <UITableViewDelegate, MXKDataSourceDelegate, Stylable, UISearchResultsUpdating>

/**
 The contacts table view.
 */
@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;

@property (strong, nonatomic) ContactsDataSource *contactsDataSource;
@property (nonatomic, strong) id<Style> currentStyle;

@property (nonatomic) BOOL showSearchBar;
@property (nonatomic, strong) UISearchController *searchController;

/**
 If YES, the table view will scroll at the top on the next data source refresh.
 It comes back to NO after each refresh.
 */
@property (nonatomic) BOOL shouldScrollToTopOnRefresh;

/**
 The analytics instance screen name (Default is "ContactsTable").
 */
@property (nonatomic) NSString *screenName;

/**
 Refresh the contacts table display.
 */
- (void)refreshContactsTable;

@end

@implementation ContactsViewController

#pragma mark - Setup

+ (instancetype)instantiateWithStyle:(id<Style>)style
{
    return [self instantiateWithStyle:style showSearchBar:NO];
}

+ (instancetype)instantiateWithStyle:(id<Style>)style showSearchBar:(BOOL)showSearchBar
{
    ContactsViewController *viewController = [[UIStoryboard storyboardWithName:NSStringFromClass([ContactsViewController class]) bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    viewController.showSearchBar = showSearchBar;
    [viewController updateWithStyle:style];
    return viewController;
}

- (void)finalizeInit
{
    [super finalizeInit];

    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];

    _screenName = @"ContactsTable";
}

#pragma mark - Life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Finalize table view configuration
    self.contactsTableView.delegate = self;
    self.contactsTableView.dataSource = self.contactsDataSource; // Note: dataSource may be nil here
    
    [self.contactsTableView registerClass:ContactTableViewCell.class forCellReuseIdentifier:ContactTableViewCell.defaultReuseIdentifier];
    
    // Hide line separators of empty cells
    self.contactsTableView.tableFooterView = [[UIView alloc] init];
    
    if (self.showSearchBar)
    {
        [self setupSearchController];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.currentStyle.statusBarStyle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:_screenName];

    // Check whether the access to the local contacts has not been already asked.
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        // Allow by default the local contacts sync in order to discover matrix users.
        // This setting change will trigger the loading of the local contacts, which will automatically
        // ask user permission to access their local contacts.
        [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
    }
    
    [self updateWithStyle:self.currentStyle];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (@available(iOS 11.0, *))
    {
        // Enable to hide search bar on scrolling after first time view appear
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.searchController.searchBar resignFirstResponder];
}

#pragma mark - Public

- (void)displayList:(ContactsDataSource*)listDataSource
{
    // Cancel registration on existing dataSource if any
    if (self.contactsDataSource)
    {
        self.contactsDataSource.delegate = nil;
    }
    
    self.contactsDataSource = listDataSource;
    self.contactsDataSource.delegate = self;
    
    if (self.contactsTableView)
    {
        // Set up table data source
        self.contactsTableView.dataSource = self.contactsDataSource;
    }
}

#pragma mark - Private

- (void)refreshContactsTable
{
    [self.contactsTableView reloadData];
    
    if (_shouldScrollToTopOnRefresh)
    {
        [self scrollToTop:NO];
        _shouldScrollToTopOnRefresh = NO;
    }
}

- (void)scrollToTop:(BOOL)animated
{
    // Scroll to the top
    [self.contactsTableView setContentOffset:CGPointMake(-self.contactsTableView.mxk_adjustedContentInset.left, -self.contactsTableView.mxk_adjustedContentInset.top) animated:animated];
}

- (void)setupSearchController
{
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.dimsBackgroundDuringPresentation = NO;
    searchController.searchResultsUpdater = self;
    searchController.searchBar.placeholder = NSLocalizedStringFromTable(@"contacts_search_bar_placeholder", @"Tchap", nil);
    searchController.hidesNavigationBarDuringPresentation = NO;
    
    if (@available(iOS 11.0, *))
    {
        self.navigationItem.searchController = searchController;
        // Make the search bar visible on first view appearance
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
    }
    else
    {
        self.contactsTableView.tableHeaderView = searchController.searchBar;
    }
    
    self.definesPresentationContext = YES;
    
    self.searchController = searchController;
}

#pragma mark - Stylable

- (void)updateWithStyle:(id<Style>)style
{
    self.currentStyle = style;
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    if (navigationBar)
    {
        [style applyStyleOnNavigationBar:navigationBar];
    }
    
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    self.contactsTableView.backgroundColor = style.backgroundColor;
    self.view.backgroundColor = style.backgroundColor;
    
    UISearchBar *searchBar = self.searchController.searchBar;
    
    if (searchBar)
    {
        if (@available(iOS 11.0, *))
        {
            searchBar.tintColor = style.barActionColor;
        }
        else
        {
            searchBar.tintColor = style.primarySubTextColor;
        }
    }
    
    if (self.contactsTableView.dataSource)
    {
        [self refreshContactsTable];
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:MXKContact.class])
    {
        return ContactTableViewCell.class;
    }
    
    return nil;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:MXKContact.class])
    {
        return [ContactTableViewCell defaultReuseIdentifier];
    }
    
    return nil;
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    [self refreshContactsTable];
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = self.currentStyle.backgroundColor;
    
    if (!cell.selectedBackgroundView)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    cell.selectedBackgroundView.backgroundColor = self.currentStyle.secondaryBackgroundColor;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self.contactsDataSource heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self.contactsDataSource viewForHeaderInSection:section withFrame:[tableView rectForHeaderInSection:section]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.contactsDataSource contactAtIndexPath:indexPath])
    {
        // Return the default height of the contact cell
        return 74.0;
    }
    
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXKContact *mxkContact = [self.contactsDataSource contactAtIndexPath:indexPath];
    
    if (self.delegate && mxkContact)
    {
        [self.delegate contactsViewController:self didSelectContact:mxkContact];
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchText = searchController.searchBar.text;
    [self.contactsDataSource searchWithPattern:searchText forceReset:NO];
}

@end
