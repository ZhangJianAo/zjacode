#import "iPhoneBookApplication.h"
#import "sim_phonebook.h"
#import <UIKit/UIProgressHUD.h>

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

- (void) AddRow: (NSString*)title
{
	UIImageAndTextTableCell *cell = [[UIImageAndTextTableCell alloc] init];
	[cell setTitle: title];
	[_pbCells addObject: cell];
	[cell release];
}

char GetChar(char *p)
{
	switch(*p) {
	case '0': return 0;
	case '1': return 1;
	case '2': return 2;
	case '3': return 3;
	case '4': return 4;
	case '5': return 5;
	case '6': return 6;
	case '7': return 7;
	case '8': return 8;
	case '9': return 9;
	case 'A': return 10;
	case 'B': return 11;
	case 'C': return 12;
	case 'D': return 13;
	case 'E': return 14;
	case 'F': return 15;
	}

	return 0;
}

char GetHexChar(char *p)
{
	char h = GetChar(p);
	char l = GetChar(p+1);

	return (h<<4 | l);
}

- (NSString *) Ucs2String: (char *)str
{
	char buf[255];
	char *p = str;
	int len = 0;

	buf[0] = 0xFE; buf[1] = 0xFF;
	len = 2;

	while('\0' != *p) {
		buf[len] = GetHexChar(p);
		p += 2;
		len += 1;
	}

	NSData *dat = [NSData dataWithBytesNoCopy: buf length:len];
	
	return [[NSString alloc] initWithData: dat encoding:NSUnicodeStringEncoding];
}

- (void) applicationDidFinishLaunching: (id)unknown
{
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];

	_window = [[UIWindow alloc] initWithContentRect: rect];
	[_window orderFront: self];
	[_window makeKey: self];
	[_window _setHidden: NO];

	rect.origin.x = rect.origin.y = 0;

	_mainView = [[UIView alloc] initWithFrame: rect];

	UINavigationBar *navBar = [[UINavigationBar alloc] init];
	[navBar setFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, NAV_BAR_HEIGHT)];
	[navBar showLeftButton:@"Call" withStyle:0 rightButton:@"Import All" withStyle:0];
	[navBar setDelegate: self];
	[_mainView addSubview: navBar];

	rect.origin.y = rect.origin.y + NAV_BAR_HEIGHT;
	rect.size.height = rect.size.height - NAV_BAR_HEIGHT;

	errorInfoSheet = [[UIAlertSheet alloc] initWithFrame: CGRectMake(0, 240, 320, 240)];
	[errorInfoSheet setTitle:@"Error"];
	[errorInfoSheet setBodyText:@"Hello World!"];
	[errorInfoSheet addButtonWithTitle:@"OK" ];
	[errorInfoSheet setDelegate: self ];

	_pbTable = [[UITable alloc] initWithFrame: rect];
	UITableColumn *pbColumn = [[UITableColumn alloc] initWithTitle: @"PhoneBook" identifier: @"iPhoneBook" width: rect.size.width];
	[_pbTable addTableColumn: pbColumn];
	[_pbTable setDataSource: self];
	[_pbTable setDelegate: self];
	[_pbTable setResusesTableCells: FALSE];
	[_mainView addSubview: _pbTable];

	[_window setContentView: _mainView];

	_pbCells = [[NSMutableArray alloc] init];

	UIImageAndTextTableCell *cell = [[UIImageAndTextTableCell alloc] init];
	[cell setTitle: @"Test Cell 1"];
	[cell setShowDisclosure: YES];
	[_pbCells addObject: cell];
	[cell release];

	UIProgressHUD *hud = [[UIProgressHUD alloc] initWithWindow: _window];
	[hud show: true];

	//[self AddRow: [self Ucs2String: "707573AF4E3D0041004300430054"]];

	sim_phonebook *spb = sim_read_pb();

	if (NULL != spb) {
		[self AddRow: [NSString stringWithFormat: @"count: %d", spb->count]];

		int i = 0;
		for(i = 0; i < spb->count; i++) {
			[self AddRow: [NSString stringWithFormat: @"%s: %@", spb->numbers[i], [self Ucs2String: spb->names[i]]]];
		}
	} else {
		[errorInfoSheet setBodyText: [NSString stringWithUTF8String: sim_get_lasterror()]];
		[errorInfoSheet presentSheetInView: _mainView ];
		[self AddRow: [NSString stringWithUTF8String: sim_get_lasterror()]];
	}

	[_pbTable reloadData];

}

- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int)button;
{
	[sheet dismiss];
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
	if (1 == button) {
		[errorInfoSheet setBodyText: @"Call This Phone!"];
		[errorInfoSheet presentSheetInView: _mainView ];
	}
}

- (void)tableRowSelected:(NSNotification*)notification
{
}

@end
