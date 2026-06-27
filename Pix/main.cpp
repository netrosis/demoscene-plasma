#include "Window.h"
#include <vector>

const int GB_WIDTH = 160;
const int GB_HEIGHT = 144;

#define PI 3.14159265

struct Vec2{
    float x,y;
    
    Vec2 operator+(const Vec2& other){
        return Vec2(x+other.x,y+other.y);
    }
    
    Vec2 operator-(const Vec2& other){
        return Vec2(x-other.x,y-other.y);
    }
};

float length(Vec2 vector){
    return std::sqrt((vector.x*vector.x)+(vector.y*vector.y));
}

float dot(const Vec2& v1, const Vec2& v2){
    return (v1.x*v2.x)+(v1.y*v2.y);
}

color4B plasmaGen(int xIn, int yIn, float iTime){
    float time = iTime*0.001f;
    
    float color1, color2;
    
    float x = xIn;
    float y = yIn;
    
    color1 = (sin(dot({x,y},{sin(time*3.0f),cos(time*3.0f)})*0.02f+time*3.0f)+1.0f)/2.0f;
    
    Vec2 a = {80,72};
    Vec2 b = {80*sin(-time*3.0f),72*cos(-time*3.0f)};
    Vec2 center = a+b;
    
    Vec2 frag{x,y};
    
    color2 = (cos(length(frag-center)*0.03f)+1.0f)/2.0f;
    
    float color = (color1+color2)/2.0f;
    
    float red = (cos(PI*color/0.5f+time*3.0f)+1.0f)/2.0f;
    float green = (sin(PI*color/0.5f+time*3.0f)+1.0f)/2.0f;
    float blue = (sin(time*3.0f)+1.0f)/2.0f;
    
    uint8_t r = (uint8_t) (red*255);
    uint8_t g = (uint8_t) (green*255);
    uint8_t bn = (uint8_t) (blue*255);
    return {r,g,bn,255};
}

int main() {
    
    WindowBridge::initWindow(GB_WIDTH, GB_HEIGHT);
    
    std::vector<color4B> frameBuffer(GB_WIDTH * GB_HEIGHT);

    float iTime = 0;
    for (int y = 0; y < GB_HEIGHT; ++y) {
        for (int x = 0; x < GB_WIDTH; ++x) {
            int index = y * GB_WIDTH + x;
            frameBuffer[index] = plasmaGen(x,y,iTime);
        }
    }

    while (!WindowBridge::shouldClose()) {
        WindowBridge::pollEvents();
        
        for (int y = 0; y < GB_HEIGHT; ++y) {
            for (int x = 0; x < GB_WIDTH; ++x) {
                int index = y * GB_WIDTH + x;
                frameBuffer[index] = plasmaGen(x,y,iTime);
            }
        }
        WindowBridge::updateFramebuffer(frameBuffer.data());
        
        iTime++;
    }
    
    return 0;
}
