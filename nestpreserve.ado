*! version 1.1.0 19jul2026
program define nestpreserve, rclass
    version 16.0

    syntax [, MAXDepth(integer 100) QUIET]

    if `maxdepth' < 1 {
        di as error "maxdepth() must be a positive integer"
        exit 198
    }

    local had_stack = ("${NESTPRESERVE_depth}" != "")
    local depth 0
    if `had_stack' local depth = real("${NESTPRESERVE_depth}")
    if missing(`depth') | `depth' < 0 | `depth' != floor(`depth') {
        di as error "nestpreserve stack metadata are corrupted"
        di as error "invalid stack depth: ${NESTPRESERVE_depth}"
        exit 498
    }

    if `depth' > 0 & "${NESTPRESERVE_session}" == "" {
        di as error "nestpreserve stack metadata are corrupted: session identifier is missing"
        exit 498
    }

    if `depth' > 0 {
        forvalues level = 1/`depth' {
            local file_macro "NESTPRESERVE_file_`level'"
            local frame_macro "NESTPRESERVE_frame_`level'"
            local N_macro "NESTPRESERVE_N_`level'"
            local k_macro "NESTPRESERVE_k_`level'"
            local source_changed_macro "NESTPRESERVE_source_changed_`level'"
            local filename : copy global `file_macro'
            local frame : copy global `frame_macro'
            local saved_N : copy global `N_macro'
            local saved_k : copy global `k_macro'
            local source_changed : copy global `source_changed_macro'
            if `"`filename'"' == "" | `"`frame'"' == "" | ///
                    "`saved_N'" == "" | "`saved_k'" == "" | ///
                    "`source_changed'" == "" | ///
                    !inlist("`source_changed'", "0", "1") {
                di as error "nestpreserve stack metadata are corrupted at level `level'"
                exit 498
            }
        }
    }

    local next = `depth' + 1
    if `next' > `maxdepth' {
        di as error "maximum nesting depth exceeded"
        di as error "requested level `next'; maximum is `maxdepth'"
        exit 498
    }

    local session "${NESTPRESERVE_session}"
    if "`session'" == "" {
        local stamp = clock("`c(current_date)' `c(current_time)'", "DMYhms")
        local stamp_s = strtrim(string(`stamp', "%21.0f"))

        /* Generate a nonce without changing the user's RNG sequence. */
        local rngstate `"`c(rngstate)'"'
        local nonce = runiformint(100000000, 999999999)
        set rngstate `rngstate'
        local nonce_s = strtrim(string(`nonce', "%12.0f"))

        local session "`stamp_s'_`nonce_s'"
    }

    local frame `"`c(frame)'"'
    local source_filename `"`c(filename)'"'
    local source_filedate `"`c(filedate)'"'
    local source_changed = c(changed)
    local filename `"`c(tmpdir)'nestpreserve_`session'_`next'.dta"'

    /* Save first.  Stack metadata are committed only after save succeeds. */
    quietly save `"`filename'"'

    global NESTPRESERVE_session "`session'"
    global NESTPRESERVE_file_`next' `"`filename'"'
    global NESTPRESERVE_frame_`next' `"`frame'"'
    global NESTPRESERVE_N_`next' "`=_N'"
    global NESTPRESERVE_k_`next' "`=c(k)'"
    global NESTPRESERVE_source_filename_`next' `"`source_filename'"'
    global NESTPRESERVE_source_filedate_`next' `"`source_filedate'"'
    global NESTPRESERVE_source_changed_`next' `source_changed'
    global NESTPRESERVE_depth `next'

    /* Stata's own u_mi_save/u_mi_use use these internals to make a temporary
       save noninvasive with respect to filename, filedate, and changed. */
    global S_FN `"`source_filename'"'
    global S_FNDATE `"`source_filedate'"'
    mata: st_updata(`source_changed')

    capture noisily _nestpreserve_manifest, action(write)
    local manifest_rc = _rc
    if `manifest_rc' {
        macro drop NESTPRESERVE_file_`next'
        macro drop NESTPRESERVE_frame_`next'
        macro drop NESTPRESERVE_N_`next'
        macro drop NESTPRESERVE_k_`next'
        macro drop NESTPRESERVE_source_filename_`next'
        macro drop NESTPRESERVE_source_filedate_`next'
        macro drop NESTPRESERVE_source_changed_`next'
        if `depth' > 0 global NESTPRESERVE_depth `depth'
        else if `had_stack' global NESTPRESERVE_depth 0
        else {
            macro drop NESTPRESERVE_depth
            macro drop NESTPRESERVE_session
        }
        capture erase `"`filename'"'
        exit `manifest_rc'
    }

    return scalar level = `next'
    return scalar depth = `next'
    return scalar N = _N
    return scalar k = c(k)
    return local frame `"`frame'"'
    return local filename `"`filename'"'
    return local manifest "${NESTPRESERVE_manifest}"

    if "`quiet'" == "" {
        di as text "dataset preserved at level " as result `next' ///
            as text " (" as result _N as text " observations, " ///
            as result c(k) as text " variables)"
    }
end
