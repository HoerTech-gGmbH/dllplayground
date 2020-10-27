all: lib

CXXFLAGS = -Wall -Wno-deprecated-declarations -std=c++17 -pthread	\
-ggdb -fno-finite-math-only

OSFLAG :=
ifeq ($(OS),Windows_NT)
	OSFLAG += -D WIN32
	ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
		OSFLAG += -D AMD64
	endif
	ifeq ($(PROCESSOR_ARCHITECTURE),x86)
		OSFLAG += -D IA32
	endif
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSFLAG += -D LINUX
		CXXFLAGS += -fext-numeric-literals
	endif
	ifeq ($(UNAME_S),Darwin)
		OSFLAG += -D OSX
	endif
		UNAME_P := $(shell uname -p)
	ifeq ($(UNAME_P),x86_64)
		OSFLAG += -D AMD64
	endif
		ifneq ($(filter %86,$(UNAME_P)),)
	OSFLAG += -D IA32
		endif
	ifneq ($(filter arm%,$(UNAME_P)),)
		OSFLAG += -D ARM
	endif
endif

VERSION=0.1

OBJ = dll

BUILD_OBJ = $(patsubst %,build/%.o,$(OBJ))

FULLVERSION=$(VERSION)

CXXFLAGS += -DDLLVERSION="\"$(FULLVERSION)\"" $(OSFLAG)

ifeq "$(ARCH)" "x86_64"
CXXFLAGS += -msse -msse2 -mfpmath=sse -ffast-math
endif

CPPFLAGS = -std=c++17
BUILD_DIR = build
SOURCE_DIR = src

lib: build/libdll.a

build/libdll.a: $(BUILD_OBJ)
	ar rcs $@ $^

%/.directory:
	mkdir -p $*
	touch $@

build/%.o: src/%.cc $(wildcard src/*.h) build/.directory
	$(CXX) $(CXXFLAGS) -c $< -o $@

clangformat:
	clang-format-9 -i $(wildcard src/*.cc) $(wildcard src/*.h)

clean:
	rm -Rf build src/*~ googletest

googletest: googletest/include/gmock/gmock.h googletest/lib/libgmock_main.a

googletest/include/gmock/gmock.h googletest/lib/libgmock_main.a: googletest/build/Makefile
	$(MAKE) -C googletest/build VERBOSE=1 install

googletest/build/Makefile: googletest/CMakeLists.txt
	mkdir -p googletest/build
	cd googletest/build && cmake -DCMAKE_INSTALL_PREFIX=.. ..

googletest/CMakeLists.txt:
	git clone git@github.com:google/googletest || git clone https://github.com/google/googletest
