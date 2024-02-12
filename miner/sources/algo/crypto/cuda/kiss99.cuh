#pragma once

__device__ __forceinline__
uint32_t kiss99(uint4& data)
{
    data.x = (36969u * (data.x & 0xffff)) + (data.x >> 16);
    data.y = (18000u * (data.y & 0xffff)) + (data.y >> 16);

    uint32_t mwc = (data.x << 16) + data.y;

    data.z ^= (data.z << 17);
    data.z ^= (data.z >> 13);
    data.z ^= (data.z << 5);

    data.w = (69069u * data.w) + 1234567u;

    return (mwc ^ data.w) + data.z;
}
