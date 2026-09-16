# Native UI overlays

`LEKMOD/Lua/tmp/ui/MacOS/CivilopediaScreen.xml.ignore` preserves the installed
Aspyr Expansion 2 Civilopedia hierarchy. Its source was
`Contents/Assets/Assets/DLC/Expansion2/UI/Civilopedia/CivilopediaScreen.xml`,
SHA-256 `4ebb721263713c82601266aeb37c6a0317f1f715e003eaaae7722d5bd1604e05`.
The original header/comment and control definitions are retained.

The Close control was not visibly available in the 1280×800 native window.
The overlay replaces only that control with a standard header button labeled X,
retains its ID and original Lua callback, and leaves the article/search layout
intact. Native run `20260916T022923Z` verified its visibility and actual mouse
closure. The configurator uses this layout for standard UI and EUI 1.28g, which
has no Civilopedia replacement; it defers to an EUI-provided Civilopedia context
if one is present. That guard is configuration coverage, not certification of
other EUI releases.

Existing leader content with an ArtDefineTag keeps its original scene. The 64
playable leaders that lacked that reference use `LEKMOD_StaticLeaderScene.xml`,
which displays the existing `generic_DoM.dds` Lekmod backdrop. The native leader
and trade views for Belgium were verified. This is shared static presentation,
not a claim that missing individual 3D artwork has been created.

`CityStatePopup/CityStateGreetingPopup.lua.ignore` is based on Aspyr's Expansion 2
greeting Lua, source SHA-256
`e38e8963290129979526d5aba699078265f114fac591664e782705378aa28e0c`.
Its four-personality switch is replaced by the existing shared Lekmod personality
helper. Ten data-driven personality cases pass; six custom cases were blank in
the original block. Native run `20260916T033220Z` rendered Pacifistic correctly
and used normal Close/save/exit. EUI's deliberately empty greeting override is
retained; EUI already uses the shared helper in its own city-state popup.
