# NESTPRESERVE

`nestpreserve` provides a disk-backed, last-in-first-out stack for nested
preservation and restoration of the dataset currently in memory.

Requires Stata 16 or newer.

## Installation

### From a downloaded release

Download and extract `nestpreserve_1.1.0.zip`, then point Stata to the extracted
directory:

```stata
net install nestpreserve, from("C:/path/to/extracted/nestpreserve") replace
```

Use forward slashes in the Stata path on Windows. Verify the installation:

```stata
which nestpreserve
help nestpreserve
```

### From a GitHub repository

After the repository is published, replace `OWNER` with its GitHub account or
organization:

```stata
net install nestpreserve, from("https://raw.githubusercontent.com/OWNER/nestpreserve/main") replace
```

To uninstall:

```stata
ado uninstall nestpreserve
```

## Commands

```stata
nestpreserve [, maxdepth(#) quiet]
nestrestore [, preserve quiet]
neststatus [, detail]
nestclear [, force quiet]
nestrecover [, list]
nestrecover using manifest, inspect
nestrecover using manifest, adopt confirm(session-id)
nesttransaction [, quiet]: command
```

| Command | Purpose |
|---|---|
| `nestpreserve` | Push the current dataset onto the LIFO stack. |
| `nestrestore` | Restore and pop the most recent snapshot. |
| `nestrestore, preserve` | Restore the top snapshot without popping it. |
| `neststatus, detail` | Inspect levels, frames, paths, and file availability. |
| `nestclear` | Delete snapshots and clear stack metadata without restoring. |
| `nestrecover` | List, inspect, or explicitly adopt a validated manifest. |
| `nesttransaction: command` | Run one command and roll back its dataset changes. |

## Basic example

```stata
sysuse auto, clear
nestpreserve
keep if foreign == 0
nestpreserve
keep make price mpg
neststatus, detail
nestrestore
nestrestore
```

The first `nestrestore` returns to the 52 domestic observations with all
original variables. The second returns to the original 74-observation dataset.
Stata's official `preserve` cannot be called a second time before `restore`;
NESTPRESERVE provides the explicit multi-level stack.

Repeatedly restoring the same checkpoint:

```stata
sysuse auto, clear
nestpreserve
drop if missing(price)
nestrestore, preserve
keep if foreign == 1
nestrestore
```

## Transaction example

`nesttransaction:` always attempts to restore its dataset checkpoint and, when
rollback succeeds, propagates the wrapped command's return code:

```stata
sysuse auto, clear
nesttransaction: drop if foreign == 1
assert _N == 74
```

It rolls back dataset changes only. Scalars, matrices, macros, estimates,
graphs, other frames, and arbitrary `r()`, `e()`, or `s()` results are not
transactionally restored.

## Status, cleanup, and recovery

```stata
neststatus, detail
nestclear
nestclear, force
nestrecover, list
```

Use `force` only when you intentionally want metadata cleared despite a file
deletion failure. `nestrecover` never automatically deletes or adopts a foreign
session. Inspect a manifest first, then adopt only after confirming that its
originating Stata session has ended; see `help nestpreserve` for the guarded
syntax.

## Core guarantees

- A new stack level is committed only after `save` succeeds.
- A stack level is removed only after `use` succeeds.
- Restoration is last-in, first-out.
- Every level is tied to the frame in which it was created.
- `nestrestore, preserve` restores without popping the level.
- A successful restore is logically popped even if later file deletion fails;
  the undeleted snapshot is registered for later cleanup.
- Non-forced cleanup proceeds from the top down so any remaining stack stays
  contiguous after a deletion failure.
- A versioned manifest records active levels and orphan snapshots.
- Lost in-memory metadata can be inspected and explicitly adopted from a
  validated manifest after the originating Stata session has ended.
- `nesttransaction:` restores its dataset checkpoint whether the wrapped
  command succeeds or fails and reissues the wrapped command's return code.

## Scope

The package restores datasets, not complete Stata sessions. It does not promise
to restore macros, matrices, estimates, graphs, other frames, working-directory
state, or stored results.

For an ordinary active stack, real Stata tests verify preservation of the source
filename, file date, changed flag, labels, formats, notes, characteristics,
sort order, `datasignature`, Unicode/`strL` values, `xtset`, `svyset`, and MI
settings. These are dataset-state guarantees only.

Manifest format 1 does not record the source filename, file date, or changed
flag. After lost globals are explicitly recovered by adopting a manifest, the
snapshot data remain recoverable, but those three attributes fall back to an
empty filename/file date and an unchanged flag on restoration.

StataNow 19.5 does not expose a process identifier and Stata file handles are
not exclusive across processes. NESTPRESERVE therefore never automatically
deletes a foreign-session manifest. Recovery requires the exact session ID and
an explicit `adopt` request.

`nesttransaction:` guarantees dataset rollback and return-code propagation,
not transparent preservation of arbitrary `r()`, `e()`, or `s()` results.
Scalars, matrices, globals, estimates, graphs, and other frames are outside the
transaction and may survive or change.

Each active level is a complete `.dta` snapshot. Peak temporary disk demand is
approximately the saved dataset size multiplied by stack depth. Stage 6 local
benchmarks and their limitations are recorded in
[`docs/stage6_performance.md`](docs/stage6_performance.md). No memory/frame or
differential fast path is enabled in this build.

## Development status

Stages 2 through 6 have been exercised by the automated suite in a real
StataNow 19 installation. Version 1.1.0 is the Stage 7 release candidate. Its
package manifest has also passed an isolated `net install`/uninstall test.

## Reproducing validation

The GitHub-ready repository includes license-free package validation and a full
real-Stata runner:

```powershell
./scripts/validate-package.ps1
./scripts/run-stata-tests.ps1 -StataPath "C:\Program Files\StataNow19\StataMP-64.exe"
```

See `VALIDATION.md` in the GitHub repository for GitHub Actions and self-hosted
runner instructions. Ordinary GitHub-hosted runners cannot execute proprietary
Stata unless a licensed installation is separately provided.
