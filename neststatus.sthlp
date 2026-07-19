{smcl}
{* *! version 1.1.0 19jul2026}{...}
{title:neststatus}

{title:Syntax}

{p 8 16 2}
{cmd:neststatus} [{cmd:,} {opt detail}]

{pstd}
{cmd:neststatus} reports the active NESTPRESERVE stack and snapshot status.
{opt detail} includes frames, paths, saved observation/variable counts, and
file availability.  Machine-readable status is returned in {cmd:r()}.

{pstd}
See {help nestpreserve} for returned results and corruption behavior.
