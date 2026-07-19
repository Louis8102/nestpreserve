*! version 1.1.0 19jul2026
program define neststatus, rclass
    version 16.0

    syntax [, DETAIL]

    if "${NESTPRESERVE_depth}" == "" {
        di as text "no active nestpreserve stack"
        local orphan_count = real("${NESTPRESERVE_orphan_count}")
        if missing(`orphan_count') local orphan_count 0
        if `orphan_count' > 0 {
            di as error "registered orphan snapshots awaiting cleanup: `orphan_count'"
        }
        return scalar depth = 0
        return scalar valid = 1
        return scalar files_ok = 1
        return scalar orphan_count = `orphan_count'
        return local session "${NESTPRESERVE_session}"
        exit
    }

    local depth = real("${NESTPRESERVE_depth}")
    if missing(`depth') | `depth' < 0 | `depth' != floor(`depth') {
        di as error "nestpreserve stack metadata are corrupted"
        exit 498
    }

    di as text "active nesting depth: " as result `depth'
    di as text "session identifier:  " as result "${NESTPRESERVE_session}"

    if `depth' > 0 & "${NESTPRESERVE_session}" == "" {
        di as error "nestpreserve stack metadata are corrupted: session identifier is missing"
        exit 498
    }

    local all_exist 1
    if `depth' > 0 {
      forvalues level = 1/`depth' {
        local file_macro "NESTPRESERVE_file_`level'"
        local frame_macro "NESTPRESERVE_frame_`level'"
        local N_macro "NESTPRESERVE_N_`level'"
        local k_macro "NESTPRESERVE_k_`level'"

        local filename : copy global `file_macro'
        local frame : copy global `frame_macro'
        local saved_N : copy global `N_macro'
        local saved_k : copy global `k_macro'

        if `"`filename'"' == "" | `"`frame'"' == "" | ///
                "`saved_N'" == "" | "`saved_k'" == "" {
            di as error "nestpreserve stack metadata are corrupted at level `level'"
            exit 498
        }

        tempname exists
        mata: st_numscalar("`exists'", fileexists(st_local("filename")))
        local file_ok = scalar(`exists')
        if !`file_ok' local all_exist 0

        return local file_`level' `"`filename'"'
        return local frame_`level' `"`frame'"'
        return scalar N_`level' = real("`saved_N'")
        return scalar k_`level' = real("`saved_k'")
        return scalar file_ok_`level' = `file_ok'

        if "`detail'" == "" {
            if `file_ok' {
                di as text "level " as result `level' as text ": frame " ///
                    as result `"`frame'"' as text ", file " as result "available"
            }
            else {
                di as text "level " as result `level' as text ": frame " ///
                    as result `"`frame'"' as text ", file " as error "missing"
            }
        }
        else {
            di as text "level " as result `level'
            di as text "  frame:        " as result `"`frame'"'
            di as text "  observations: " as result `"`saved_N'"'
            di as text "  variables:    " as result `"`saved_k'"'
            if `file_ok' {
                di as text "  file status:  " as result "available"
            }
            else {
                di as text "  file status:  " as error "missing"
            }
            di as text "  file:         " as result `"`filename'"'
        }
      }
    }

    return scalar depth = `depth'
    return scalar valid = 1
    return scalar files_ok = `all_exist'
    local orphan_count = real("${NESTPRESERVE_orphan_count}")
    if missing(`orphan_count') local orphan_count 0
    return scalar orphan_count = `orphan_count'
    return local session "${NESTPRESERVE_session}"
end
