#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>

@interface iPhoneBookApplication : UIApplication {
	UIWindow *_window;
	UIView *_mainView;
	UITable *_pbTable;
	NSMutableArray *_pbCells;
	UIAlertSheet *errorInfoSheet;
}

- (void) AddRow: (NSString *)title;
- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int)button;

@end
