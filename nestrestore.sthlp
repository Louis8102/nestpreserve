{smcl}
{* *! version 1.1.0 19jul2026}{...}
{title:nestrestore}

{title:Syntax}

{p 8 16 2}
{cmd:nestrestore} [{cmd:,} {opt preserve} {opt quiet}]

{pstd}
{cmd:nestrestore} restores the most recent NESTPRESERVE dataset snapshot and,
by default, pops that level.  {opt preserve} retains the level for another
restoration.  {opt quiet} suppresses confirmation output.  Restoration is
strictly LIFO and must occur in the frame where the level was saved.

{pstd}
A failed {cmd:use} does not pop the stack.  If deletion fails after successful
restoration, the logical pop remains valid and the file is registered for
later cleanup.

{pstd}
See {help nestpreserve} for stored results, examples, and limitations.
