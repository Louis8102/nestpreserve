*! version 1.1.0 19jul2026
program define nesttransaction, rclass properties(prefix)
    version 16.0
    set prefix nesttransaction

    capture _on_colon_parse `0'
    if _rc | `"`s(after)'"' == "" {
        di as error "nesttransaction requires a command after a colon"
        exit 198
    }
    local command `"`s(after)'"'
    local 0 `"`s(before)'"'
    syntax [, QUIET]

    local depth_before 0
    if "${NESTPRESERVE_depth}" != "" {
        local depth_before = real("${NESTPRESERVE_depth}")
        if missing(`depth_before') | `depth_before' < 0 | ///
                `depth_before' != floor(`depth_before') {
            di as error "cannot start transaction: stack metadata are corrupted"
            exit 498
        }
    }
    local original_frame `"`c(frame)'"'

    quietly nestpreserve
    local transaction_level = r(level)
    local transaction_session `"${NESTPRESERVE_session}"'
    local transaction_manifest `"${NESTPRESERVE_manifest}"'

    if "`quiet'" == "" capture noisily `command'
    else capture quietly `command'
    local command_rc = _rc

    /* clear all or manual macro deletion may remove the in-memory stack while
       leaving the committed transaction manifest available for recovery. */
    if "${NESTPRESERVE_depth}" == "" & ///
            `"`transaction_manifest'"' != "" {
        capture confirm file `"`transaction_manifest'"'
        if !_rc {
            capture quietly nestrecover using `"`transaction_manifest'"', ///
                adopt confirm(`transaction_session')
        }
    }

    local rollback_rc 0
    local current_depth = real("${NESTPRESERVE_depth}")
    if missing(`current_depth') | `current_depth' < `transaction_level' {
        local rollback_rc 498
    }

    while !`rollback_rc' & `current_depth' > `transaction_level' {
        local frame_macro "NESTPRESERVE_frame_`current_depth'"
        local top_frame : copy global `frame_macro'
        if `"`top_frame'"' == "" {
            local rollback_rc 498
        }
        else {
            capture frame change `top_frame'
            if _rc local rollback_rc = _rc
            else {
                capture quietly nestrestore
                if _rc local rollback_rc = _rc
            }
        }
        if !`rollback_rc' {
            local current_depth = real("${NESTPRESERVE_depth}")
            if missing(`current_depth') local current_depth 0
        }
    }

    if !`rollback_rc' {
        capture frame change `original_frame'
        if _rc local rollback_rc = _rc
        else {
            capture quietly nestrestore
            if _rc local rollback_rc = _rc
        }
    }

    if `rollback_rc' {
        di as error "nesttransaction could not restore its dataset checkpoint"
        di as error "wrapped command return code was `command_rc'"
        exit `rollback_rc'
    }

    return scalar command_rc = `command_rc'
    return scalar rollback_rc = 0
    return scalar depth_before = `depth_before'
    return local frame `"`original_frame'"'
    return local command `"`command'"'

    if `command_rc' exit `command_rc'
end
