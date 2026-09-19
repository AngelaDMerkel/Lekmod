# Current-Mac overview and screen-size checks

These are actual mouse/keyboard checks on the current Mac, using read-only
observation and the preserved Huge-map turn-111 save. They do not advance the
accepted long campaign. Foreground sessions were authorized by the user.

## Compact EUI baseline

`20260918T060233Z` used EUI 1.28g at requested 1024x768 and signed GameCore
`cf5273574eb622c53b700d6a0dbfa1e2ff882f5475d4c9a486aa4cdac740e798`.
The private archive was `Lekmod-eui-overviews-20260918.zip`, SHA-256
`dee6ca5a236292474bfc5a45dd7b25861fbf9a6c02ac91ac77062168301454f2`.
Actual input opened the following screens:

- Economic Overview: General Information and Resources & Happiness.
- Military Overview: the 23-unit list scrolled to its final rows; Close worked.
- Diplomacy Overview: relationships, empty Deal History and Global Politics.
- Notification Log: long messages wrapped within the visible panel.
- Religion Overview: Your Religion, World Religions and Beliefs; page clicks
  reached the final Zakat row. Long belief descriptions used ellipses.
- Espionage Overview: Move opened destination selection, Cancel returned,
  and Intrigue showed its empty state. No agent was assigned.
- Demographics: all eight rows and Close were visible.
- Trade Route Overview: all three tabs rendered empty tables in this fixture;
  this is empty-state coverage, not a populated-route layout pass.
- Technology tree: F6 opened it and actual Close returned to the map; the
  horizontal scrollbar and Close were visible at the compact size.

One product defect was observed: personality values were blank for Monaco,
Port-au-Prince and Mohenjo-Daro. Their names, traits and resources rendered.
The defective screenshot is `diplomacy-blank-personality.png` in the run folder.
Other screenshots and hashes are in `physical-overview-events.json`.

The process exited normally (0) through actual Escape / Exit to Windows / Yes,
after 426.7 seconds. Settings, graphics, hooks and original manual saves were
preserved. The EUI wrapper `20260918T060225Z` restored the exact standard payload,
EUI text and options. No Lua/synchronization failures were recorded. The single
observed gameplay snapshot remained at turn 111. The session is retained as a
personality display failure with passing scoped navigation checks.

## Diplomacy personality correction

The stock BNW `DiploRelationships.lua` recognizes only the four original
personality enum values. The new ordinary UI template retains the stock screen
and routes its personality label/tooltips through the existing
`CityStatePersonalityHelper`. Both standard and EUI assembly include the template.
No gameplay personality or diplomatic rule changes.

An extracted-block test reproduces blank values for all six added types on the
original source. All ten shipped types pass after correction; all ten greeting
regressions and nine UI-assembly tests also pass. The native baseline is retained
locally as `build/macos/DiploRelationships-native-before.lua`.

`20260918T061213Z` retested standard UI at 1024x768. Actual F4 displayed Monaco
as Wealthy, Port-au-Prince as Isolationist and Mohenjo-Daro as Pacifistic, matching
the read-only engine type observations. The Wealthy descriptive tooltip appeared;
clicking the row also opened Monaco's normal detail popup, which was closed.
The tourism indicator opened Culture Overview; all four tabs rendered, including
an empty exchange list and visible disabled Swap control. No work was moved.
The culture overview option was enabled in this save.

Normal physical exit returned 0 after 195.2 seconds. Settings/graphics/hooks and
manual saves were preserved, with no Lua/sync errors and unchanged observed
turn-111 gameplay state. This used `Lekmod-diplo-personalities-20260918.zip`, SHA-256
`4c18117705f5bd85e8013f326d80b1c06ead25f4a974c0fdc5a1d8d675bfadce`,
with the same signed GameCore. It is an intermediate test artifact built with
uncommitted display/test changes; final release regression remains separate.

## Larger EUI regression

`20260918T061609Z` used requested 1440x900 and private corrected EUI archive
`Lekmod-eui-personalities-20260918.zip`, SHA-256
`08af0fa879e441d697f5f9ae94c4d2d45fef25c3cac5ecdb7649af4f927f514f`.
Actual F4 showed the same three corrected labels. Scrollbar clicks reached the
last city-state and returned to Ife (Impoverished, red) and Mogadishu (Neutral),
also matching engine observations. No personality value was supplied.

The tourism display opened Culture Overview. Selecting Greece instead of Rome
refreshed tourism from 0 to 2 and the influence levels, modifiers and trend
indicators. The Culture Victory table also rendered in bounds. F1, Units and
the Mpiambina row opened the corresponding Civilopedia article; image, stats,
text, scrolling regions and the header X were visible. Actual X closed it. F6
opened the technology tree; clicking its horizontal scrollbar moved from the
Ancient era to Atomic/Information technologies, and actual Close returned.

Physical Exit to Windows / Yes returned 0 after 274.5 seconds. There were no Lua
or synchronization errors, all settings/graphics/hooks/manual saves were
preserved, and the wrapper restored standard payload/text/options. The observed
gameplay state remained at turn 111. Screenshot hashes and the supplemental
verdict are retained in the run directory.

These checks add compact and larger layouts to the earlier 1280x800 physical
city/save tests. They do not establish populated trade-table or occupied-work
mouse coverage, every popup, every resolution, startup reliability or gameplay
mechanics represented by read-only overview values.

## EUI occupied Great Works and physical quickload

`20260918T062447Z` loaded the preserved two-Museum fixture at requested 1024x768.
Its original two Artists and Museums were supplied in the earlier scenario;
this session supplied no new units, buildings, works or gameplay values. The
observer only read all city work slots, Museum themes and tourism.

Actual Culture Overview clicks established these outcomes at unchanged turn 179:

- Selecting artwork then an empty writing slot changed only selection. The
  complete observed gameplay state remained unchanged.
- Moving work 1 from Rome to Antium preserved both work IDs, removed the Museum
  theme and yielded two tourism per city.
- Selecting both occupied slots swapped work 0/work 1 across cities without
  duplication. Theme 0/tourism 2 per city remained; another real swap reversed it.
- F11 saved that split arrangement. An unsaved move then reunited the pair in
  Rome, restoring theme 2/tourism 6 and leaving Antium empty.
- Ctrl+F11 restored the exact full saved observer string: split works, both
  themes 0, tourism 2 each, city/unit/treasury/queue/yield state and turn 179. The
  quicksave file was unchanged by loading.
- Click to View and the occupied slot opened Bartholomeus Spranger's Self
  portrait with artwork/title and a visible Close. Actual Close returned to
  Culture Overview without changing the saved arrangement.

Quicksave SHA-256: `92c6f2301ced5ef6a4355f07f3186a307febc225b9389d73b35e817568ccd5f6`.
The retained copy is `062447Z/EUI-GreatWork-QuickSave.Civ5Save`. Before F11, the
previous test quicksave was verified against its preserved `053742Z` copy
(`9ef8ba46…`); no original manual save was overwritten. Every intermediate
assertion, full snapshot and screenshot hash is retained in the run folder.

The normal physical exit returned 0 after 405.7 seconds. Settings, graphics, hooks
and manual saves were preserved, with no Lua or synchronization errors. Wrapper
`20260918T062439Z` restored standard payload, EUI text and options. The preceding
`062317Z` attempt failed during localization startup before opening the save and
remains failed; its host error diagnostic was 0. No retry reclassified that run.

This adds actual mouse Great Work management and EUI keyboard quicksave/load
coverage. Foreign-player exchanges and populated trade overview remain separate.

`20260918T063242Z` loaded that EUI quicksave under standard UI at 1440x900.
The entire recorded observer string matched the EUI saved state before input.
Actual clicks rejected an artwork-to-writing slot change, swapped occupied
Museum works across cities, reversed that swap, then restored both works to
Rome. IDs and total count were preserved; Rome regained theme 2/tourism 6,
Antium returned to zero. The normal production notification opened Antium's
list and Back closed it. Its banner opened the larger city screen, where all
nine focus controls, specialist/work slots and Return to Map were visible.
No production or focus selection was made. These city-screen checks do not
assert that opening a city preserves its automatic citizen assignments.

The session exited normally through physical Return / Escape / Exit to Windows
/ Yes, returned 0 and preserved original manual saves, settings, graphics and
hooks. No Lua/sync errors were recorded. Its source quicksave remains byte
identical; these later standard-UI changes were not saved.


## Populated standard trade overview, 2026-09-19

Foreground session `20260919T041547Z` loaded the preserved internal land/sea
route fixture `20260916T080553Z` at requested 1440×900. Actual CUA mouse clicks
opened Additional Information → Trade Route Overview. No gameplay callback
selected a route, and no turn advanced.

Your Trade Routes showed Antium→Rome land food 1.8/19 turns and Antium→Cumae
sea production 3.5/24 turns. These match the saved native route values of
175 hundredths food (rounded to one decimal), 350 hundredths production, and
19/24 remaining turns. Destination sorting toggled Cumae/Rome order and back;
remaining-turn sorting toggled 19/24 to 24/19 without detaching route values.

Trade Routes Available displayed populated internal and international choices.
A real origin-gold header click sorted the visible external quotes as
11.3, 7.6, 7.5, 6 and 5.8, followed by zero-gold internal choices. Column and
tab tooltips were readable. A scrollbar-thumb drag reached the final rows with
headers and Close still visible. Wheel movement was observed, but the retained
end-of-list evidence uses the verified thumb drag. Different food/production
choices for the same city pair are kept distinct.

Trade Routes with You was empty in this fixture; populated incoming routes
are not covered by this session. Returning to Your Trade Routes restored its
two unchanged rows. Actual Close returned to the map, then Escape → Exit to
Windows → Yes closed the game normally (0) after 367 seconds without a
supervisor signal. Settings/resolution/hooks and manual saves were restored.
No Lua errors, synchronization failures or new diagnostics were reported.
The read-only observer logged one unchanged game-state signature; displayed
turn 180 and treasury 2,202 stayed unchanged. No new save was requested.

The automatic runner labels this `ended-manual-ui-session`; physical evidence
is recorded separately in `physical-overview-events.json` and
`physical-completion.json` under the run directory. Retained screenshot hashes:

| Screenshot | SHA-256 |
| --- | --- |
| `trade-own-routes.png` | `e63303e76edb99707b890007272f621b4aada2a3d8ebd3934c0b0e79e22036bb` |
| `trade-sort-desc.png` | `491a63f0ca0ed8178b5697a1aa40fd581942b99725bb845f587009efa68bd675` |
| `trade-available-gold.png` | `96e35c5ec1f1b57f27bf4c0f06a510966c9e5b7b911c35f99a28720c3cfc542e` |
| `trade-available-bottom.png` | `5f183b2d75a564fbbdcd3bfc3fc8ca9906eb976d6ed04b7595508c8a74289b64` |
| `trade-overview-closed.png` | `7911b4f34a55a26597c082ea27f357a0b570fb8884d2386d83c8646d85ace363` |

This closes the populated standard own/available table interaction on the
tested display. Populated incoming routes, EUI parity for these rows and foreign
Great Work exchange remain separate checks. The installed package/core were
the Moors-founding intermediate artifact recorded in its validation report.
