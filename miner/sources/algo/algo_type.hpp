#pragma once


#include <string>


namespace algo
{
    enum class ALGORITHM : uint8_t
    {
        SHA256,
        ETHASH,
        ETCHASH,
        PROGPOW,
        KAWPOW,
        FIROPOW,
        EVRPROGPOW,
        AUTOLYKOS_V2,
        UNKNOW,
        MAX_SIZE = algo::ALGORITHM::UNKNOW
    };

    std::string toString(algo::ALGORITHM const algorithm);
}
