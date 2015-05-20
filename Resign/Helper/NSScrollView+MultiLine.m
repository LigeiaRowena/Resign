

#import "NSScrollView+MultiLine.h"

@implementation NSScrollView (MultiLine)

- (void)appendStringValue:(NSString*)string
{
    NSTextView *textfield = (NSTextView*)self.documentView;
    NSString *newValue = [textfield.textStorage.mutableString stringByAppendingFormat:@"\n%@", string];
    [textfield setString:newValue];
    
    // scrolls to the bottom
    NSPoint bottom = NSMakePoint(0.0, NSMaxY([[self documentView] frame]) - NSHeight([[self contentView] bounds]));
    [[self documentView] scrollPoint:bottom];
}

- (void)setStringValue:(NSString*)string
{
    NSTextView *textfield = (NSTextView*)self.documentView;
    [textfield setString:string];
    
    // scrolls to the bottom
    NSPoint bottom = NSMakePoint(0.0, NSMaxY([[self documentView] frame]) - NSHeight([[self contentView] bounds]));
    [[self documentView] scrollPoint:bottom];
}


@end
