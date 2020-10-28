all: lib unit-tests

CXXFLAGS = -Wall -Wno-deprecated-declarations -std=c++17 -pthread	\
-ggdb -fno-finite-math-only
LDFLAGS = -L$(BUILD_DIR) -Lgoogletest/lib
LDLIBS = -l$(LIB) -lgmock_main -lgmock -lgtest
INCLUDEPATH = -I$(SOURCE_DIR) -Igoogletest/include
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

SOURCES = $(wildcard $(SOURCE_DIR)/*.cc)
TEST_SOURCES = $(wildcard $(TEST_DIR)/*.cc)

OBJ = $(patsubst $(SOURCE_DIR)/%.cc,%,$(SOURCES))
TEST_OBJ = $(patsubst $(TEST_DIR)/%.cc,%,$(TEST_SOURCES))

BUILD_OBJ = $(patsubst %,build/%.o,$(OBJ))
TEST_BUILD_OBJ = $(patsubst %,build/%.o,$(TEST_OBJ))

FULLVERSION=$(VERSION)

CXXFLAGS += -DDLLVERSION="\"$(FULLVERSION)\"" $(OSFLAG) $(INCLUDEPATH)

ifeq "$(ARCH)" "x86_64"
CXXFLAGS += -msse -msse2 -mfpmath=sse -ffast-math
endif

CPPFLAGS = -std=c++17
BUILD_DIR = build
SOURCE_DIR = src
TEST_DIR = test
LIB = dll

lib: build/lib$(LIB).a

$(BUILD_DIR)/libdll.a: $(BUILD_OBJ)
	ar rcs $@ $^

%/.directory:
	mkdir -p $*
	touch $@

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.cc $(wildcard $(SOURCE_DIR)/*.h) build/.directory
	$(CXX) $(CXXFLAGS) -c $< -o $@
$(BUILD_DIR)/%.o: $(TEST_DIR)/%.cc $(wildcard $(SOURCE_DIR)/*.h) build/.directory
	$(CXX) $(CXXFLAGS) -c $< -o $@

clangformat:
	clang-format-9 -i $(wildcard $(SOURCE_DIR)/*.cc)           \
	$(wildcard $(SOURCE_DIR)/*.h) $(wildcard $(TEST_DIR)/*.cc) \
	$(wildcard $(TEST_DIR)/*.h)

clean:
	rm -Rf $(BUILD_DIR) $(SOURCE_DIR)/*~ $(TEST_DIR)/*~ googletest

unit-tests: $(BUILD_DIR)/unit-test-runner
	$<

$(BUILD_DIR)/unit-test-runner: googletest/lib/libgmock_main.a lib $(TEST_BUILD_OBJ)
	$(CXX) $(CXXFLAGS) -o $@ $(TEST_BUILD_OBJ) $(LDFLAGS) $(LDLIBS)

googletest: googletest/include/gmock/gmock.h googletest/lib/libgmock_main.a

googletest/include/gmock/gmock.h googletest/lib/libgmock_main.a: googletest/build/Makefile
	$(MAKE) -C googletest/build VERBOSE=1 install

googletest/build/Makefile: googletest/CMakeLists.txt
	mkdir -p googletest/build
	cd googletest/build && cmake -DCMAKE_INSTALL_PREFIX=.. ..

googletest/CMakeLists.txt:
	git clone git@github.com:google/googletest || git clone https://github.com/google/googletest
