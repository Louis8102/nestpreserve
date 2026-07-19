# Changelog

## Version 1.1.0 — 19 July 2026

- Avoid committing session or stack metadata before the first snapshot save
  succeeds.
- Validate required metadata before extending or restoring the stack.
- Return stack depth from preservation and restoration commands.
- Logically pop a successfully restored level before snapshot cleanup and
  register deletion failures for later cleanup.
- Clear active levels from the top down so a non-forced deletion failure leaves
  a contiguous valid stack.
- Report missing files, orphan snapshots, and machine-readable per-level status.
- Split the initial tests into core, failure, and frame suites.
- Add versioned per-session manifests for active and orphan snapshots.
- Add `nestrecover` for read-only listing/inspection and explicitly confirmed
  adoption after in-memory metadata loss.
- Reject manifests with invalid sessions, noncontiguous levels, unknown
  records, or snapshot paths that fail exact ownership validation.
- Verify real Windows snapshot and manifest deletion failures with open file
  handles.
- Verify cross-process recovery and cleanup using a manifest left by an earlier
  failed Stata run.
- Add `nesttransaction:` for automatic dataset rollback on wrapped-command
  success and failure.
- Propagate the original wrapped-command return code after successful rollback;
  use the rollback error only when restoration itself fails catastrophically.
- Unwind deeper NESTPRESERVE levels created inside a transaction and return to
  the frame where the transaction began.
- Recover transaction metadata from its manifest when wrapped code removes the
  in-memory globals.
- Document and test that arbitrary session objects and stored results are not
  transactionally rolled back or transparently preserved.
- Preserve `c(filename)`, `c(filedate)`, and `c(changed)` across ordinary
  `nestpreserve` and `nestrestore` operations.
- Add executable fidelity tests for types, formats, labels, notes,
  characteristics, sort order, `datasignature`, Unicode/`strL`, zero
  observations, `xtset`, `svyset`, and MI data.
- Document that manifest format 1 cannot reconstruct the source filename,
  file date, or changed flag after globals have been lost.
- Add repeatable small, medium, and large disk-snapshot benchmarks with multiple
  nesting depths, exact snapshot sizes, timings, cleanup assertions, and three
  trials per case.
- Confirm linear full-snapshot disk use and retain the disk baseline rather than
  introduce an unverified frame, memory, or differential fast path.
- Add discoverable help entries for every public command while retaining the
  consolidated main help file.
- Validate the package manifest with an isolated Stata `net install`, command
  discovery, help discovery, LIFO/transaction smoke test, and uninstall.
- Synchronize installation, examples, safety limits, command syntax, and
  validation guidance across README, consolidated help, per-command help,
  package metadata, GitHub materials, and release archives.

The full release-candidate suite was executed successfully in StataNow 19 on
19 July 2026. Version 1.1.0 is the build prepared in Stage 7.
