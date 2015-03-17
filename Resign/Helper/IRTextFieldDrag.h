//
//  IRTextFieldDrag.h
//  iReSign
//
//  Created by Esteban Bouza on 01/12/12.
//

#import <Cocoa/Cocoa.h>
@class IRTextFieldDrag;

@protocol IRTextFieldDragDelegate <NSObject>
@optional
- (void)performDragOperation:(NSString*)text;
- (void)draggingEntered:(IRTextFieldDrag*)textField;
@end

@interface IRTextFieldDrag : NSTextField

@property (nonatomic, weak) IBOutlet id <IRTextFieldDragDelegate> dragDelegate;


@end
