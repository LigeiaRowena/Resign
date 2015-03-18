

#import "NSTextField+MultiLine.h"

@implementation NSTextField (MultiLine)

- (void)appendStringValue:(NSString*)string
{
    NSString *newValue = [self.stringValue stringByAppendingFormat:@"\n%@", string];
    [self setStringValue:newValue];
}

@end
