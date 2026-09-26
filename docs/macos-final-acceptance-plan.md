# Current-Mac single-player final acceptance plan

Written 2026-09-26. Execution order: **resolve gameplay gaps → freeze the candidate
→ run reliability qualification → record final acceptance**. This document is a
plan, not evidence that its unchecked requirements have passed.

## Scope and starting point

Acceptance means that the defined single-player requirements pass on this
Mac14,5 / M2 Max, macOS26.5.2, using the supported Aspyr x86-64 host, a pinned
Lekmod package, WSDLC installation and the already-supported standard/EUI
configurations. It does not mean every possible game-state combination has been
exhaustively exercised. Existing successful evidence should be reused when its
applicability to the candidate is demonstrated.

The accepted long turn-testing phase stays closed. Its incomplete 100-turn target
is not relabeled as passed. No new long campaign, multiplayer, hotseat, PBEM or
additional Mac/macOS qualification belongs to this plan. Publication is separate
from local acceptance; no push or release is authorized by this plan.

Starting candidate: `build/macos/Lekmod-steam-startup-20260926.zip`, SHA-256
`edd00aa4d8eca910ee90777465e6db7eeae92b02aa2bff709f44fdb06b529002`.
GameCore/DLC provenance is clean `ec9fb383`; startup-library source is `5b1ed586`.
See [host correction and Steam verification](macos-host-stat-abi.md) for the full
component hashes. This candidate has the Swiss, Yugoslav and Romanian fixes,
the comprehensive81-check/16-replay process-only correction regression, the
installed-path database regression, and actual Steam/Aspyr Play → existing save
→ normal exit0 evidence. The comprehensive run is not silently reassigned to the
later archive's installation path.

WSDLC startup installation was qualified at `562e490`/`dbae158`. Its checkout has
since advanced independently to `c103ed2` (HTTPS/dependency and distribution work).
Preserve those changes and recheck the exact installer/dependencies chosen for
final acceptance. Do not assume the old161-test result covers later revisions.

## 1. Turn the remaining gameplay work into a finite case register

Before launching another gameplay round:

1. Reconcile the [civilization inventory](macos-civilization-coverage.md),
   [system ledger](macos-expanded-coverage.md), feature reports and actual native
   reports. Mark historical descriptions as historical; retain failed runs.
   Distinguish a remaining test from a confirmed product defect or harness defect.
2. Enumerate active shipped effects from resolved XML/SQL, active Lua contexts
   and the native implementations they call. Start with114 civilizations,
   90 replacement buildings and125 non-default replacement units. Include
   standalone classes such as the Swiss Reislaufer, linked promotions, unique
   improvements, beliefs, policies, projects and non-civilization handlers.
   Those three catalogue counts are not an exhaustive effect inventory.
3. Map each distinct effect/branch to a case, previous evidence or a documented
   shared implementation. Parameter differences still need assertions for their
   values. Sharing one native control is justified only by the same implementation
   and applicable conditions; it cannot erase a civilization-specific exception.
4. Freeze a versioned register at
   `docs/macos-gameplay-acceptance-cases.json` with stable IDs. For each case record:
   source/data references and hashes, affected owners, expected result and units,
   supplied fixture inputs, actual trigger, negative control, relevant transitions,
   persistence requirement, evidence level, fixture hashes, batch/stage, status
   and evidence links. This register is a planned deliverable, not yet generated.

Statuses: `untriaged`, `ready`, `harness-blocked`, `product-failed`, `passed`,
`covered-by-evidence`, or `out-of-scope`. Each out-of-scope/equivalence decision
needs its reason. A gameplay requirement cannot be waived simply to reach100%.
New discoveries amend the register with a reason; the backlog does not expand
silently. Record totals only after this reconciliation; stale “pending” text is
not a reliable denominator.

**Gate G0:** every active in-scope effect and every existing “remaining” entry is
mapped; there are no untriaged entries. Produce the exact case count and batch
schedule at this gate. This avoids inventing an overall completion percentage now.

## 2. Close gameplay cases in batches

The following are work groups, not claims that executable plans already exist.
Reuse the existing civilization-group and feature saves. Commission new assertions
offline, then run multiple independent stages and exact reloads in one game
process with `batch-playtest.py`. Target15–45minute sessions within the existing
60minute recovery bound; finish early when the checks finish. Keep explicit
per-stage and aggregate turn caps. Most cases should need0–6 ordinary turns.

| Order | Work group | Concrete starting cases and completion requirement |
| --- | --- | --- |
| G1 | Explicit missing outcomes | Complete the positive City of God free-prophet grant and replay. Distinguish enhancement/reformation grants from paid births, callback timing, faith debit and next cost. Close any other cases that currently have only failed commissioning attempts. |
| G2 | Ownership and effect lifetime | Māori upgrade/capture/naval movement branches; Moorish capture/transfer and actual production completion; Cuban capital transfer; Palmyran elimination/ownership freshwater; Mexican captured-city/owner reward boundaries. Check old/new owners, immediate result, the next normal owner turn, removal/non-repeat and persistence as applicable. |
| G3 | Unit effects and missions | Catalogue unique promotions, movement/terrain permissions, combat modifiers, kill/pillage rewards, healing, upgrade retention/loss and non-production missions. Cover actual outcomes, costs/consumption and legal rejection. Include Aksum ordinary healing rather than only a supplied healing delta, and applicable Crusader damage comparisons. |
| G4 | Buildings, improvements and economy | Quantify untested unique yields/resources, modifiers, worked-plot effects, construction restrictions and production/purchase costs. Verify actual settlement/completion, scaling/rounding and cache refresh after the relevant sale, pillage, capture, technology or era transition. Acquisition-only rows stay open until their effects are covered. |
| G5 | Trade, diplomacy and city-state traits | Nabataean Tomb sea/internal route outcomes; Phoenician Sailing/Trade Harbour effects; remaining Kilwan/Omani unique effects; the untested engine-backed trade/influence/annexation branches identified by G0. Observe actual creation, settlement, expiry/removal and ownership effects. Preserve existing proven diplomacy/espionage coverage. |
| G6 | Religion, policies, culture and great people | Remaining belief branches, conversions/pressure/yields, free-unit and great-person rewards, policy/era/ideology triggers and cultural effects. Test repeat/rejection and human/AI paths where dispatch or bookkeeping differs. Preserve closed Swiss/Yugoslav/Romanian cases as regressions, not new gaps. |
| G7 | Cross-system and UI closure | Resolve the residual economy/religion/espionage/persistence entries from the system ledger. Exercise new or changed player decisions through actual standard/EUI controls, including accept/cancel and saved-state continuation. Audit victory/post-victory evidence applicability; rerun affected paths rather than starting new campaigns. |

G0 must allocate every remaining engine-backed trait, including rows currently
labeled only “Unique mechanics pending,” among these groups. The examples above
are the initial concrete queue, not an exhaustive substitute for that allocation.
Run G1 and G2 first because they contain explicit missing outcomes and event-order
boundaries similar to previously confirmed defects. Within subsequent groups,
prioritize changed macOS bindings, cached state and distinct native branches.

For each required case:

- Specify the expected amount, state transition or permitted/rejected action
  before running it, using the original Lekmod rules and implementation. Record
  source/text discrepancies for investigation instead of choosing the observed
  result as the expectation.
- Use controlled prerequisites to reach the situation quickly, labeling all
  supplied resources, positions, technologies and previous progress. The actual
  event being tested must run normally; setting its final reward is not a test.
- Include a positive path and the relevant rejection/negative control. Test
  human and AI separately where timing, ownership or command routing differs.
  Include minor/barbarian/foreign ownership when the mechanic handles them.
- Exercise relevant boundaries and transitions, rather than every Cartesian
  combination. For saved state, perform exact scenario-fingerprint replay and
  verify source/copy bytes after asynchronous writing has finished. A rendered
  loaded world alone does not prove exact state persistence.
- Label evidence as offline/source check, scripted callback, native gameplay
  outcome, or actual mouse/keyboard action. One level cannot claim another.

A confirmed defect gets a minimal reproducer, focused fix, same-input retest,
relevant negative controls, affected-old-save test when state is persistent, and
a shared-path regression. Commit only those changes locally. Rebuild/repackage
when product bytes change; retain original failures and fix/package/run links.
A wrong oracle, unavailable binding or premature callback assertion is a harness
failure until a native product defect is demonstrated.

**Gate G1–G7:** all registered gameplay requirements pass or have explicitly
validated applicable evidence; no harness-blocked or product-failed cases remain.
Do not reopen closed catalogues wholesale. If gameplay testing encounters a
startup/crash/save failure, stop and diagnose it immediately; formal reliability
qualification still comes after gameplay closure.

## 3. Freeze the final candidate and finish gameplay regression

Build the completed product from clean committed source in a separate output
location, preserving existing binaries/evidence. Pin the host, GameCore, payload,
startup-library, archive, compatibility source and WSDLC revision/dependencies.
Verify signatures, ABI/export contracts and the complete artifact inventory.
Record standard/EUI configurations and any reproducible UI conversion hashes.

Run on those final bytes:

- The existing comprehensive plan: all81 functional assertions and16 exact
  checkpoint comparisons in one process.
- The compact regression plan for every product fix made during G1–G7, including
  retained affected saves. Batch independent fixtures rather than restarting the
  game for each assertion.
- Relevant runner, dispatcher, Lua/native binding, save integrity, startup ABI
  and WSDLC transaction tests. A whole installer-suite result must identify the
  exact tested revision, including the newer dependency/distribution changes.

Produce a dependency/evidence map showing which earlier passes remain applicable
because their implementation and data are unchanged. Changed shared code
invalidates affected consumers; rerun those consumers. An arbitrary successful
smoke test cannot validate unrelated old evidence.

**Gate F:** clean, identified candidate; all required gameplay/regression evidence
accounted for; no unexplained regression, crash, hang, synchronization or save
failure. Begin reliability only after this gate.

## 4. Reliability qualification on the frozen candidate

These are bounded operational tests, with a finite success sequence. They are
not another turn campaign or a statistical promise of zero possible failures.

| ID | Test | Required result |
| --- | --- | --- |
| R1 | Known startup reproducer | Repeat the preserved bad-inode database comparison using the installed correction. Real attachment/integrity/detachment succeeds; file/inode evidence, genuine errors and symlink controls remain preserved. Reference the retained uncorrected failure; do not repeatedly disable a proven fix. |
| R2 | Five fresh-process lifecycle cycles | Install once through WSDLC. Cycle1 uses the normal post-install cache state; cycles2–5 retain generated cache. Each loads the pinned fixture, saves a unique checkpoint, verifies state and exits0. Observe the installed correction and retain cache metadata. Stop at the first failure. The existing `lifecycle-playtest.py --cycles 5` supplies the bounded starting mechanism. |
| R3 | Persistence and UI continuity | In one session per required UI configuration, exercise manual-save/load, autosave load, quicksave/quickload, return-to-menu/reload, and the already-supported standard↔EUI continuation. Verify required state and file completeness. Use dedicated test files; preserve and restore the user's quicksave if its slot must be exercised. |
| R4 | Ordinary Steam launch | On the final package, actual Steam Play → ordinary Aspyr Play → loaded game → normal exit, with no test UI hooks, injected observer or custom launch options. Cover standard UI and the supported EUI configuration. Include a bounded fresh-game opening on the final package; reuse the accepted setup matrix for unaffected combinations. Verify loaded library identities and native exit status independently. |
| R5 | WSDLC installation and recovery | Disposable-bundle tests cover interrupted transactions, signatures/hashes, unknown host, modified content, missing/corrupt backups, Steam-restored detection and rollback. On the live installation, verify stock→final package→same-package reinstall→stock, original executable/GameCore restoration, startup-library removal, and save/settings/UI preservation. Do not damage the live install or force a Steam download to simulate recovery. |

Cold/warm in R2 refers to **cache state**, not a system reboot or Steam restart.
WSDLC's normal install-time invalidation is the only planned cache reset. Preserve
failure caches before restoration; do not delete healthy caches to get a pass.
R3/R4 can share a session when their instrumentation requirements are compatible.
Retries and preflight refusals remain separately classified; a retry never erases
a failed qualification run.

Review historical startup/shutdown incidents against known causes, regressions
and harness failures. Do not claim the stat ABI correction explains every earlier
incident. Any unresolved indication of an in-scope product reliability defect
blocks acceptance until resolved or explicitly adjudicated with evidence.

**Gate R:** R1–R5 pass on the frozen artifact, with no unexplained crash/hang,
startup255, synchronization failure, save corruption or restoration discrepancy.
After a product fix, pin a new candidate, rerun its affected gameplay checks and
restart the invalidated reliability sequence. No routine infinite repetition is
planned after a successful gate.

## 5. Final acceptance record and stopping rule

Create one current acceptance report linking the case register and raw evidence.
All of the following must be true:

- Every frozen in-scope gameplay requirement is closed with auditable evidence;
  there are no unexplained skips, harness blockers or known incorrect required
  gameplay outcomes. Cosmetic limitations are listed separately and cannot hide
  a gameplay failure.
- Final gameplay regression and R1–R5 pass on the identified candidate or have
  explicitly demonstrated unchanged-component applicability.
- Ordinary Steam launch is verified, WSDLC restores the original executable and
  core, and manual saves/quicksave, settings, UI files and original backups match
  their preservation records. Leave stock active and Civ V closed after testing.
- Historical reports retain their original verdicts; current status pages agree
  on the final artifact, fixes, tested environment and remaining exclusions.
- The clean checkout, local commits, reproducible commands, archive/component
  hashes and ignored evidence locations are documented. No push is performed.

The resulting claim is **accepted for the defined single-player scope on this
Mac and pinned configuration**. Multiplayer and other platforms stay explicitly
untested. Stop routine qualification once these gates pass; investigate only a
new defect or a changed requirement/artifact. Do not keep generating new tests
merely because more combinations are conceivable.

## Execution safeguards and progress reports

Work in the existing Lekmod checkout on local `main`; inspect and preserve any
external changes in it or WSDLC. Keep Steam/Civ V in the background by default.
Foreground testing and the approved native input fallback may be used for actual
UI cases, with game-identity, frontmost and unlock checks. Never launch locked,
unlock the machine, restart Docker, change Steam's channel or recreate schedules.
Never bypass synchronization checks, save-write completion or GameCore wait flags.
Restore temporary hooks/settings after every session and preserve manual saves
and Aspyr/canonical backups. Native crashes, protocol/sync errors and unsafe save
transitions abort the batch; isolated assertion failures remain failed and may
only be followed by a genuinely independent fixture under the existing supervisor.

Report after each batch: cases newly closed, cases still open, confirmed product
versus harness failures, fix/retest links, tested artifact, preservation result
and next batch. Track gameplay closure and reliability completion separately.
Do not use accumulated assertion count as a percentage of complete support.

**First execution deliverable:** the reconciled case register and ordered batch
list (G0), followed by the missing City of God outcome and ownership/lifetime
cases (G1/G2). No game launch is needed to prepare that register.
