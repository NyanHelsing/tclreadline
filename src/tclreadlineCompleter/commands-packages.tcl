# -*- tclsh -*-
# http, msgcat, safe interpreter, and package-adjacent completers.
# Sourced by ../tclreadlineCompleter.tcl.

namespace eval tclreadline {
    proc http::complete(config) {text start end line pos mod} {
        set prev [PreviousWord $start $line]
        switch -- $prev {
            -accept      { return [DisplayHints <mimetypes>] }
            -proxyhost   { return [CompleteFromList $text [HostList]] }
            -proxyport   { return [DisplayHints <number>] }
            -proxyfilter { return [CompleteFromList $text [CommandCompletion $text]] }
            -useragent   { return [DisplayHints <string>] }
            default      {
                return [CompleteFromList $text \
                            [RemoveUsedOptions $line \
                                 {-accept -proxyhost -proxyport
                                  -proxyfilter -useragent}]]
            }
        }
        return ""
    }

    proc http::complete(geturl) {text start end line pos mod} {
        switch -- $pos {
            1       { return [DisplayHints <url>] }
            default {
                set prev [PreviousWord $start $line]
                switch -- $prev {
                    -blocksize { return [DisplayHints <size>] }
                    -channel   { return [ChannelId $text] }
                    -command   -
                    -handler   -
                    -progress  {
                        return [CompleteFromList $text [CommandCompletion $text]]
                    }
                    -headers   { return [DisplayHints <keyvaluelist>] }
                    -query     { return [DisplayHints <query>] }
                    -timeout   { return [DisplayHints <milliseconds>] }
                    -validate  { return [CompleteBoolean $text] }
                    default    {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-blocksize -channel -command
                                          -handler -headers -progress
                                          -query -timeout -validate}]]
                    }
                }
            }
        }
        return ""
    }

    proc http::complete(formatQuery) {text start end line pos mod} {
        switch -- $pos {
            1       { return [DisplayHints <key>] }
            2       { return [DisplayHints <value>] }
            default {
                switch [expr {$pos % 2}] {
                    0 { return [DisplayHints ?value?] }
                    1 { return [DisplayHints ?key?] }
                }
            }
        }
        return ""
    }

    proc http::complete(reset) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <token>] }
            2 { return [DisplayHints ?why?] }
        }
        return ""
    }

    # the unknown proc handles the rest
    #
    proc http::complete(tclreadline_complete_unknown) {text start end line pos mod} {
        set cmd [Lindex $line 0]
        regsub -all {^.*::} $cmd "" cmd
        switch -- $pos {
            1 {
                switch -- $cmd {
                    reset   -
                    wait    -
                    data    -
                    status  -
                    code    -
                    size    -
                    cleanup {
                        return [DisplayHints <token>]
                    }
                }
            }
        }
        return ""
    }

    # --- END OF HTTP PACKAGE ---

    proc complete(if) {text start end line pos mod} {
        # we don't offer the completion `then':
        # it's optional, more difficult to parse
        # and who uses it anyway?
        #
        switch -- $pos {
            1 -
            2 {
                return [BraceOrCommand $text $start $end $line $pos $mod]
            }
            default {
                set prev [PreviousWord $start $line]
                switch -- $prev {
                    then    -
                    else    -
                    elseif  {
                        return [BraceOrCommand $text $start \
                                    $end $line $pos $mod]
                    }
                    default {
                        if {-1 == [lsearch [ProperList $line] else]} {
                            return [CompleteFromList $text {else elseif}]
                        }
                    }
                }
            }
        }
        return ""
    }

    proc complete(incr) {text start end line pos mod} {
        switch -- $pos {
            1 {
                set matches [uplevel [info level] info vars ${mod}*]
                set integers ""
                # check for integers
                #
                foreach match $matches {
                    if {[uplevel [info level] array exists $match]} {
                        continue
                    }
                    if {[regexp {^[0-9]+$} [uplevel [info level] set $match]]} {
                        lappend integers $match
                    }
                }
                return [CompleteFromList $text $integers]
            }
            2 { return [DisplayHints ?increment?] }
        }
        return ""
    }

    proc complete(info) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        set tcloo 0
        if {![catch {package present TclOO 1.0}]} {
            set tcloo 1
        }
        switch -- $pos {
            1 {
                set cmds {
                    args body cmdcount commands complete default exists
                    globals hostname level library loaded locals
                    nameofexecutable patchlevel procs script
                    sharedlibextension tclversion vars
                }
                if {$tcloo} {
                    lappend cmds class object
                }
                return [CompleteFromList $text [lsort $cmds]]
            }
            2 {
                if {$tcloo && ($cmd eq "class")} {
                    set subcmds {
                        call constructor definition destructor filters forward
                        instances methods methodtype mixins subclasses
                        superclasses variables 
                    }
                    return [CompleteFromList $text $subcmds]
                } elseif {$tcloo && ($cmd eq "object")} {
                    set subcmds {
                        call class definition filters forward isa methods
                        methodtype mixins namespace variables vars
                    }
                    return [CompleteFromList $text $subcmds]
                } else {
                    switch -- $cmd {
                        args     -
                        body     -
                        default  -
                        procs    {
                            return [complete(proc) $text 0 0 $line 1 $mod]
                        }
                        complete { return [DisplayHints <command>] }
                        level    { return [DisplayHints ?number?] }
                        loaded   { return [DisplayHints ?interp?] }
                        commands -
                        exists   -
                        globals  -
                        locals   -
                        vars     {
                            if {"exists" == $cmd} {
                                set do vars
                            } else {
                                set do $cmd
                            }
                            return [CompleteFromList $text \
                                        [uplevel [info level] info $do]]
                        }
                    }
                }
            }
            3 {
                if {$tcloo && ($cmd eq "object")} {
                    return [VarCompletion $text]
                } else {
                    set proc [Lindex $line 2]
                    return [CompleteFromList $text \
                                [uplevel [info level] info args $proc]]
                }
            }
            4 {
                return [VarCompletion $text]
            }
        }
        return ""
    }

    proc complete(interp) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        switch -- $pos {
            1 {
                set cmds {
                    alias aliases create delete eval exists expose hide hidden
                    invokehidden issafe marktrusted share slaves target transfer
                }
                return [TryFromList $text $cmds]
            }
            2 {
                switch -- $cmd {
                    create {
                        set cmds [RemoveUsedOptions $line {-save --} {--}]
                        if {[llength $cmds]} {
                            return [CompleteFromList $text "$cmds ?path?"]
                        } else {
                            return [DisplayHints ?path?]
                        }
                    }

                    eval         -
                    exists       -
                    expose       -
                    hide         -
                    hidden       -
                    invokehidden -
                    marktrusted  -
                    target       { return [CompleteFromList $text [interp slaves]] }

                    aliases -
                    delete  -
                    issafe  -
                    slaves  { return [CompleteFromList $text [interp slaves]] }

                    alias    -
                    share    -
                    transfer { return [DisplayHints <srcPath>] }
                }
            }
            3 {
                switch -- $cmd {
                    alias { return [DisplayHints <srcCmd>] }

                    create {
                        set cmds [RemoveUsedOptions $line {-save --} {--}]
                        if {[llength $cmds]} {
                            return [CompleteFromList $text "$cmds ?path?"]
                        } else {
                            return [DisplayHints ?path?]
                        }
                    }

                    eval   { return [DisplayHints <arg>] }
                    delete { return [CompleteFromList $text [interp slaves]] }

                    expose { return [DisplayHints <hiddenName>] }
                    hide   { return [DisplayHints <exposedCmdName>] }

                    invokehidden {
                        return [CompleteFromList $text \
                                    {?-global? <hiddenCmdName>}]
                    }

                    target { return [DisplayHints <alias>] }

                    exists      {}
                    hidden      {}
                    marktrusted {}
                    aliases     {}
                    issafe      {}
                    slaves      {}

                    share    -
                    transfer { return [ChannelId $text] }
                }
            }
            4 {
                switch -- $cmd {
                    alias { return [DisplayHints <targetPath>] }
                    eval  { return [DisplayHints ?arg?] }

                    invokehidden {
                        return [CompleteFromList $text {<hiddenCmdName> ?arg?}]
                    }

                    create {
                        set cmds [RemoveUsedOptions $line {-save --} {--}]
                        if {[llength $cmds]} {
                            return [CompleteFromList $text "$cmds ?path?"]
                        } else {
                            return [DisplayHints ?path?]
                        }
                    }

                    expose { return [DisplayHints ?exposedCmdName?] }
                    hide   { return [DisplayHints ?hiddenCmdName?] }

                    share    -
                    transfer { return [CompleteFromList $text [interp slaves]] }
                }
            }
            5 {
                switch -- $cmd {
                    alias        { return [DisplayHints <targetCmd>] }
                    invokehidden -
                    eval         { return [DisplayHints ?arg?] }

                    expose { return [DisplayHints ?exposedCmdName?] }
                    hide   { return [DisplayHints ?hiddenCmdName?] }

                    share    -
                    transfer { return [CompleteFromList $text [interp slaves]] }
                }
            }
        }
        return ""
    }

    proc complete(join) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <list>] }
            2 { return [DisplayHints ?joinString?] }
        }
        return ""
    }

    proc complete(lappend) {text start end line pos mod} {
        switch -- $pos {
            1       { return [VarCompletion $text] }
            default { return [TryFromList $text ?value?] }
        }
        return ""
    }

    # the following routines are described in the
    # `library' man page.
    # --- LIBRARY ---

    proc complete(auto_execok) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <cmd>] }
        }
        return ""
    }

    proc complete(auto_load) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <cmd>] }
        }
        return ""
    }

    proc complete(auto_mkindex) {text start end line pos mod} {
        switch -- $pos {
            1       { return "" }
            default { return [DisplayHints ?pattern?] }
        }
        return ""
    }

    # proc complete(auto_reset) {text start end line pos mod} {
    # }

    proc complete(tcl_findLibrary) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <basename>] }
            2 { return [DisplayHints <version>] }
            3 { return [DisplayHints <patch>] }
            4 { return [DisplayHints <initScript>] }
            5 { return [DisplayHints <enVarName>] }
            6 { return [DisplayHints <varName>] }
        }
        return ""
    }

    proc complete(parray) {text start end line pos mod} {
        switch -- $pos {
            1 {
                set vars [uplevel [info level] info vars]
                foreach var $vars {
                    if {[uplevel [info level] array exists $var]} {
                        lappend matches $var
                    }
                }
                return [CompleteFromList $text $matches]
            }
        }
        return ""
    }

    proc complete(tcl_endOfWord) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <str>] }
            2 { return [DisplayHints <start>] }
        }
        return ""
    }

    proc complete(tcl_startOfNextWord) {text start end line pos mod} {
        return [complete(tcl_endOfWord) $text $start $end $line $pos $mod]
    }

    proc complete(tcl_startOfPreviousWord) {text start end line pos mod} {
        return [complete(tcl_endOfWord) $text $start $end $line $pos $mod]
    }

    proc complete(tcl_wordBreakAfter) {text start end line pos mod} {
        return [complete(tcl_endOfWord) $text $start $end $line $pos $mod]
    }

    proc complete(tcl_wordBreakBefore) {text start end line pos mod} {
        return [complete(tcl_endOfWord) $text $start $end $line $pos $mod]
    }

    # --- END OF `LIBRARY' ---

    proc complete(lindex) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <list>] }
            2 { return [DisplayHints <index>] }
        }
        return ""
    }

    proc complete(linsert) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <list>] }
            2 { return [DisplayHints <index>] }
            3 { return [DisplayHints <element>] }
            default { return [DisplayHints ?element?] }
        }
        return ""
    }

    proc complete(list) {text start end line pos mod} {
        return [DisplayHints ?arg?]
    }

    proc complete(llength) {text start end line pos mod} {
        switch -- $pos {
            1 {
                return [DisplayHints <list>]
            }
        }
        return ""
    }

    proc complete(load) {text start end line pos mod} {
        switch -- $pos {
            1 {
                return ""; # filename
            }
            2 {
                if {![llength $mod]} {
                    return [DisplayHints ?packageName?]
                }
            }
            3 {
                if {![llength $mod]} {
                    return [DisplayHints ?interp?]
                }
            }
        }
        return ""
    }

    proc complete(lrange) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <list>] }
            2 { return [DisplayHints <first>] }
            3 { return [DisplayHints <last>] }
        }
        return ""
    }

    proc complete(lreplace) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <list>] }
            2 { return [DisplayHints <first>] }
            3 { return [DisplayHints <last>] }
            default { return [DisplayHints ?element?] }
        }
        return ""
    }

    proc complete(lsearch) {text start end line pos mod} {
        set options {-exact -glob -regexp}
        switch -- $pos {
            1 {
                return [CompleteFromList $text "$options <list>"]
            }
            2 -
            3 -
            4 {
                set sub [Lindex $line 1]
                if {-1 != [lsearch $options $sub]} {
                    incr pos -1
                }
                switch -- $pos {
                    1 { return [DisplayHints <list>] }
                    2 { return [DisplayHints <pattern>] }
                }
            }
        }
        return ""
    }

    proc complete(lsort) {text start end line pos mod} {
        set options [RemoveUsedOptions $line \
                         {-ascii -dictionary -integer -real -command
                          -increasing -decreasing -index <list>}]
        switch -- $pos {
            1       { return [CompleteFromList $text $options] }
            default {
                switch -- [PreviousWord $start $line] {
                    -command { return [CompleteFromList $text [CommandCompletion $text]] }
                    -index   { return [DisplayHints <index>] }
                    default  { return [CompleteFromList $text $options] }
                }
            }
        }
        return ""
    }

    # --- MSGCAT PACKAGE ---

    # create a msgcat namespace inside
    # tclreadline and import some commands.
    #
    namespace eval msgcat {
        catch {namespace import ::tclreadline::DisplayHints}
    }

    proc msgcat::complete(mc) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <src-string>] }
        }
        return ""
    }

    proc msgcat::complete(mclocale) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints ?newLocale?] }
        }
        return ""
    }

    # proc msgcat::complete(mcpreferences) {text start end line pos mod} {
    # }

    proc msgcat::complete(mcload) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <dirname>] }
        }
        return ""
    }

    proc msgcat::complete(mcset) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <locale>] }
            2 { return [DisplayHints <src-string>] }
            3 { return [DisplayHints ?translate-string?] }
        }
        return ""
    }

    proc msgcat::complete(mcunknown) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <locale>] }
            2 { return [DisplayHints <src-string>] }
        }
        return ""
    }

    # --- END OF MSGCAT PACKAGE ---

}
