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

int main() {
	AUTORELEASE_BEGIN;

	// allocation speed
	// --------------------------------------------------------------------------------
	void (^go)(Class class, SEL through, unsigned int count) = nil;
	go = ^void(Class class, SEL through, unsigned int count) {
		NSDate *date = [NSDate date];
		for (NSUInteger i = 0; i < count; i++) {
			id object = [class alloc];
			if (through == @selector(alloc)) { continue; }
			object = [object init];
			if (through == @selector(init)) { continue; }
			obj_release(object);
			object = nil;
		}
		fprintf(stderr, "Averaged %f miliseconds for %u allocations through %s %s.\n",
			(float)(-[date timeIntervalSinceNow] * 1000), count, [NSStringFromSelector(through) UTF8String],
			[NSObject respondsToSelector:@selector(hasSingletonProtocol)] ? "with singleton support" : "normally");
	};

	unsigned int count = 100000;
	go([NSMutableDictionary class], @selector(self), count);
	go([NSMutableDictionary class], @selector(init), count);
	go([NSMutableDictionary class], @selector(alloc), count);
	
	AUTORELEASE_END;
	return 0;
}
