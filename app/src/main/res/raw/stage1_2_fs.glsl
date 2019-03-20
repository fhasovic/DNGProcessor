#version 300 es

precision mediump float;

uniform sampler2D rawBuffer;
uniform int rawWidth;
uniform int rawHeight;

// Sensor and picture variables
uniform int cfaPattern; // The Color Filter Arrangement pattern used
uniform bool oneDotFive;

// Out
out float intermediate;

float[25] load5x5(int x, int y) {
    float outputArray[25];
    for (int i = 0; i < 25; i++) {
        ivec2 pos = ivec2(x + (i % 5) - 2, y + (i / 5) - 2);
        if (oneDotFive && ((pos.x % 8 == 6 && pos.y % 16 == 1) || (pos.x % 8 == 2 && pos.y % 16 == 9))) {
            // OnePlus 5 Dot-Fix: Bilinear interpolate this green pixel in a cross
            for (int j = 0; j < 4; j++) {
                outputArray[i] += texelFetch(rawBuffer, pos
                    + ivec2(2 * (j % 2) - 1, 2 * (j / 2) - 1), 0).x;
            }
            outputArray[i] *= 0.25f;
        } else {
            outputArray[i] = texelFetch(rawBuffer, pos, 0).x;
        }
    }
    return outputArray;
}

int ind(int x, int y) {
    int dim = 5;
    return x + dim / 2 + (y + dim / 2) * dim;
}

float demosaicG(int x, int y, float[25] inputArray) {
    int index = (x & 1) | ((y & 1) << 1);
    index |= (cfaPattern << 2);
    float p = inputArray[ind(0, 0)];
    switch (index) {
        // RGR
        case 1:     //  R[G] G B
        case 4:     // [G]R  B G
        case 11:    //  G B  R[G]
        case 14:    //  B G [G]R
        // BGB
        case 2:     //  R G [G]B
        case 7:     //  G R  B[G]
        case 8:     // [G]B  R G
        case 13:    //  B[G] G R
            return p;
    }

    float dxp = p * 2.f - inputArray[ind(-2, 0)] - inputArray[ind(2, 0)];
    float dx = abs(inputArray[ind(-1, 0)] - inputArray[ind(1, 0)]) + abs(dxp);
    float gx = (inputArray[ind(-1, 0)] + inputArray[ind(1, 0)]) * 0.5f + dxp * 0.25f;

    float dyp = p * 2.f - inputArray[ind(0, -2)] - inputArray[ind(0, 2)];
    float dy = abs(inputArray[ind(0, -1)] - inputArray[ind(0, 1)]) + abs(dyp);
    float gy = (inputArray[ind(0, -1)] + inputArray[ind(0, 1)]) * 0.5f + dyp * 0.25f;

    float w = 0.5f, w1 = 0.87f;
    if (dx < dy) {
        w = 1.f - w1;
    } else if (dx > dy) {
        w = w1;
    }

    return max(mix(gx, gy, w), 0.f);
}

void main() {
    ivec2 xy = ivec2(gl_FragCoord.xy);
    int x = clamp(xy.x, 2, rawWidth - 3);
    int y = clamp(xy.y, 2, rawHeight - 3);

    float[25] inoutPatch = load5x5(x, y);
    intermediate = demosaicG(x, y, inoutPatch);
}
