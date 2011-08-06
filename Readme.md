# Simple Singletons

This project allows you to easily make a class a singleton in Objective-C. With this project you can write:

    @interface FRDatabaseManager : NSObject <FRSingleton>
    @end

And your class is now a singleton -- that's all there is to it!

This method works by returning your singleton object from the alloc method. For convenience and clarity, you can also implement an accessor for the singleton:

    @implementation FRDatabaseManager
    + (id)sharedDatabaseManager { return [[self alloc] autorelease]; }
    @end


## Background

The project was first presented at [SpikedCocoa](http://www.spikedcocoa.com/) as an example of using the Objective-C runtime to our advantage. This project is by no means intended to promote wide use of the singleton design pattern. You should be aware of the drawbacks that singletons have before using them. If you decide to use singletons, though, this will significantly decrease the code you write and you'll have a better, more consistent implementation.


## Considerations

Singleton support is achieved by this project by [swizzling](http://www.cocoadev.com/index.pl?MethodSwizzling) the `NSObject::allocWithZone:` method. The implementation takes into consideration the safety and speed implications of swizzling this method.


## Compatibility

This code is compatible with Mac OS X 10.6 and later. It is most optimized on Mac OS X 10.7, as it is able to use `IMP_implementationWithBlock`. It will compile with `gcc` and `clang` and works with Automatic Reference Counting (ARC) as well as Garbage Collection.
