#pragma once

#include <cstdint>

struct color4B {
    uint8_t r,g,b,a;
};

class WindowBridge {
public:
    static void initWindow(int width, int height);
    static void updateFramebuffer(const color4B* buffer);
    static bool shouldClose();
    static void pollEvents();
};
