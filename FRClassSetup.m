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

#import <pthread.h>
#import <mach-o/dyld.h>
#import <mach-o/dyld_images.h>
#import <objc/runtime.h>

#import "FRClassSetup.h"

#if __has_feature(objc_arc)
#define bridge_ptr __bridge void *
#else
#define bridge_ptr void *
#endif

typedef struct {
	CFMutableSetRef functions;
	pthread_mutex_t lock;
} FRCallbackInfo;

static FRCallbackInfo FRClassSetupCallbackInfo(void);
static FRCallbackInfo FRClassSetupCallbackInfo(void) {
	static FRCallbackInfo callbackFunctions = {};
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		callbackFunctions.functions = CFSetCreateMutable(NULL, 0, &(CFSetCallBacks){});
		pthread_mutex_init(&callbackFunctions.lock, NULL);
	});
	return callbackFunctions;
}

BOOL FRAddClassSetupCallback(FRClassSetupCallback callback) {
	FRCallbackInfo callbackInfo = FRClassSetupCallbackInfo();
	pthread_mutex_lock(&callbackInfo.lock);
	BOOL add = !CFSetContainsValue(callbackInfo.functions, callback);
	if (add) {
		CFSetAddValue(callbackInfo.functions, callback);
		
		// call for all classes in the runtime
		int classCount = objc_getClassList(NULL, 0);
		if (classCount > 0) {
			Class *classes = (Class *)malloc(sizeof(Class) * classCount);
			classCount = objc_getClassList(classes, classCount);
			for (int i = 0; i < classCount; i++) {
				callback(classes[i], FALSE);
			}
			free(classes);
		}
	}
	pthread_mutex_unlock(&callbackInfo.lock);
	return add;
}

BOOL FRRemoveClassSetupCallback(FRClassSetupCallback callback) {
	FRCallbackInfo callbackInfo = FRClassSetupCallbackInfo();
	pthread_mutex_lock(&callbackInfo.lock);
	BOOL remove = CFSetContainsValue(callbackInfo.functions, callback);
	if (remove) {
		CFSetRemoveValue(callbackInfo.functions, callback);
	}
	pthread_mutex_unlock(&callbackInfo.lock);
	return remove;
}

static void _FREnsureClassCallbacksHaveBeenCalled(BOOL dynamic);
static void _FREnsureClassCallbacksHaveBeenCalled(BOOL dynamic) {
	static CFMutableSetRef setupClasses = NULL;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		setupClasses = CFSetCreateMutable(NULL, 0, &(CFSetCallBacks){});
	});

	FRCallbackInfo callbackInfo = FRClassSetupCallbackInfo();
	pthread_mutex_lock(&callbackInfo.lock);

	int classCount = objc_getClassList(NULL, 0);
	CFIndex callbackCount = CFSetGetCount(callbackInfo.functions);
	
	// this is declared in the dynamic support header file. it can be used to re-setup the runtime
	// support for singletons after images have been added or after classes have been created at
	// runtime.
	if (classCount > 0 && callbackCount > 0) {
		Class *classes = (Class *)malloc(sizeof(Class) * classCount);
		classCount = objc_getClassList(classes, classCount);

		FRClassSetupCallback *callbacks = malloc(sizeof(FRClassSetupCallback) * callbackCount);
		CFSetGetValues(callbackInfo.functions, (const void **)callbacks);
		
		for (int i = 0; i < classCount; i++) {
			Class class = classes[i];
			if (!CFSetContainsValue(setupClasses, (bridge_ptr)class)) {
				for (int j = 0; j < callbackCount; j++) {
					callbacks[j](class, dynamic);
				}
			}
		}
		free(classes);
		free(callbacks);
	}

	pthread_mutex_unlock(&callbackInfo.lock);
}

void FREnsureClassCallbacksHaveBeenCalled(void) {
	_FREnsureClassCallbacksHaveBeenCalled(FALSE);
}

#ifndef RED_SINGLETON_DISABLE_DYLD_PRIVATE_API_USE

// dyld private
enum dyld_image_states {
	dyld_image_state_mapped					= 10, // no batch
	dyld_image_state_dependents_mapped		= 20, // only batch
	dyld_image_state_rebased				= 30, 
	dyld_image_state_bound					= 40, 
	dyld_image_state_dependents_initialized	= 45, // single notification
	dyld_image_state_initialized			= 50, 
	dyld_image_state_terminated				= 60, // single notification
};
typedef const char *(*dyld_image_state_change_handler)(enum dyld_image_states, uint32_t, const struct dyld_image_info[]);
extern void dyld_register_image_state_change_handler(enum dyld_image_states, bool, dyld_image_state_change_handler);

static bool gHandlerSetup = false;
static const char* FRImageInitializedHandler(enum dyld_image_states state, uint32_t infoCount, const struct dyld_image_info info[]);
static const char* FRImageInitializedHandler(enum dyld_image_states state, uint32_t infoCount, const struct dyld_image_info info[]) {
	if (gHandlerSetup) {
		// only ensure runtime setup once the handler is fully set up since there's
		// no need to ensure setup for all images already in the intialized state.
		_FREnsureClassCallbacksHaveBeenCalled(TRUE);
	}
	return NULL;
}

static void initialize(void) __attribute__((constructor));
static void initialize(void) {
	dyld_register_image_state_change_handler(dyld_image_state_initialized, true, FRImageInitializedHandler);
	gHandlerSetup = true;
}

#endif
