// 
// Copyright (c) 2011 FadingRed LLC
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// 

#import <Foundation/Foundation.h>

#import "FRSingleton.h"
#import "test_macros.h"

@interface FRSingletonAuto : NSObject <FRSingleton>
@end
@implementation FRSingletonAuto
+ (id)sharedInstance { return obj_autorelease([self alloc]); }
@end

// directly from apple's recommendation
@interface FRSingletonManual : NSObject
@end
@implementation FRSingletonManual
static FRSingletonManual *sharedInstance = nil;
+ (id)sharedInstance {
	if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
	return sharedInstance;
}
+ (id)allocWithZone:(NSZone *)zone {
    return obj_retain([self sharedInstance]);
}
@end


int main() {
	AUTORELEASE_BEGIN;
	
	// allocation speed
	// --------------------------------------------------------------------------------
	void (^go)(Class class, unsigned int count) = nil;
	go = ^void(Class class, unsigned int count) {
		NSDate *date = [NSDate date];
		for (NSUInteger i = 0; i < count; i++) {
			obj_release([class alloc]);
		}
		fprintf(stderr, "Averaged %f miliseconds for %u calls to %s.\n",
			(float)(-[date timeIntervalSinceNow] * 1000), count, [[class description] UTF8String]);
	};
	
	unsigned int count = 100000;
	go([FRSingletonAuto class], count);
	go([FRSingletonManual class], count);
	
	AUTORELEASE_END;
	return 0;
}
