#import "iPhoneBookApplication.h"

@implementation iPhoneBookApplication

- (int) numberOfRowsInTable: (UITable*)table
{
	return [_pbCells count];
}

- (UITableCell*) table:(UITable*)table cellForRow:(int)row column:(int)column
{
	return [_pbCells objectAtIndex: row];
}

#define NAV_BAR_HEIGHT 45.0f

- (void) applicationDidFinishLaunching: (id)unknown
{
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];

	_window = [[UIWindow alloc] initWithContentRect: rect];
	[_window orderFront: self];
	[_window makeKey: self];
	[_window _setHidden: NO];

	rect.origin.x = rect.origin.y = 0;

	UIView *mainView = [[UIView alloc] initWithFrame: rect];

	UINavigationBar *navBar = [[UINavigationBar alloc] init];
	[navBar setFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, NAV_BAR_HEIGHT)];
	[navBar showLeftButton:@"Call" withStyle:0 rightButton:@"Import All" withStyle:0];
	[mainView addSubview: navBar];

	rect.origin.y = rect.origin.y + NAV_BAR_HEIGHT;
	rect.size.height = rect.size.height - NAV_BAR_HEIGHT;

	UITable *pbTable = [[UITable alloc] initWithFrame: rect];
	UITableColumn *pbColumn = [[UITableColumn alloc] initWithTitle: @"PhoneBook" identifier: @"iPhoneBook" width: rect.size.width];
	[pbTable addTableColumn: pbColumn];
	[pbTable setDataSource: self];
	[pbTable setDelegate: self];
	[pbTable setResusesTableCells: FALSE];
	[mainView addSubview: pbTable];

	[_window setContentView: mainView];

	_pbCells = [[NSMutableArray alloc] init];

	UIImageAndTextTableCell *cell = [[UIImageAndTextTableCell alloc] init];
	[cell setTitle: @"Test Cell 1"];
	[cell setShowDisclosure: YES];
	[_pbCells addObject: cell];
	[cell release];

	rect = [UIHardware fullScreenApplicationContentRect];

	cell = [[UIImageAndTextTableCell alloc] init];
	[cell setTitle: [NSString stringWithFormat: @"x: %f y: %f", rect.origin.x, rect.origin.y]];
	[_pbCells addObject: cell];
	[cell release];

	cell = [[UIImageAndTextTableCell alloc] init];
	[cell setTitle: [NSString stringWithFormat: @"w:%f h:%f", rect.size.width, rect.size.height]];
	[_pbCells addObject: cell];
	[cell release];

	[pbTable reloadData];
}

@end
