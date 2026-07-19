*! version 1.1.0 19jul2026
program define nestrecover, rclass
    version 16.0

    syntax [using/] [, LIST INSPECT ADOPT CONFIRM(string)]

    local modes = ("`list'" != "") + ("`inspect'" != "") + ("`adopt'" != "")
    if `modes' == 0 local list "list"
    if `modes' > 1 {
        di as error "specify only one of list, inspect, or adopt"
        exit 198
    }

    if "`list'" != "" {
        if `"`using'"' != "" {
            di as error "using is not allowed with list"
            exit 198
        }
        local tmpdir `"`c(tmpdir)'"'
        mata: np_f = dir(st_local("tmpdir"), "files", ///
            "nestpreserve_*.manifest"); ///
            st_local("np_manifests", rows(np_f) == 0 ? "" : ///
            invtokens(vec(np_f)'))
        local count 0
        foreach filename of local np_manifests {
            local ++count
            di as text `"`tmpdir'`filename'"'
            return local manifest_`count' `"`tmpdir'`filename'"'
        }
        return scalar count = `count'
        exit
    }

    if `"`using'"' == "" {
        di as error "a manifest filename is required"
        exit 198
    }
    confirm file `"`using'"'

    file open np_recover_in using `"`using'"', read text
    file read np_recover_in line
    if r(eof) | `"`line'"' != "NESTPRESERVE_MANIFEST|1" {
        file close np_recover_in
        di as error "not a supported NESTPRESERVE manifest"
        exit 498
    }

    file read np_recover_in line
    if r(eof) | substr(`"`line'"', 1, 8) != "SESSION|" {
        file close np_recover_in
        di as error "manifest session record is missing or malformed"
        exit 498
    }
    local session = substr(`"`line'"', 9, .)
    if !regexm("`session'", "^[0-9]+_[0-9]+$") {
        file close np_recover_in
        di as error "manifest session identifier is invalid"
        exit 498
    }

    local norm_using = lower(subinstr(`"`using'"', "\", "/", .))
    local expected_manifest `"`c(tmpdir)'nestpreserve_`session'.manifest"'
    local norm_expected = lower(subinstr(`"`expected_manifest'"', "\", "/", .))
    if `"`norm_using'"' != `"`norm_expected'"' {
        file close np_recover_in
        di as error "manifest path does not match its declared session"
        exit 498
    }

    local depth 0
    local orphan_count 0
    local files_ok 1
    file read np_recover_in line
    while !r(eof) {
        if `"`line'"' != "" {
            tokenize `"`line'"', parse("|")
            if "`1'" == "ACTIVE" {
                local level = real("`3'")
                local saved_N = real("`7'")
                local saved_k = real("`9'")
                local filename `"`11'"'
                if missing(`level') | `level' != `depth' + 1 | ///
                        missing(`saved_N') | missing(`saved_k') | `"`5'"' == "" {
                    file close np_recover_in
                    di as error "manifest contains malformed or noncontiguous active levels"
                    exit 498
                }
                local expected_file `"`c(tmpdir)'nestpreserve_`session'_`level'.dta"'
                local norm_file = lower(subinstr(`"`filename'"', "\", "/", .))
                local norm_expected_file = lower(subinstr(`"`expected_file'"', "\", "/", .))
                if `"`norm_file'"' != `"`norm_expected_file'"' {
                    file close np_recover_in
                    di as error "manifest snapshot path failed ownership validation"
                    exit 498
                }
                local ++depth
                local active_frame_`level' `"`5'"'
                local active_N_`level' `saved_N'
                local active_k_`level' `saved_k'
                local active_file_`level' `"`filename'"'
                capture confirm file `"`filename'"'
                local active_ok_`level' = (_rc == 0)
                if !`active_ok_`level'' local files_ok 0
            }
            else if "`1'" == "ORPHAN" {
                local index = real("`3'")
                local erase_rc = real("`5'")
                local filename `"`7'"'
                if missing(`index') | `index' != `orphan_count' + 1 | ///
                        missing(`erase_rc') {
                    file close np_recover_in
                    di as error "manifest contains malformed orphan records"
                    exit 498
                }
                local expected_prefix `"`c(tmpdir)'nestpreserve_`session'_"'
                local norm_file = lower(subinstr(`"`filename'"', "\", "/", .))
                local norm_prefix = lower(subinstr(`"`expected_prefix'"', "\", "/", .))
                if substr(`"`norm_file'"', 1, length(`"`norm_prefix'"')) != ///
                        `"`norm_prefix'"' | substr(`"`norm_file'"', -4, 4) != ".dta" {
                    file close np_recover_in
                    di as error "manifest orphan path failed ownership validation"
                    exit 498
                }
                local ++orphan_count
                local orphan_file_`orphan_count' `"`filename'"'
                local orphan_rc_`orphan_count' `erase_rc'
            }
            else {
                file close np_recover_in
                di as error "manifest contains an unknown record type"
                exit 498
            }
        }
        file read np_recover_in line
    }
    file close np_recover_in

    if `depth' == 0 & `orphan_count' == 0 {
        di as error "manifest contains no recoverable records"
        exit 498
    }

    if "`adopt'" != "" {
        if "${NESTPRESERVE_depth}" != "" | "${NESTPRESERVE_session}" != "" {
            di as error "an active NESTPRESERVE session already exists"
            exit 498
        }
        if "`confirm'" != "`session'" {
            di as error "adoption requires confirm(`session')"
            di as error "confirm only after verifying that the originating Stata session ended"
            exit 198
        }
        global NESTPRESERVE_session "`session'"
        global NESTPRESERVE_manifest `"`using'"'
        if `depth' > 0 {
            forvalues level = 1/`depth' {
                global NESTPRESERVE_file_`level' `"`active_file_`level''"'
                global NESTPRESERVE_frame_`level' `"`active_frame_`level''"'
                global NESTPRESERVE_N_`level' "`active_N_`level''"
                global NESTPRESERVE_k_`level' "`active_k_`level''"
                global NESTPRESERVE_source_filename_`level' ""
                global NESTPRESERVE_source_filedate_`level' ""
                global NESTPRESERVE_source_changed_`level' 0
            }
            global NESTPRESERVE_depth `depth'
        }
        if `orphan_count' > 0 {
            forvalues orphan = 1/`orphan_count' {
                global NESTPRESERVE_orphan_file_`orphan' `"`orphan_file_`orphan''"'
                global NESTPRESERVE_orphan_rc_`orphan' "`orphan_rc_`orphan''"
            }
            global NESTPRESERVE_orphan_count `orphan_count'
        }
        return scalar adopted = 1
        di as error "warning: foreign manifest adopted by explicit session confirmation"
    }
    else return scalar adopted = 0

    return scalar depth = `depth'
    return scalar orphan_count = `orphan_count'
    return scalar files_ok = `files_ok'
    return local session "`session'"
    return local manifest `"`using'"'
end
