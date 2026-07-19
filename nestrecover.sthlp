{smcl}
{* *! version 1.1.0 19jul2026}{...}
{title:nestrecover}

{title:Syntax}

{p 8 16 2}
{cmd:nestrecover} [{cmd:,} {opt list}]

{p 8 16 2}
{cmd:nestrecover using} {it:manifest}{cmd:,} {opt inspect}

{p 8 16 2}
{cmd:nestrecover using} {it:manifest}{cmd:,} {opt adopt}
{opt confirm(session-id)}

{pstd}
{cmd:nestrecover} lists, inspects, or explicitly adopts a validated
NESTPRESERVE session manifest.  Listing and inspection do not change package
state.  Adoption requires the exact session identifier and must be used only
after confirming that the originating Stata session ended.

{pstd}
The command never automatically adopts or deletes a foreign session.  Manifest
format 1 cannot reconstruct the source filename, file date, or changed flag
after their globals have been lost.

{pstd}
See {help nestpreserve} for the ownership policy and returned results.
