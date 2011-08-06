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

typedef void (*FRClassSetupCallback)(Class class, BOOL dynamicLoaded);

/*!
 \brief		Add a class setup callback
 \details	The class setup callback will be called immediately for all classes in the runtime.
			It will also be called when FREnsureClassCallbacksHaveBeenCalled is called (either
			explicaitly or because a library was loaded). Returns TRUE if the callback was added.
 */
BOOL FRAddClassSetupCallback(FRClassSetupCallback);

/*!
 \brief		Remove a class setup callback
 \details	The class setup callback will no longer be used. Returns TRUE if the callback was removed.
 */
BOOL FRRemoveClassSetupCallback(FRClassSetupCallback);

/*!
 \brief		Ensure the class setup callbacks have been performed for all classes.
 \details	This will make class setup callbacks for any classes that have been added to the runtime
			(the method may safely be called multiple times). You should call this method if you're
			dynamically adding classes that need to use features depending on class setup callbacks.
			Additionally, the implementation that is paired with this file will watch for any images
			that get loaded into the process. This is useful, but uses a private function from the dyld
			API. If you wish to disable this feature, define RED_SINGLETON_DISABLE_DYLD_PRIVATE_API_USE
			during compilation. If you choose to disable the use of the dyld API, you may wish to call
			FREnsureClassCallbacksHaveBeenCalled early on in your application's startup (and/or) after
			you load any code in order to ensure that features depending on class setup callbacks work
			properly.
 */
void FREnsureClassCallbacksHaveBeenCalled(void);
