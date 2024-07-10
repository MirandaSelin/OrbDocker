CXX = g++
CXXFLAGS = -std=c++11 -Wall
LDFLAGS = $(shell pkg-config --libs opencv)
TARGET = basic_webcam

SRC = basic_webcam.cc
OBJ = $(SRC:.cc=.o)

all: $(TARGET)

$(TARGET): $(OBJ)
    $(CXX) $(LDFLAGS) $^ -o $@

%.o: %.cc
    $(CXX) $(CXXFLAGS) -c $< -o $@

clean:
    rm -f $(OBJ) $(TARGET)
