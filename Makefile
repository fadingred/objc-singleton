# 
# Copyright (c) 2011 FadingRed LLC
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 

# Flags for clang with ARC
CC=clang
CFLAGS=-std=c99 -Wall -fobjc-arc
LDFLAGS=

# # Flags for clang with GC
# CC=clang
# CFLAGS=-std=c99 -Wall -fobjc-gc-only
# LDFLAGS=

# # Flags for gcc
# CC=gcc
# CFLAGS=-std=c99 -Wall
# LDFLAGS=

SOURCES:=$(shell echo *.m)
HEADERS:=$(shell echo *.h)
OBJECTS:=$(foreach obj,$(SOURCES:.m=.o),build/$(obj))
TEST_SOURCES:=$(shell echo tests/test_*.m)
TEST_LIBSRCS:=$(shell echo tests/lib_*.m)
TEST_HEADERS:=$(shell echo tests/test_*.h)
TEST_EXECUTABLES:=$(foreach test,$(TEST_SOURCES:.m=),$(subst tests/,build/,$(test))) build/test_speedwithout
TEST_LIBS:=$(foreach lib,$(TEST_LIBSRCS:.m=.dylib),$(subst tests/,build/,$(lib)))

all: build $(TEST_EXECUTABLES) $(TEST_LIBS) $(OBJECTS)

build:
	mkdir -p build

build/%.o: %.m $(HEADERS)
	$(CC) -c $(CFLAGS) $< -o $@

build/%.dylib: tests/%.m $(TEST_HEADERS)
	$(CC) -dynamiclib -framework Foundation $(CFLAGS) $< -o $@

build/%: tests/%.m $(OBJECTS) $(TEST_HEADERS)
	$(CC) $(CFLAGS) -I. -framework Foundation $< $(OBJECTS) -o $@

build/test_speedwithout: tests/test_speed.m $(TEST_HEADERS)
	$(CC) $(CFLAGS) -I. -framework Foundation $< -o $@

clean:
	rm -rf build

.PHONY: all clean
