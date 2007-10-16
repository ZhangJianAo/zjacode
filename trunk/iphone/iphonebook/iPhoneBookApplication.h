#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>

@interface iPhoneBookApplication : UIApplication {
	UIWindow *_window;
	NSMutableArray *_pbCells;
}

- (void) AddRow: (NSString *)title;

@end
