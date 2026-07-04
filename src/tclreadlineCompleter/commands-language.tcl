# -*- tclsh -*-
# language, namespace, TclOO, and Itcl completers.
# Sourced by ../tclreadlineCompleter.tcl.

namespace eval tclreadline {
    proc complete(namespace) {text start end line pos mod} {
        # TODO doesn't work ???
        set space_matches [namespace children :: [string trim ${mod}*]]
        set cmd [Lindex $line 1]
        switch -- $pos {
            1 {
                set cmds {
                    children code current delete eval export forget
                    import inscope origin parent qualifiers tail which
                }
                return [TryFromList $text $cmds]
            }
            2 {
                switch -- $cmd {
                    children   -
                    delete     -
                    eval       -
                    inscope    -
                    forget     -
                    parent     -
                    qualifiers -
                    tail       {
                        regsub {^([^:])} $mod {::\1} mod; # full qual. name
                        return [TryFromList $mod $space_matches]
                    }
                    code       { return [DisplayHints <script> ] }
                    current    {}
                    export     { return [CompleteFromList $text {-clear ?pattern?}] }
                    import     {
                        if {"-" != [string index $mod 0]} {
                            regsub {^([^:])} $mod {::\1} mod; # full qual. name
                        }
                        return [CompleteFromList $mod "-force $space_matches"]
                    }
                    origin     { return [DisplayHints <command>] }
                    # tail       { return [DisplayHints <string>] }
                    which      { return [CompleteFromList $mod {-command -variable <name>}] }
                }
            }
            3 {
                switch -- $cmd {
                    children -
                    export   -
                    forget   -
                    import   { return [DisplayHints ?pattern?] }
                    delete   { return [TryFromList $mod $space_matches] }
                    eval     -
                    inscope  { return [BraceOrCommand $text $start $end $line $pos $mod] }
                    which    { return [CompleteFromList $mod {-variable <name>}] }
                }
            }
            4 {
                switch -- $cmd {
                    export  -
                    forget  -
                    import  { return [DisplayHints ?pattern?] }
                    delete  { return [TryFromList $mod $space_matches] }
                    eval    -
                    inscope { return [DisplayHints ?arg?] }
                    which   { return [CompleteFromList $mod {<name>}] }
                }
            }
        }
        return ""
    }

    proc complete(open) {text start end line pos mod} {
            # 2 { return [DisplayHints ?access?] }
        switch -- $pos {
            2 {
                set access {
                    r r+ w w+ a a+
                    RDONLY WRONLY RDWR APPEND CREAT
                    EXCL NOCTTY NONBLOCK TRUNC
                }
                return [CompleteFromList $text $access]
            }
            3 { return [DisplayHints ?permissions?] }
        }
        return ""
    }

    proc complete(package) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        switch -- $pos {
            1 {
                set cmds {
                    forget ifneeded names present provide require
                    unknown vcompare versions vsatisfies
                }
                return [TryFromList $text $cmds]
            }
            2 {
                switch -- $cmd {
                    forget     -
                    ifneeded   -
                    provide    -
                    versions   { return [CompleteFromList $mod [package names]] }
                    present    -
                    require    {
                        return [CompleteFromList $mod "-exact [package names]"] }
                    names      {}
                    unknown    { return [DisplayHints ?command?] }
                    vcompare   -
                    vsatisfies { return [DisplayHints <version1>] }
                }
            }
            3 {
                set versions ""
                catch [list set versions [package versions [Lindex $line 2]]]
                switch -- $cmd {
                    forget     {}
                    ifneeded   {
                        if {"" != $versions} {
                            return [CompleteFromList $text $versions]
                        } else {
                            return [DisplayHints <version>]
                        }
                    }
                    provide    {
                        if {"" != $versions} {
                            return [CompleteFromList $text $versions]
                        } else {
                            return [DisplayHints ?version?]
                        }
                    }
                    versions   {}
                    present    -
                    require    {
                        if {"-exact" == [PreviousWord $start $line]} {
                            return [CompleteFromList $mod [package names]]
                        } else {
                            if {"" != $versions} {
                                return [CompleteFromList $text $versions]
                            } else {
                                return [DisplayHints ?version?]
                            }
                        }
                    }
                    names      {}
                    unknown    {}
                    vcompare   -
                    vsatisfies { return [DisplayHints <version2>] }
                }
            }
        }
        return ""
    }

    proc complete(pid) {text start end line pos mod} {
        switch -- $pos {
            1 { return [ChannelId $text] }
        }
    }

    proc complete(pkg_mkIndex) {text start end line pos mod} {
        set cmds [RemoveUsedOptions $line {-direct -load -verbose -- <dir>} {--}]
        set res [string trim [TryFromList $text $cmds]]
        set prev [PreviousWord $start $line]
        if {"-load" == $prev} {
            return [DisplayHints <pkgPat>]
        } elseif {"--" == $prev} {
            return [TryFromList $text <dir>]
        }
        return $res
    }

    proc complete(proc) {text start end line pos mod} {
        switch -- $pos {
            1 {
                set known_procs [ProcsOnlyCompletion $text]
                return [CompleteFromList $text $known_procs]
            }
            2 {
                set proc [Lindex $line 1]
                if {[catch {set args [uplevel [info level] info args $proc]}]} {
                    return [DisplayHints <args>]
                } else {
                    return [list "\{${args}\}"]
                }
            }
            3 {
                if {![string length [Lindex $line $pos]]} {
                    return [list \{ {}]; # \}
                } else {
                    # return [DisplayHints <body>]
                    return [BraceOrCommand $text $start $end $line $pos $mod]
                }
            }
        }
        return ""
    }

    proc complete(puts) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        switch -- $pos {
            1 {
                return [OutChannelId $text "-nonewline"]
            }
            2 {
                switch -- $cmd {
                    -nonewline { return [OutChannelId $text] }
                    default    { return [DisplayHints <string>] }
                }
            }
            3 {
                switch -- $cmd {
                    -nonewline { return [DisplayHints <string>] }
                }
            }
        }
        return ""
    }

    # proc complete(pwd) {text start end line pos mod} {
    # }

    proc complete(read) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        switch -- $pos {
            1 {
                return [InChannelId $text "-nonewline"]
            }
            2 {
                switch -- $cmd {
                    -nonewline { return [InChannelId $text] }
                    default    { return [DisplayHints <numChars>] }
                }
            }
        }
        return ""
    }

    proc complete(regexp) {text start end line pos mod} {
        set prev [PreviousWord $start $line]
        if {[llength $prev] && "--" != $prev
                && ("-" == [string index $prev 0] || 1 == $pos)} {
            set cmds [RemoveUsedOptions $line \
                          {-nocase -indices -expanded -line
                           -linestop -lineanchor -about <expression> --} {--}]
            if {[llength $cmds]} {
                return [string trim [CompleteFromList $text $cmds]]
            }
        } else {
            set virtual_pos [expr {$pos - [FirstNonOption $line]}]
            switch -- $virtual_pos {
                0       { return [DisplayHints <string>] }
                1       { return [DisplayHints ?matchVar?] }
                default { return [DisplayHints ?subMatchVar?] }
            }
        }
        return ""
    }

    proc complete(regsub) {text start end line pos mod} {
        set prev [PreviousWord $start $line]
        if {[llength $prev] && "--" != $prev
                && ("-" == [string index $prev 0] || 1 == $pos)} {
            set cmds [RemoveUsedOptions $line \
                          {-all -nocase --} {--}]
            if {[llength $cmds]} {
                return [string trim [CompleteFromList $text $cmds]]
            }
        } else {
            set virtual_pos [expr {$pos - [FirstNonOption $line]}]
            switch -- $virtual_pos {
                0 { return [DisplayHints <expression>] }
                1 { return [DisplayHints <string>] }
                2 { return [DisplayHints <subSpec>] }
                3 { return [DisplayHints <varName>] }
            }
        }
        return ""
    }

    proc complete(rename) {text start end line pos mod} {
        switch -- $pos {
            1 { return [CompleteFromList $text [CommandCompletion $text]] }
            2 { return [DisplayHints <newName>] }
        }
        return ""
    }

    # proc complete(resource) {text start end line pos mod} {
    #     This is not a mac ...
    # }

    proc complete(return) {text start end line pos mod} {
        # TODO this is not perfect yet
        set cmds {-code -errorinfo -errorcode ?string?}
        set res [PreviousWord $start $line]
        switch -- $res {
            -errorinfo { return [DisplayHints <info>] }
            -code      -
            -errorcode {
                set codes {ok error return break continue}
                return [TryFromList $mod $codes]
            }
        }
        return [CompleteFromList $text [RemoveUsedOptions $line $cmds]]
    }

    # --- SAFE PACKAGE ---

    # create a safe namespace inside
    # tclreadline and import some commands.
    #
    namespace eval safe {
        catch {
            namespace import \
                ::tclreadline::DisplayHints ::tclreadline::PreviousWord \
                ::tclreadline::CompleteFromList ::tclreadline::CommandCompletion \
                ::tclreadline::RemoveUsedOptions ::tclreadline::HostList \
                ::tclreadline::ChannelId ::tclreadline::Lindex \
                ::tclreadline::CompleteBoolean \
                ::tclreadline::WidgetChildren
        }
        variable opts
        set opts {
            -accessPath -statics -noStatics -nested -nestedLoadOk -deleteHook
        }
        proc SlaveOrOpts {text start line pos slave} {
            set prev [PreviousWord $start $line]
            variable opts
            if {$pos > 1} {
                set slave ""
            }
            switch -- $prev {
                -accessPath { return [DisplayHints <directoryList>] }
                -statics    { return [CompleteBoolean $text] }
                -nested     { return [CompleteBoolean $text] }
                -deleteHook { return [DisplayHints <script>] }
                default     {
                    return [CompleteFromList $text \
                                [RemoveUsedOptions $line "$opts $slave"]]
                }
            }
        }
    }

    proc safe::complete(interpCreate) {text start end line pos mod} {
        return [SlaveOrOpts $text $start $line $pos ?slave?]
    }

    proc safe::complete(interpInit) {text start end line pos mod} {
        return [SlaveOrOpts $text $start $line $pos [interp slaves]]
    }

    proc safe::complete(interpConfigure) {text start end line pos mod} {
        return [SlaveOrOpts $text $start $line $pos [interp slaves]]
    }

    proc safe::complete(interpDelete) {text start end line pos mod} {
        return [CompleteFromList $text [interp slaves]]
    }

    proc safe::complete(interpAddToAccessPath) {text start end line pos mod} {
        switch -- $pos {
            1 { return [CompleteFromList $text [interp slaves]] }
        }
    }

    proc safe::complete(interpFindInAccessPath) {text start end line pos mod} {
        switch -- $pos {
            1 { return [CompleteFromList $text [interp slaves]] }
        }
    }

    proc safe::complete(setLogCmd) {text start end line pos mod} {
        switch -- $pos {
            1       { return [DisplayHints ?cmd?] }
            default { return [DisplayHints ?arg?] }
        }
    }

    proc safe::complete(loadTk) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <slave>] }
            default {
                switch -- [PreviousWord $start $line] {
                    -use     {
                        return [CompleteFromList $text \
                                    [::tclreadline::WidgetChildren $text]]
                    }
                    -display { return [DisplayHints <display>] }
                    default  {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line {-use -display}]]
                    }
                }
            }
        }
    }

    # --- END OF SAFE PACKAGE ---

    proc complete(scan) {text start end line pos mod} {
        switch -- $pos {
            1       { return [DisplayHints <string>] }
            2       { return [DisplayHints <format>] }
            default { return [VarCompletion $text] }
        }
        return ""
    }

    proc complete(seek) {text start end line pos mod} {
        switch -- $pos {
            1 { return [ChannelId $text] }
            2 { return [DisplayHints <offset>] }
            3 { return [TryFromList $text {start current end}] }
        }
        return ""
    }

    proc complete(set) {text start end line pos mod} {
        switch -- $pos {
            1 { return [VarCompletion $text] }
            2 {
                if {$text == "" || $text == "\"" || $text == "\{"} {
                    # set line [QuoteQuotes $line]
                    if {[catch {set value \
                                    [list [uplevel [info level] \
                                               set [Lindex $line 1]]]} msg]} {
                        return ""
                    } else {
                        return [Quote $value $text]
                    }
                }
            }
        }
        return ""
    }

    proc complete(socket) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        set prev [PreviousWord $start $line]
        if {"-server" == $cmd} {
            # server sockets
            #
            switch -- $pos {
                2       { return [DisplayHints <command>] }
                default {
                    if {"-myaddr" == $prev} {
                        return [DisplayHints <addr>]
                    } else {
                        return [CompleteFromList $mod \
                                    [RemoveUsedOptions $line {-myaddr -error -sockname <port>}]]
                    }
                }
            }
        } else {
            # client sockets
            #
            switch -- $prev {
                -myaddr { return [DisplayHints <addr>] }
                -myport { return [DisplayHints <port>] }
            }

            set hosts [HostList]
            set cmds {-myaddr -myport -async -myaddr -error -sockname -peername}
            if {$pos <= 1} {
                lappend cmds -server
            }
            set cmds [RemoveUsedOptions $line $cmds]
            if {-1 != [lsearch $hosts $prev]} {
                return [DisplayHints <port>]
            } else {
                return [CompleteFromList $mod [concat $cmds $hosts]]
            }
        }
        return ""
    }

    proc complete(source) {text start end line pos mod} {
        # allow file name completion
        return ""
    }

    proc complete(split) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <string>] }
            2 { return [DisplayHints ?splitChars?] }
        }
    }

    proc complete(string) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        set prev [PreviousWord $start $line]
        set cmds {
            bytelength compare equal first index is last length map match
            range repeat replace tolower toupper totitle trim trimleft
            trimright wordend wordstart}
        switch -- $pos {
            1 { return [CompleteFromList $text $cmds] }
            2 {
                switch -- $cmd {
                    compare -
                    equal   {
                        return [CompleteFromList $text {-nocase -length <string>}]
                    }

                    first -
                    last  { return [DisplayHints <string1>] }

                    map   { return [CompleteFromList $text {-nocase <charMap>]} }
                    match { return [CompleteFromList $text {-nocase <pattern>]} }

                    is {
                        return [CompleteFromList $text \
                                    {alnum alpha ascii boolean control digit double
                                     false graph integer lower print punct space
                                     true upper wordchar xdigit}]
                    }

                    bytelength -
                    index      -
                    length     -
                    range      -
                    repeat     -
                    replace    -
                    tolower    -
                    totitle    -
                    toupper    -
                    trim       -
                    trimleft   -
                    trimright  -
                    wordend    -
                    wordstart  { return [DisplayHints <string>] }
                }
            }
            3 {
                switch -- $cmd {
                    compare -
                    equal   {
                        if {"-length" == $prev} {
                            return [DisplayHints <int>]
                        }
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line {-nocase -length <string>}]]
                    }

                    first -
                    last  { return [DisplayHints <string2>] }

                    map   {
                        if {"-nocase" == $prev} {
                            return [DisplayHints <charMap>]
                        } else {
                            return [DisplayHints <string>]
                        }
                    }
                    match {
                        if {"-nocase" == $prev} {
                            return [DisplayHints <pattern>]
                        } else {
                            return [DisplayHints <string>]
                        }
                    }

                    is {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line {-strict -failindex <string>}]]
                    }

                    bytelength {}
                    index      -
                    wordend    -
                    wordstart  { return [DisplayHints <charIndex>] }
                    range      -
                    replace    { return [DisplayHints <first>] }
                    repeat     { return [DisplayHints <count>] }
                    tolower    -
                    totitle    -
                    toupper    { return [DisplayHints ?first?] }
                    trim       -
                    trimleft   -
                    trimright  { return [DisplayHints ?chars?] }
                }
            }
            4 {
                switch -- $cmd {
                    compare -
                    equal   {
                        if {"-length" == $prev} {
                            return [DisplayHints <int>]
                        }
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line {-nocase -length <string>}]]
                    }

                    first -
                    last  { return [DisplayHints ?startIndex?] }

                    map   -
                    match { return [DisplayHints <string>] }

                    is {
                        if {"-failindex" == $prev} {
                            return [VarCompletion $text]
                        }
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line {-strict -failindex <string>}]]
                    }

                    bytelength {}
                    index      {}
                    length     {}
                    range      -
                    replace    { return [DisplayHints <last>] }
                    repeat     {}
                    tolower    -
                    totitle    -
                    toupper    { return [DisplayHints ?last?] }
                    trim       -
                    trimleft   -
                    trimright  {}
                    wordend    -
                    wordstart  {}
                }
            }
            default {
                switch -- $cmd {
                    compare -
                    equal   {
                        if {"-length" == $prev} {
                            return [DisplayHints <int>]
                        }
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line {-nocase -length <string>}]]
                    }

                    is {
                        if {"-failindex" == $prev} {
                            return [VarCompletion $text]
                        }
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line {-strict -failindex <string>}]]
                    }

                    replace { return [DisplayHints ?newString?] }
                }
            }
        }
        return ""
    }

    proc complete(subst) {text start end line pos mod} {
        return [CompleteFromList $text [RemoveUsedOptions $line {
            -nobackslashes -nocommands -novariables <string>}]]
    }

    proc complete(switch) {text start end line pos mod} {
        set prev [PreviousWord $start $line]
        if {[llength $prev] && "--" != $prev
                && ("-" == [string index $prev 0] || 1 == $pos)} {
            set cmds [RemoveUsedOptions $line \
                          {-exact -glob -regexp --} {--}]
            if {[llength $cmds]} {
                return [string trim [CompleteFromList $text $cmds]]
            }
        } else {
            set virtual_pos [expr {$pos - [FirstNonOption $line]}]
            switch -- $virtual_pos {
                0       { return [DisplayHints <string>] }
                1       { return [DisplayHints <pattern>] }
                2       { return [DisplayHints <body>] }
                default {
                    switch [expr {$virtual_pos % 2}] {
                        0 { return [DisplayHints ?body?] }
                        1 { return [DisplayHints ?pattern?] }
                    }
                }
            }
        }
        return ""
    }

    # --- TCLREADLINE PACKAGE ---

    # create a tclreadline namespace inside
    # tclreadline and import some commands.
    #
    namespace eval tclreadline {
        catch {
            namespace import \
                ::tclreadline::DisplayHints \
                ::tclreadline::CompleteFromList \
                ::tclreadline::Lindex \
                ::tclreadline::CompleteBoolean
        }
    }

    proc tclreadline::complete(readline) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        switch -- $pos {
            1 { return [CompleteFromList $text \
                            {read initialize write add complete customcompleter
                             builtincompleter eofchar reset-terminal bell
                             historyexpansion}]
            }
            2 {
                switch -- $cmd {
                    read             {}
                    initialize       {}
                    write            {}
                    add              { return [DisplayHints <completerLine>] }
                    completer        { return [DisplayHints <line>] }
                    customcompleter  { return [DisplayHints ?scriptCompleter?] }
                    historyexpansion -
                    builtincompleter { return [CompleteBoolean $text] }
                    eofchar          { return [DisplayHints ?script?] }
                    reset-terminal   {
                        if {[info exists ::env(TERM)]} {
                            return [CompleteFromList $text $::env(TERM)]
                        } else {
                            return [DisplayHints ?terminalName?]
                        }
                    }
                }
            }
        }
        return ""
    }

    # --- END OF TCLREADLINE PACKAGE ---

    proc complete(tell) {text start end line pos mod} {
        switch -- $pos {
            1 { return [ChannelId $text] }
        }
        return ""
    }

    proc complete(testthread) {text start end line pos mod} {

        set cmd [Lindex $line 1]
        switch -- $pos {
            1 {
                return [CompleteFromList $text \
                            {-async create errorproc exit id names send wait}]
            }
            2 {
                switch -- [PreviousWord $start $line] {
                    create  {
                        return [BraceOrCommand $text $start $end $line $pos $mod]
                    }
                    -async  { return [CompleteFromList $text send] }
                    send    { return [CompleteFromList $text [testthread names]] }
                    default {}
                }
            }
            3 {
                if {"send" == [PreviousWord $start $line]} {
                    return [CompleteFromList $text [testthread names]]
                } elseif {"send" == $cmd} {
                    return [BraceOrCommand $text $start $end $line $pos $mod]
                }
            }
            4 {
                if {"send" == [Lindex $line 2]} {
                    return [BraceOrCommand $text $start $end $line $pos $mod]
                }
            }
        }
        return ""
    }

    proc complete(time) {text start end line pos mod} {
        switch -- $pos {
            1 { return [BraceOrCommand $text $start $end $line $pos $mod]
            }
            2 { return [DisplayHints ?count?] }
        }
        return ""
    }

    proc complete(trace) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        switch -- $pos {
            1 { return [CompleteFromList $mod {variable vdelete vinfo}] }
            2 { return [CompleteFromList $text [uplevel [info level] info vars "${mod}*"]] }
            3 {
                # TODO LW: 2 'variable' cases, missing 'vinfo' case?
                switch -- $cmd {
                    variable -
                    variable { return [CompleteFromList $text {r w u}] }
                    vdelete  {
                        set var [PreviousWord $start $line]
                        set modes ""
                        foreach info [uplevel [info level] trace vinfo $var] {
                            lappend modes [lindex $info 0]
                        }
                        return [CompleteFromList $text $modes]
                    }
                }
            }
            4 {
                switch -- $cmd {
                    variable {
                        return [CompleteFromList $text [CommandCompletion $text]]
                    }
                    vdelete {
                        set var [Lindex $line 2]
                        set mode [PreviousWord $start $line]
                        set scripts ""
                        foreach info [uplevel [info level] trace vinfo $var] {
                            if {$mode == [lindex $info 0]} {
                                lappend scripts [list [lindex $info 1]]
                            }
                        }
                        return [DisplayHints $scripts]
                    }
                }
            }
        }
        return ""
    }

    proc complete(unknown) {text start end line pos mod} {
        switch -- $pos {
            1       { return [CompleteFromList $text [CommandCompletion $text]] }
            default { return [DisplayHints ?arg?] }
        }
        return ""
    }

    proc complete(unset) {text start end line pos mod} {
        return [VarCompletion $text]
    }

    proc complete(update) {text start end line pos mod} {
        switch -- $pos {
            1 { return idletasks }
        }
        return ""
    }

    proc complete(uplevel) {text start end line pos mod} {
        set one [Lindex $line 1]
        switch -- $pos {
            1 {
                return [CompleteFromList $text "?level? [CommandCompletion $text]"]
            }
            2 {
                if {"#" == [string index $one 0] || [regexp {^[0-9]*$} $one]} {
                    return [CompleteFromList $text [CommandCompletion $text]]
                } else {
                    return [DisplayHints ?arg?]
                }
            }
            default { return [DisplayHints ?arg?] }
        }
        return ""
    }

    proc complete(upvar) {text start end line pos mod} {
        set one [Lindex $line 1]
        switch -- $pos {
            1       { return [DisplayHints {?level? <otherVar>}] }
            2       {
                if {"#" == [string index $one 0] || [regexp {^[0-9]*$} $one]} {
                    return [DisplayHints <otherVar>]
                } else {
                    return [DisplayHints <myVar>]
                }
            }
            3       {
                if {"#" == [string index $one 0] || [regexp {^[0-9]*$} $one]} {
                    return [DisplayHints <myVar>]
                } else {
                    return [DisplayHints ?otherVar?]
                }
            }
            default {
                set virtual_pos $pos
                if {"#" == [string index $one 0] || [regexp {^[0-9]*$} $one]} {
                    incr virtual_pos
                }
                switch [expr {$virtual_pos % 2}] {
                    0 { return [DisplayHints ?myVar?] }
                    1 { return [DisplayHints ?otherVar?] }
                }
            }
        }
        return ""
    }

    proc complete(variable) {text start end line pos mod} {
        set modulo [expr {$pos % 2}]
        switch -- $modulo {
            1 { return [VarCompletion $text] }
            0 {
                if {$text == "" || $text == "\"" || $text == "\{"} {
                    set line [QuoteQuotes $line]
                    if {[catch {set value [list [uplevel [info level] \
                                    set [PreviousWord $start $line]]]} msg]} {
                        return ""
                    } else {
                        return [Quote $value $text]
                    }
                }
            }
        }
        return ""
    }

    proc complete(vwait) {text start end line pos mod} {
        switch -- $pos {
            1 { return [VarCompletion $mod] }
        }
        return ""
    }

    proc complete(while) {text start end line pos mod} {
        switch -- $pos {
            1 -
            2 {
                return [BraceOrCommand $text $start $end $line $pos $mod]
            }
        }
        return ""
    }

    # --- TclOO PACKAGE ---
    proc complete(_tcloo) {text start end line pos mod} {
        # Resolve object name. A full-on [subst] without -nocommands may seem
        # excessive but this mirrors what ScriptCompleter does.
        set obj [uplevel [info level] [list subst [Lindex $line 0]]]
        switch -- $pos {
            0 {
                return ""
            }
            1 {
                return [CompleteFromList $text [info object methods $obj -all]]
            }
            default {
                set method [Lindex $line 1]
                set cls [info object class $obj]
                if {$method in [info object methods $obj]} {
                    set method_args \
                            [Lindex [info object definition $obj $method] 0]
                } elseif {$method in [info class methods $cls]} {
                    set method_args \
                            [Lindex [info class definition $cls $method] 0]
                } else {
                    return ""
                }
                set len [Llength $method_args]
                set arg_pos [expr { $pos - 2 }]
                if {($len > 0) && ($arg_pos < $len)} {
                    set arg [Lindex $method_args $pos-2]
                    return [DisplayHints [list <$arg>]]
                } else {
                    return ""
                }
            }
        }
        error "this should never be reached"
    }
    # --- END OF TclOO PACKAGE ---

    # --- itcl PACKAGE ---
    proc complete(_itcl) {text start end line pos mod} {
        set obj [uplevel [info level] [list subst [Lindex $line 0]]]

        switch -- $pos {
            0 {
                return ""
            }
            1 {
                set methods info
                foreach method [$obj info function] {
                    lappend methods [namespace tail $method]
                }
                return [CompleteFromList $text $methods]
            }
            default {
                set method [Lindex $line 1]
                switch -- $method {
                    cget -
                    configure {
                        if {$pos % 2 == 0} {
                            set option_names {}
                            foreach option [$obj configure] {
                                lappend option_names [Lindex $option 0]
                            }
                            return [CompleteFromList $text $option_names]
                        } else {
                            return ""
                        }
                    }
                    info {
                        set subcmds {class inherit heritage function variable}
                        return [CompleteFromList $text $subcmds]
                    }
                    default {
                        if {[catch {
                            set method_args [$obj info function $method -args]
                        }]} {
                            return ""
                        }
                        set len [Llength $method_args]
                        set arg_pos [expr { $pos - 2 }]
                        if {($len > 0) && ($arg_pos < $len)} {
                            set arg [Lindex $method_args $pos-2]
                            return [DisplayHints [list <$arg>]]
                        } else {
                            return ""
                        }
                    }
                }
            }
        }
        error "this should never be reached"
    }
    # --- END OF itcl PACKAGE ---

    # -------------------------------------
    #                  TK
    # -------------------------------------

    # GENERIC WIDGET CONFIGURATION
}
