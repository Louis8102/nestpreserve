{smcl}
{* *! version 1.1.0 19jul2026}{...}
{title:nestclear}

{title:Syntax}

{p 8 16 2}
{cmd:nestclear} [{cmd:,} {opt force} {opt quiet}]

{pstd}
{cmd:nestclear} removes registered snapshots and stack metadata without
restoring a dataset.  Normal cleanup works from the top down and stops if a
file cannot be deleted.  {opt force} may clear metadata despite deletion or
metadata failures; use it only when that outcome is intentional.  {opt quiet}
suppresses confirmation output.

{pstd}
The command never deliberately deletes files not owned by the adopted or
active NESTPRESERVE session.  See {help nestpreserve} for cleanup guarantees.
