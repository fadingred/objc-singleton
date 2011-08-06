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

static bool deallocated;

@interface FRSingleton : NSObject <FRSingleton>
@end
@implementation FRSingleton
- (void)dealloc {
	deallocated = TRUE;
	#if !__has_feature(objc_arc)
	[super dealloc];
	#endif
}
@end

@interface FRSingletonBase1 : NSObject <FRSingleton>
@end
@implementation FRSingletonBase1
@end

@interface FRSingletonSubclass1 : FRSingletonBase1
@end
@implementation FRSingletonSubclass1
@end

@interface FRSingletonBase2 : NSObject <FRSingleton>
@end
@implementation FRSingletonBase2
@end

@interface FRSingletonSubclass2 : FRSingletonBase2
@end
@implementation FRSingletonSubclass2
@end

#import <objc/message.h>

int main() {
	BOOL gcEnabled = [NSClassFromString(@"NSGarbageCollector") defaultCollector] != nil;
	AUTORELEASE_BEGIN;
	
	id base = nil;
	id subclass = nil;
	
	// test 1
	// --------------------------------------------------------------------------------
	FRAssertEquals(obj_autorelease([FRSingleton alloc]), obj_autorelease([[FRSingleton alloc] init]), nil);
	
	// test 2
	// --------------------------------------------------------------------------------
	subclass = obj_autorelease([FRSingletonSubclass1 alloc]);
	base = obj_autorelease([FRSingletonBase1 alloc]);
	FRAssertEquals([subclass class], [FRSingletonSubclass1 class], nil);
	FRAssertEquals([base class], [FRSingletonSubclass1 class], nil);
	FRAssertEquals(subclass, base, nil);
	
	// test 3
	// --------------------------------------------------------------------------------
	base = obj_autorelease([FRSingletonBase2 alloc]);
	NSLog(@"------------- expecting error output -------------");
	subclass = obj_autorelease([FRSingletonSubclass2 alloc]);
	NSLog(@"-------- no longer expecting error output --------");
	FRAssertEquals([base class], [FRSingletonBase2 class], nil);
	FRAssertNotNil(base, nil);
	FRAssertNil(subclass, nil);

	FRAssertFalse(deallocated, nil);
	id singleton = obj_autorelease([[FRSingleton alloc] init]);
	obj_explicit_release(singleton);
	FRAssertFalse(deallocated, nil);
	
	AUTORELEASE_END;
	FRAssertTrue(deallocated || gcEnabled, nil); // must check outside of autorelease pool
	return 0;
}
