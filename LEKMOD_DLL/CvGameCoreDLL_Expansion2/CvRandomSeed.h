#pragma once

// Civilization V's LCG and its save/network seed representation are 32-bit.
// Windows unsigned long wraps at 32 bits; LP64 macOS unsigned long does not.
// Preserve the existing public/member types while enforcing identical state.
inline unsigned long CvNormalizeRandomSeed(unsigned long seed)
{
	return seed & 0xffffffffUL;
}

inline unsigned long CvNextRandomSeed(unsigned long seed, unsigned long multiplier,
	unsigned long increment)
{
	return CvNormalizeRandomSeed(multiplier * seed + increment);
}
