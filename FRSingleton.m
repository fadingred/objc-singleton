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

#import <dlfcn.h>
#import <objc/runtime.h>

#import "FRSingleton.h"
#import "FRClassSetup.h"
#import "FRRuntimeAdditions.h"

#if __has_feature(objc_arc)
typedef __unsafe_unretained id unid;
#define bridge_ptr __bridge void *
#define bridge_obj __bridge id
#define obj_explicit_retain(x)  (__bridge id)(__bridge_retained void *)x
#else
typedef id unid;
#define bridge_ptr void *
#define bridge_obj id
#define obj_explicit_retain(x) [x retain]
#endif

@interface NSObject (FRObjectSingletonAdditionsDynamic)
+ (BOOL)hasSingletonProtocol;
+ (unid)singletonObjectWithZone:(NSZone *)zone; // must call hasSingletonProtocol first
@end

// load & setup
static void FRSingletonLoad(unid self);
static void FRSingletonClassSetup(Class self, BOOL dynamic);

// swizzling
static void *(*SSingletonAllocWithZone)(unid self, SEL _cmd, NSZone *zone) = NULL;
static void *(FRSingletonAllocWithZone)(unid self, SEL _cmd, NSZone *zone);

// dynamic methods
static BOOL FRSingletonProtocolYes(unid self, SEL _cmd);
static BOOL FRSingletonProtocolNo(unid self, SEL _cmd);
static BOOL FRSingletonProtocolInitialCheck(unid self, SEL _cmd);
static unid FRSingletonAllocWithZoneBlockIMP(unid self, SEL _cmd, NSZone *zone);
static unid FRSingletonAllocWithZoneAssociations(unid self, SEL _cmd, NSZone *zone);

// helpers & debugging
static unid FRSingletonCreate(unid self, SEL _cmd, NSZone *zone);
static unid FRSingletonVerify(unid self, SEL _cmd, unid singleton, Class assocclass);
static Class FRSingletonAssociationClass(unid self);
unid red_singleton_debug(void);

// globals (constant, calculated during load)
static const char *gBoolMethodType = NULL;
static const char *gAllocMethodType = NULL;
IMP (*gIMP_implementationWithBlockFunc)(void *block) = NULL;


@implementation NSObject (FRObjectSingletonAdditions)

#pragma mark -
#pragma mark general setup
// ----------------------------------------------------------------------------------------------------
// general setup
// ----------------------------------------------------------------------------------------------------

+ (void)load {
	// need to get the type encoding for bool methods
	unid objectMetaClass = object_getClass([NSObject class]);
	Method boolMethod = class_getInstanceMethod(objectMetaClass, @selector(isProxy));
	Method objectMethod = class_getInstanceMethod(objectMetaClass, @selector(allocWithZone:));
	gBoolMethodType = method_getTypeEncoding(boolMethod);
	gAllocMethodType = method_getTypeEncoding(objectMethod);
	gIMP_implementationWithBlockFunc = dlsym(RTLD_DEFAULT, "imp_implementationWithBlock");
	
	// perform general setup
	FRAddClassSetupCallback(FRSingletonClassSetup);
	FRSingletonLoad(self);
}


#pragma mark -
#pragma mark singleton load
// ----------------------------------------------------------------------------------------------------
// singleton load
// ----------------------------------------------------------------------------------------------------

static void FRSingletonLoad(unid self) {
	[self swizzleClassMethod:@selector(allocWithZone:)
						 with:(IMP)FRSingletonAllocWithZone
						store:(IMPPointer)&SSingletonAllocWithZone];
}


#pragma mark -
#pragma mark singleton setup (for every class)
// ----------------------------------------------------------------------------------------------------
// singleton setup (for every class)
// ----------------------------------------------------------------------------------------------------

static void FRSingletonClassSetup(Class class, BOOL dynamic) {
	// we explicitly add a class method for singleton checks to every class to ensure that all classes
	// handle singleton checking on their own.
	Class metaClass = object_getClass(class);
	SEL selector = @selector(hasSingletonProtocol);
	class_addMethod(metaClass, selector, (IMP)FRSingletonProtocolInitialCheck, gBoolMethodType);
}


#pragma mark -
#pragma mark helper methods
// ----------------------------------------------------------------------------------------------------
// helper methods
// ----------------------------------------------------------------------------------------------------

static unid FRSingletonCreate(unid self, SEL _cmd, NSZone *zone) {
	id singleton = [(bridge_obj)SSingletonAllocWithZone(self, _cmd, zone) init];
	// from now on, init should simply return self. the standard alloc, init sequence will always return
	// the singleton and will only perform init on it once. this allows use of the singleton in nib files
	// when it has already been used before nib loading occurs.
	[self swizzle:@selector(init) with:[self instanceMethodForSelector:@selector(self)] store:NULL];
	return singleton;
}

static unid FRSingletonVerify(unid self, SEL _cmd, unid singleton, Class assocclass) {
	if (assocclass != self && ![singleton isKindOfClass:self]) {
		NSLog(@"An attempt to access a singleton through %@ was "
			  @"made after first creating the singleton through %@. "
			  @"The result of this atempt has been set to is nil. "
			  @"Break on red_singleton_debug to debug.", self, assocclass);
		singleton = red_singleton_debug();
	}
	return singleton;
}

static Class FRSingletonAssociationClass(unid self) {
	Class assocclass = self;
	Class superclass = [self superclass];
	while (superclass) {
		if (![superclass hasSingletonProtocol]) { break; }
		assocclass = superclass;
		superclass = [superclass superclass];
	}
	return assocclass;
}


#pragma mark -
#pragma mark debug methods
// ----------------------------------------------------------------------------------------------------
// debug methods
// ----------------------------------------------------------------------------------------------------

unid red_singleton_debug(void) {
	return nil;
}


#pragma mark -
#pragma mark dynamic methods
// ----------------------------------------------------------------------------------------------------
// dynamic methods
// ----------------------------------------------------------------------------------------------------

static BOOL FRSingletonProtocolYes(unid self, SEL _cmd) { return YES; }
static BOOL FRSingletonProtocolNo(unid self, SEL _cmd) { return NO; }
static BOOL FRSingletonProtocolInitialCheck(unid self, SEL _cmd) {
	// we check this one time and then from then on, we just use a cached version. it's okay to swizzle
	// this since every class has it's own implementation of this method (thanks to the work done in
	// the singleton setup).
	
	// race condition: the intial check could happen for a class at the same time. if this method is
	// called simultaneously, the result will be the same, and there will be no negative side effects.
	BOOL has = [self conformsToProtocol:@protocol(FRSingleton)];
	BOOL (*method)(unid, SEL) = has ?
		FRSingletonProtocolYes :
		FRSingletonProtocolNo;
	[self swizzleClassMethod:@selector(hasSingletonProtocol) with:(IMP)method store:NULL];
	
	// add the object calculation method in on the assocation class (the top most ancestor class of
	// self that supports the singleton protocol).
	Class assocmeta = object_getClass(FRSingletonAssociationClass(self));
	unid (*lookup)(unid, SEL, NSZone *) = gIMP_implementationWithBlockFunc ?
		FRSingletonAllocWithZoneBlockIMP :
		FRSingletonAllocWithZoneAssociations;
	class_addMethod(assocmeta, @selector(singletonObjectWithZone:), (IMP)lookup, gAllocMethodType);
	
	return [self hasSingletonProtocol];
}

static unid FRSingletonAllocWithZoneBlockIMP(unid self, SEL _cmd, NSZone *zone) {
	Class assocclass = FRSingletonAssociationClass(self);

	__block unid singleton = nil;
	IMP result = gIMP_implementationWithBlockFunc((bridge_ptr)^(unid _self, NSZone *_zone) {
		return FRSingletonVerify(_self, _cmd, singleton, assocclass);
	});

	@synchronized(self) {
		unid (*lookup)(unid, SEL, NSZone *) = (void *)[assocclass methodForSelector:@selector(singletonObjectWithZone:)];
		if (lookup == FRSingletonAllocWithZoneBlockIMP) {
			singleton = FRSingletonCreate(self, _cmd, zone);
			[assocclass swizzleClassMethod:@selector(singletonObjectWithZone:) with:(IMP)result store:NULL];
		}
	}

	return [self singletonObjectWithZone:zone];
}

static unid FRSingletonAllocWithZoneAssociations(unid self, SEL _cmd, NSZone *zone) {
	// storing associations in a global object to avoid issues with associations when
	// using garbage collection and classes sometimes not being allocated in a gc zone.
	static unid FRSingletonObjects = @"FRSingletonObjects";
	void *assocclass = (bridge_ptr)FRSingletonAssociationClass(self);
	unid singleton = nil;
	if ((singleton = objc_getAssociatedObject(FRSingletonObjects, assocclass)) == nil) {
		@synchronized(self) {
			if ((singleton = objc_getAssociatedObject(FRSingletonObjects, assocclass)) == nil) {
				singleton = FRSingletonCreate(self, _cmd, zone);
				objc_setAssociatedObject(FRSingletonObjects, assocclass, singleton, OBJC_ASSOCIATION_ASSIGN);
			}
		}
	}
	return FRSingletonVerify(self, _cmd, singleton, (bridge_obj)assocclass);
}


#pragma mark -
#pragma mark swizzling (implementation)
// ----------------------------------------------------------------------------------------------------
// swizzling (implementation)
// ----------------------------------------------------------------------------------------------------

static void *FRSingletonAllocWithZone(unid self, SEL _cmd, NSZone *zone) {
	if ([self hasSingletonProtocol]) {
		// calling through imp to preserve the _cmd argument
		IMP singletonObjectWithZone = [self methodForSelector:@selector(singletonObjectWithZone:)];
		void *singleton = nil;
		if (singletonObjectWithZone) {
			singleton = (bridge_ptr)obj_explicit_retain(singletonObjectWithZone(self, _cmd, zone));
		}
		return singleton;
	}
	else { return SSingletonAllocWithZone(self, _cmd, zone); }
}

@end
