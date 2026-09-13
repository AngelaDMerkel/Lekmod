// Standalone regression: no game launch or proprietary runtime required.
#include "../CvGameCoreDLL_Expansion2/CvRandomSeed.h"
#include <cassert>
#include <cstdint>
#include <cstdio>

int main()
{
    const unsigned long multipliers[] = {1103515245UL, 214013UL};
    const unsigned long increments[] = {12345UL, 2531011UL};
    const unsigned long seeds[] = {0UL, 12345UL, 0x7fffffffUL, 0xffffffffUL, ~0UL};
    for (unsigned scheme = 0; scheme < 2; ++scheme) {
        for (unsigned long initial : seeds) {
            unsigned long seed = CvNormalizeRandomSeed(initial);
            uint32_t windowsSeed = static_cast<uint32_t>(initial);
            for (unsigned i = 0; i < 100000; ++i) {
                seed = CvNextRandomSeed(seed, multipliers[scheme], increments[scheme]);
                windowsSeed = static_cast<uint32_t>(
                    uint64_t(multipliers[scheme]) * windowsSeed + increments[scheme]);
                assert(seed == windowsSeed);
                // Aspyr FDataStream writes four bytes, then zero-extends on read.
                const unsigned long restored = static_cast<uint32_t>(seed);
                assert(seed == restored);
            }
        }
    }
    assert(CvNextRandomSeed(12345UL, 1103515245UL, 12345UL) == 3554416254UL);
    if (sizeof(unsigned long) > 4) {
        const unsigned long oldSeed = 1103515245UL * 12345UL + 12345UL;
        assert(oldSeed != static_cast<uint32_t>(oldSeed));
    }
    std::puts("RNG: 1,000,000 transitions match 32-bit Windows state and Aspyr serialization");
}
