{smcl}
{* *! version 1.1.0 19jul2026}{...}
{title:nesttransaction}

{title:Syntax}

{p 8 16 2}
{cmd:nesttransaction} [{cmd:,} {opt quiet}]{cmd::} {it:command}

{pstd}
{cmd:nesttransaction:} runs one command and then rolls back its dataset
changes, whether the wrapped command succeeds or fails.  After successful
rollback it propagates the wrapped command's return code.  {opt quiet} runs the
wrapped command quietly.

{pstd}
The guarantee covers the dataset in the transaction's starting frame.  It does
not promise rollback of scalars, matrices, macros, estimates, graphs, other
frames, or transparent preservation of arbitrary {cmd:r()}, {cmd:e()}, and
{cmd:s()} results.

{pstd}
See {help nestpreserve} for examples, returned results, and failure behavior.
