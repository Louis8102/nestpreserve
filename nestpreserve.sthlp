{smcl}
{* *! version 1.1.0 19jul2026}{...}
{vieweralsosee "preserve" "help preserve"}{...}
{vieweralsosee "save" "help save"}{...}
{vieweralsosee "frames" "help frames"}{...}
{title:Title}

{phang}
{bf:nestpreserve} — Stack-based nested preservation and restoration of the dataset in memory

{title:Installation}

{pstd}
NESTPRESERVE requires Stata 16 or newer.  After extracting the release ZIP,
install from its directory:

{phang2}{cmd:. net install nestpreserve, from("C:/path/to/extracted/nestpreserve") replace}

{pstd}
Verify installation with {cmd:which nestpreserve} and {cmd:help nestpreserve}.
The README in the distribution also documents installation from GitHub.

{title:Syntax}

{p 8 16 2}
{cmd:nestpreserve} [{cmd:,} {opt maxdepth(#)} {opt quiet}]

{p 8 16 2}
{cmd:nestrestore} [{cmd:,} {opt preserve} {opt quiet}]

{p 8 16 2}
{cmd:neststatus} [{cmd:,} {opt detail}]

{p 8 16 2}
{cmd:nestclear} [{cmd:,} {opt force} {opt quiet}]

{p 8 16 2}
{cmd:nestrecover} [{cmd:,} {opt list}]

{p 8 16 2}
{cmd:nestrecover using} {it:manifest}{cmd:,} {opt inspect}

{p 8 16 2}
{cmd:nestrecover using} {it:manifest}{cmd:,} {opt adopt}
{opt confirm(session-id)}

{p 8 16 2}
{cmd:nesttransaction} [{cmd:,} {opt quiet}]{cmd::} {it:command}

{title:Description}

{pstd}
{cmd:nestpreserve} saves the dataset currently in memory as the next level of a
last-in, first-out stack.  Unlike Stata's built-in {cmd:preserve}, additional
{cmd:nestpreserve} calls may be made before earlier levels are restored.

{pstd}
{cmd:nestrestore} restores the most recently preserved dataset.  By default,
the restored level is removed from the stack.  {cmd:nestrestore, preserve}
restores the top level but keeps that level available for another restoration.

{pstd}
{cmd:neststatus} reports the active stack.  {cmd:nestclear} deletes registered
snapshot files and removes stack metadata without restoring a dataset.

{pstd}
{cmd:nestrecover} lists session manifests, validates a specified manifest
without changing state, or explicitly adopts validated metadata after the
originating Stata session has ended.

{pstd}
{cmd:nesttransaction:} creates a dataset checkpoint, runs one Stata command,
and restores the checkpoint whether that command succeeds or fails.  After a
successful rollback it reissues the wrapped command's original return code.

{title:Options for nestpreserve}

{phang}
{opt maxdepth(#)} sets the maximum depth allowed by this call.  The default is
100.  The snapshot is not created if the requested level exceeds this limit.

{phang}
{opt quiet} suppresses the confirmation message.

{title:Options for nestrecover}

{phang}
{opt list} lists manifest filenames without adopting or deleting them.

{phang}
{opt inspect} validates the manifest header, session, record ordering, and
exact snapshot ownership paths without changing package globals.

{phang}
{opt adopt} rebuilds stack and orphan globals from a valid manifest.
{opt confirm(session-id)} must exactly match the inspected session.  Use this
only after confirming that the Stata process that created the manifest ended.

{title:Option for nesttransaction}

{phang}
{opt quiet} runs the wrapped command quietly.  Without this option the command
and its errors are displayed normally.

{title:Options for nestrestore}

{phang}
{opt preserve} restores the top snapshot but leaves it on the stack, analogous
to the repeated-restore behavior of {cmd:restore, preserve}.

{phang}
{opt quiet} suppresses the confirmation message.

{title:Options for neststatus}

{phang}
{opt detail} displays the frame, saved numbers of observations and variables,
file status, and file path for every level.

{title:Options for nestclear}

{phang}
{opt force} removes stack metadata even when a registered file cannot be
deleted or the depth metadata are invalid.  A file that cannot be deleted may
remain in the temporary directory.

{phang}
{opt quiet} suppresses the confirmation message.

{title:Frame behavior}

{pstd}
Each preservation level records the current frame.  {cmd:nestrestore} refuses
to restore a level from a different current frame.  Change back to the recorded
frame and run {cmd:nestrestore} again.  This conservative behavior prevents a
snapshot from silently replacing data in the wrong frame.

{title:What is and is not restored}

{pstd}
The commands preserve the dataset written by {cmd:save}.  They do not preserve
the complete Stata session.  In particular, they do not promise to restore
local or global macros, matrices, estimates, graphs, other frames, the working
directory, or stored {cmd:r()}, {cmd:e()}, and {cmd:s()} results.

{pstd}
For an ordinary active stack, preservation and restoration retain the source
dataset's {cmd:c(filename)}, {cmd:c(filedate)}, and {cmd:c(changed)} state.
Executable tests also cover observations, variables, storage types, formats,
variable and value labels, notes, characteristics, sort order, data labels,
{cmd:datasignature}, Unicode and {cmd:strL} values, {cmd:xtset}, {cmd:svyset},
and {cmd:mi} settings.  These are dataset-state guarantees, not session-state
guarantees.

{pstd}
Manifest format 1 does not store the source filename, file date, or changed
flag.  Consequently, after globals have been lost and a manifest is explicitly
adopted with {cmd:nestrecover}, the snapshot data remain recoverable but the
next restoration uses an empty filename/file date and an unchanged flag for
those three attributes.

{pstd}
{cmd:nesttransaction:} guarantees rollback of the dataset in the frame where
the transaction began.  It does not roll back scalars, matrices, macros,
estimates, graphs, other frames, or other Stata session objects.  It does not
promise transparent preservation of arbitrary wrapped-command {cmd:r()},
{cmd:e()}, or {cmd:s()} results.

{title:Performance and disk space}

{pstd}
Every active level is a complete Stata dataset file beneath {cmd:c(tmpdir)}.
Temporary disk demand is therefore approximately the saved dataset size times
the active nesting depth.  A 10 GB dataset preserved at five active levels may
require approximately 50 GB.  The package does not preflight free space.

{pstd}
Local StataNow 19 development benchmarks covered 10,000 observations at depth
10, 250,000 observations at depth 3, and 1,000,000 observations at depth 2.
Snapshot size equaled the independently saved dataset size in every case.
Timings depend strongly on storage and filesystem caching and are not portable
performance guarantees.  No frame-based or differential optimization is used.

{title:Examples}

{phang2}{cmd:. sysuse auto, clear}
{phang2}{cmd:. nestpreserve}
{phang2}{cmd:. keep if foreign == 0}
{phang2}{cmd:. nestpreserve}
{phang2}{cmd:. keep make price mpg}
{phang2}{cmd:. neststatus, detail}
{phang2}{cmd:. nestrestore}
{phang2}{cmd:. nestrestore}

{pstd}
The first {cmd:nestrestore} returns to the 52 domestic observations with all
original variables.  The second returns to the original 74-observation
dataset.  Official {cmd:preserve} would refuse the second preservation before
the first is restored; NESTPRESERVE maintains an explicit multi-level stack.

{pstd}
Temporarily reduce longitudinal data to one record per person:

{phang2}{cmd:. bysort id: egen complete = min(!missing(state))}
{phang2}{cmd:. nestpreserve}
{phang2}{cmd:. bysort id: keep if _n == 1}
{phang2}{cmd:. tabulate complete}
{phang2}{cmd:. nestrestore}

{pstd}
Automatically roll back the dataset changed by one command:

{phang2}{cmd:. sysuse auto, clear}
{phang2}{cmd:. nesttransaction: drop if foreign == 1}
{phang2}{cmd:. assert _N == 74}

{pstd}
Repeatedly return to the same saved state:

{phang2}{cmd:. nestpreserve}
{phang2}{cmd:. drop if missing(outcome)}
{phang2}{cmd:. nestrestore, preserve}
{phang2}{cmd:. keep if treatment == 1}
{phang2}{cmd:. nestrestore}

{title:Stored results}

{pstd}{cmd:nestpreserve} stores in {cmd:r()}:

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(level)}}new stack level{p_end}
{synopt:{cmd:r(depth)}}stack depth after preservation{p_end}
{synopt:{cmd:r(N)}}number of observations saved{p_end}
{synopt:{cmd:r(k)}}number of variables saved{p_end}
{synopt:{cmd:r(frame)}}frame saved{p_end}
{synopt:{cmd:r(filename)}}snapshot filename{p_end}
{synopt:{cmd:r(manifest)}}session manifest filename{p_end}

{pstd}{cmd:nestrestore} stores in {cmd:r()}:

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(level)}}level restored{p_end}
{synopt:{cmd:r(depth)}}stack depth after restoration{p_end}
{synopt:{cmd:r(N)}}number of observations restored{p_end}
{synopt:{cmd:r(k)}}number of variables restored{p_end}
{synopt:{cmd:r(preserved)}}1 if option {cmd:preserve} was specified; 0 otherwise{p_end}
{synopt:{cmd:r(delete_failed)}}1 if a popped snapshot could not be deleted{p_end}
{synopt:{cmd:r(manifest_failed)}}1 if post-restore manifest update failed{p_end}
{synopt:{cmd:r(frame)}}frame restored{p_end}
{synopt:{cmd:r(filename)}}snapshot filename{p_end}
{synopt:{cmd:r(manifest)}}session manifest filename, if retained{p_end}

{pstd}{cmd:neststatus} stores {cmd:r(depth)}, {cmd:r(valid)},
{cmd:r(files_ok)}, {cmd:r(orphan_count)}, per-level results, and
{cmd:r(session)}.  {cmd:nestclear} stores {cmd:r(cleared)},
{cmd:r(files_deleted)}, {cmd:r(files_missing)}, and
{cmd:r(delete_failures)} and {cmd:r(manifest_failures)}.

{pstd}{cmd:nestrecover} stores {cmd:r(adopted)}, {cmd:r(depth)},
{cmd:r(orphan_count)}, {cmd:r(files_ok)}, {cmd:r(session)}, and
{cmd:r(manifest)}.  In list mode it stores {cmd:r(count)} and manifest paths.

{pstd}{cmd:nesttransaction} stores {cmd:r(command_rc)},
{cmd:r(rollback_rc)}, {cmd:r(depth_before)}, {cmd:r(frame)}, and
{cmd:r(command)} after a successful wrapped command and rollback.  If the
wrapped command fails and rollback succeeds, its original nonzero return code
is reissued.  If rollback fails catastrophically, the rollback error is issued
and the wrapped command's return code is displayed.

{title:Technical notes}

{pstd}
Snapshot files are written beneath {cmd:c(tmpdir)}.  Stack metadata are stored
in globals whose names begin with {cmd:NESTPRESERVE_}.  Snapshot creation is
transactional at the metadata level: the stack is advanced only after
{cmd:save} succeeds.  Restoration is popped only after {cmd:use} succeeds.

{pstd}
After a successful restoration, failure to delete the no-longer-needed
snapshot does not recreate a false active level.  The file is registered as an
orphan for a later {cmd:nestclear}.  Without {cmd:force}, {cmd:nestclear}
works from the top down and stops on a deletion failure; any remaining active
levels still form a contiguous valid stack.  With {cmd:force}, metadata may be
removed even when a file cannot be deleted.

{pstd}
An abnormal Stata termination may leave snapshot files in the temporary
directory.  {cmd:nestclear} removes files registered in the active session but
does not touch foreign manifests.  {cmd:nestrecover} can validate and explicitly
adopt a manifest after metadata loss.

{pstd}
StataNow 19.5 exposes no supported process identifier, and tests show that
Stata file handles are not exclusive cross-process locks.  The package cannot
prove automatically that a foreign Stata session is dead and never
automatically deletes foreign-session files.

{title:Author}

{pstd}
Fan Lin

{title:License}

{pstd}
MIT License.  See {cmd:LICENSE} in the distribution.
