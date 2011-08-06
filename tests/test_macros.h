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

#define FRAssertGeneral(condition, default_msg, fmt, ...) do {\
	if (!(condition)) { \
		NSString *__reason = fmt ? \
			[NSString stringWithFormat:fmt ? fmt : @"", ##__VA_ARGS__] : default_msg; \
		[[NSException exceptionWithName:@"TestFailure" reason:__reason userInfo:nil] raise]; \
	} \
} while (0)

#define FRAssertEquals(arg1, arg2, fmt, ...) \
	FRAssertGeneral(arg1 == arg2, ([NSString stringWithFormat:@"%s == %s failed", #arg1, #arg2]), fmt, ##__VA_ARGS__)

#define FRAssertNotEquals(arg1, arg2, fmt, ...) \
	FRAssertGeneral(arg1 != arg2, ([NSString stringWithFormat:@"%s != %s failed", #arg1, #arg2]), fmt, ##__VA_ARGS__)

#define FRAssertNil(arg, fmt, ...) FRAssertEquals(arg, nil, fmt, ##__VA_ARGS__)
#define FRAssertNotNil(arg, fmt, ...) FRAssertNotEquals(arg, nil, fmt, ##__VA_ARGS__)
#define FRAssertFalse(arg, fmt, ...) FRAssertEquals(arg, FALSE, fmt, ##__VA_ARGS__)
#define FRAssertTrue(arg, fmt, ...) FRAssertEquals(arg, TRUE, fmt, ##__VA_ARGS__)

#if __has_feature(objc_arc)
#define AUTORELEASE_BEGIN @autoreleasepool {
#define AUTORELEASE_END }
#define obj_retain(x) x
#define obj_release(x) (void)x
#define obj_autorelease(x) x
#define obj_explicit_release(x)  (void)(__bridge_transfer id)(__bridge void *)x
#else
#define AUTORELEASE_BEGIN NSAutoreleasePool *__pool = [[NSAutoreleasePool alloc] init];
#define AUTORELEASE_END [__pool release];
#define obj_retain(x) [x retain]
#define obj_release(x) [x release]
#define obj_autorelease(x) [x autorelease]
#define obj_explicit_release(x) [x release]
#endif
