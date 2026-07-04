# -*- tclsh -*-
# core Tcl command completers.
# Sourced by ../tclreadlineCompleter.tcl.

namespace eval tclreadline {
    proc complete(after) {text start end line pos mod} {
        set sub [Lindex $line 1]
        switch -- $pos {
            1 {
                return [CompleteFromList $text {<ms> cancel idle info}]
            }
            2 {
                switch -- $sub {
                    cancel  { return [CompleteFromList $text "<script> [after info]"] }
                    idle    { return [DisplayHints <script>] }
                    info    { return [CompleteFromList $text [after info]] }
                    default { return [DisplayHints ?script?] }
                }
            }
            default {
                switch -- $sub {
                    info    { return [DisplayHints {}] }
                    default { return [DisplayHints ?script?] }
                }
            }
        }
        return ""
    }

    proc complete(append) {text start end line pos mod} {
        switch -- $pos {
            1       { return [VarCompletion $text] }
            default { return [DisplayHints ?value?] }
        }
        return ""
    }

    proc complete(array) {text start end line pos mod} {
        switch -- $pos {
            1 {
                set cmds {anymore donesearch exists get names
                          nextelement set size startsearch}
                return [CompleteFromList $text $cmds]
            }
            2 {
                set matches ""
                # set vars [uplevel [info level] info vars ${mod}*]
                #
                # better: this displays a list of array names if the
                # user inters with something which cannot be matched.
                # The matching against `text' is done by CompleteFromList.
                #
                set vars [uplevel [info level] info vars]
                foreach var $vars {
                    if {[uplevel [info level] array exists $var]} {
                        lappend matches $var
                    }
                }
                return [CompleteFromList $text $matches]
            }
            3 {
                set cmd [Lindex $line 1]
                set array_name [Lindex $line 2]
                switch -- $cmd {
                    get         -
                    names       {
                        set pattern [Lindex $line 3]
                        set matches [uplevel [info level] \
                                         array names $array_name ${pattern}*]
                        if {![llength $matches]} {
                            return [DisplayHints ?pattern?]
                        } else {
                            return [CompleteFromList $text $matches]
                        }
                    }
                    anymore     -
                    donesearch  -
                    nextelement { return [DisplayHints <searchId>] }
                }
            }
        }
        return ""
    }

    # proc complete(bgerror) {text start end line pos mod} {
    # }

    proc complete(binary) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        switch -- $pos {
            1 {
                return [CompleteFromList $text {format scan}]
            }
            2 {
                switch -- $cmd {
                    format { return [DisplayHints <formatString>] }
                    scan   { return [DisplayHints <string>] }
                }
            }
            3 {
                switch -- $cmd {
                    format { return [DisplayHints ?arg?] }
                    scan   { return [DisplayHints <formatString>] }
                }
            }
            default {
                switch -- $cmd {
                    format { return [DisplayHints ?arg?] }
                    scan   { return [DisplayHints ?varName?] }
                }
            }
        }
        return ""
    }

    # proc complete(break) {text start end line pos mod} {
    # }

    proc complete(catch) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <script>] }
            2 { return [DisplayHints ?varName?] }
        }
        return ""
    }

    proc complete(cd) {text start end line pos mod} {
        return ""
    }

    proc complete(clock) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        switch -- $pos {
            1 {
                return [CompleteFromList $text {clicks format scan seconds}]
            }
            2 {
                switch -- $cmd {
                    format  { return [DisplayHints <clockValue>] }
                    scan    { return [DisplayHints <dateString>] }
                    clicks  -
                    seconds {}
                }
            }
            3 -
            5 {
                switch -- $cmd {
                    format  {
                        set subcmds [RemoveUsedOptions $line {-format -gmt}]
                        return [TryFromList $text $subcmds]
                    }
                    scan    {
                        set subcmds [RemoveUsedOptions $line {-base -gmt}]
                        return [TryFromList $text $subcmds]
                    }
                    clicks  -
                    seconds {}
                }
            }
            4 -
            6 {
                set sub [Lindex $line [expr {$pos - 1}]]
                switch -- $cmd {
                    format {
                        switch -- $sub {
                            -format { return [DisplayHints <string>] }
                            -gmt    { return [DisplayHints <boolean>] }
                        }
                    }
                    scan {
                        switch -- $sub {
                            -base { return [DisplayHints <clockVal>] }
                            -gmt  { return [DisplayHints <boolean>] }
                        }
                    }
                    clicks  -
                    seconds {}
                }
            }
        }
        return ""
    }

    proc complete(close) {text start end line pos mod} {
        switch -- $pos {
            1 { return [ChannelId $text] }
        }
        return ""
    }

    proc complete(concat) {text start end line pos mod} {
        return [DisplayHints ?arg?]
    }

    # proc complete(continue) {text start end line pos mod} {
    # }

    # proc complete(dde) {text start end line pos mod} {
    #     We're not on windoze here ...
    # }

    proc complete(encoding) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        switch -- $pos {
            1 {
                return [CompleteFromList $text {convertfrom convertto names system}]
            }
            2 {
                switch -- $cmd {
                    convertfrom -
                    convertto   -
                    system      {
                        return [CompleteFromList $text [encoding names]]
                    }
                }
            }
            3 {
                switch -- $cmd {
                    convertfrom { return [DisplayHints <data>] }
                    convertto   { return [DisplayHints <string>] }
                }
            }
        }
        return ""
    }

    proc complete(eof) {text start end line pos mod} {
        switch -- $pos {
            1 { return [InChannelId $text] }
        }
        return ""
    }

    proc complete(error) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints <message>] }
            2 { return [DisplayHints ?info?] }
            3 { return [DisplayHints ?code?] }
        }
        return ""
    }

    proc complete(eval) {text start end line pos mod} {
        switch -- $pos {
            1       { return [DisplayHints <arg>] }
            default { return [DisplayHints ?arg?] }
        }
        return ""
    }

    proc complete(exec) {text start end line pos mod} {
        set redir [list | |& < <@ << > 2> >& >> 2>> >>& >@ 2>@ >&@]
        variable executables
        if {![info exists executables]} {
            Rehash
        }
        switch -- $pos {
            1 {
                return [TryFromList $text "-keepnewline -- $executables"]
            }
            default {
                set prev [PreviousWord $start $line]
                if {"-keepnewline" == $prev && 2 == $pos} {
                    return [TryFromList $text "-- $executables"]
                }
                switch -exact -- $prev {
                    |       -
                    |&      { return [TryFromList $text $executables] }
                    <       -
                    >       -
                    2>      -
                    >&      -
                    >>      -
                    2>>     -
                    >>&     { return "" }
                    <@      -
                    >@      -
                    2>@     -
                    >&@     { return [ChannelId $text] }
                    <<      { return [DisplayHints <value>] }
                    default { return [TryFromList $text $redir "<>"] }
                }
            }
        }
        return ""
    }

    proc complete(exit) {text start end line pos mod} {
        switch -- $pos {
            1 { return [DisplayHints ?returnCode?] }
        }
        return ""
    }

    proc complete(expr) {text start end line pos mod} {
        set left $text
        set right ""
        set substitution [regexp -- {(.*)(\(.*)} $text all left right]; #-)

        set cmds {
            - + ~ !  * / % + - << >> < > <= >= == != & ^ | && || <x?y:z>
            acos    cos     hypot   sinh
            asin    cosh    log     sqrt
            atan    exp     log10   tan
            atan2   floor   pow     tanh
            ceil    fmod    sin     abs
            double  int     rand    round
            srand
        }

        if {")" == [String index $text end] && -1 != [lsearch $cmds $left]} {
            return "$text "; # append a space after a closing ')'
        }

        switch -- $left {
            rand { return "rand() " }

            abs    -
            acos   -
            asin   -
            atan   -
            ceil   -
            cos    -
            cosh   -
            double -
            exp    -
            floor  -
            int    -
            log    -
            log10  -
            round  -
            sin    -
            sinh   -
            sqrt   -
            srand  -
            tan    -
            tanh   { return [DisplayHints <value>] }


            atan2 -
            fmod  -
            hypot -
            pow   { return [DisplayHints <value>,<value>] }
        }

        set completions [TryFromList $left $cmds <>]
        if {1 == [llength $completions]} {
            if {!$substitution} {
                if {"rand" == $completions} {
                    return "rand() "; # rand() takes no arguments
                }
                append completions (; #-)
                return [list $completions {}]
            }
        } else {
            return $completions
        }
        return ""
    }

    proc complete(fblocked) {text start end line pos mod} {
        switch -- $pos {
            1 { return [InChannelId $text] }
        }
        return ""
    }

    proc complete(fconfigure) {text start end line pos mod} {
        set cmd [Lindex $line 1]
        switch -- $pos {
            1       { return [ChannelId $text] }
            default {
                set option [PreviousWord $start $line]
                switch -- $option {
                    -blocking    { return [CompleteBoolean $text] }
                    -buffering   { return [CompleteFromList $text {full line none}] }
                    -buffersize  {
                        if {![llength $text]} {
                            return [DisplayHints <newSize>]
                        }
                    }
                    -encoding    { return [CompleteFromList $text [encoding names]] }
                    -eofchar     { return [DisplayHints {\{<inChar>\ <outChar>\}}] }
                    -translation { return [CompleteFromList $text {auto binary cr crlf lf}] }
                    default      {
                        return [CompleteFromList $text \
                                    [RemoveUsedOptions $line \
                                         {-blocking -buffering -buffersize
                                          -encoding -eofchar -translation}]]
                    }
                }
            }
        }
        return ""
    }

    proc complete(fcopy) {text start end line pos mod} {
        switch -- $pos {
            1       { return [InChannelId $text] }
            2       { return [OutChannelId $text] }
            default {
                set option [PreviousWord $start $line]
                switch -- $option {
                    -size    { return [DisplayHints <size>] }
                    -command { return [DisplayHints <callback>] }
                    default  { return [CompleteFromList $text \
                                           [RemoveUsedOptions $line {-size -command}]]
                    }
                }
            }
        }
        return ""
    }

    proc complete(file) {text start end line pos mod} {
        switch -- $pos {
            1 {
                set cmds {
                    atime attributes channels copy delete dirname executable exists
                    extension isdirectory isfile join lstat mkdir mtime
                    nativename owned pathtype readable readlink rename
                    rootname size split stat tail type volumes writable
                }
                return [TryFromList $text $cmds]
            }
            2 {
                set cmd [Lindex $line 1]
                switch -- $cmd {
                    atime       -
                    attributes  -
                    channels    -
                    dirname     -
                    executable  -
                    exists      -
                    extension   -
                    isdirectory -
                    isfile      -
                    join        -
                    lstat       -
                    mtime       -
                    mkdir       -
                    nativename  -
                    owned       -
                    pathtype    -
                    readable    -
                    readlink    -
                    rootname    -
                    size        -
                    split       -
                    stat        -
                    tail        -
                    type        -
                    volumes     -
                    writable    {
                        return ""
                    }

                    copy   -
                    delete -
                    rename {
                        # return [TryFromList $text "-force [glob *]"]
                        # this is not perfect. The  `-force' and `--'
                        # options will not be displayed.
                        return ""
                    }
                }
            }
        }
        return ""
    }

    proc complete(fileevent) {text start end line pos mod} {
        switch -- $pos {
            1 { return [ChannelId $text] }
            2 { return [CompleteFromList $text {readable writable}] }
            3 { return [DisplayHints ?script?] }
        }
        return ""
    }

    proc complete(flush) {text start end line pos mod} {
        switch -- $pos {
            1 { return [OutChannelId $text] }
        }
        return ""
    }

    proc complete(for) {text start end line pos mod} {
        switch -- $pos {
            1 -
            2 -
            3 -
            4 {
                return [BraceOrCommand $text $start $end $line $pos $mod]
            }
        }
        return ""
    }

    proc complete(foreach) {text start end line pos mod} {
        switch -- $pos {
            1       { return [DisplayHints <varname>] }
            2       { return [DisplayHints <list>] }
            default {
                if {[expr {$pos % 2}]} {
                    return [DisplayHints [list ?varname? <body>]]
                } else {
                    return [DisplayHints ?list?]
                }
            }
        }
        return ""
    }

    proc complete(format) {text start end line pos mod} {
        switch -- $pos {
            1       { return [DisplayHints <formatString>] }
            default { return [DisplayHints ?arg?] }
        }
        return ""
    }

    proc complete(gets) {text start end line pos mod} {
        switch -- $pos {
            1 { return [InChannelId $text] }
            2 { return [VarCompletion $text]}
        }
        return ""
    }

    proc complete(glob) {text start end line pos mod} {
        switch -- $pos {
            1 {
                # This also is not perfect.
                # This will not display the options as hints!
                set matches [TryFromList $text {-nocomplain --}]
                if {[llength [string trim $text]] && [llength $matches]} {
                    return $matches
                }
            }
        }
        return ""
    }

    proc complete(global) {text start end line pos mod} {
        return [VarCompletion $text]
    }

    proc complete(history) {text start end line pos mod} {
        switch -- $pos {
            1 {
                set cmds {add change clear event info keep nextid redo}
                return [TryFromList $text $cmds]
            }
            2 {
                set cmd [Lindex $line 1]
                switch -- $cmd {
                    add    { return [DisplayHints <command>] }
                    change { return [DisplayHints <newValue>] }

                    info -
                    keep { return [DisplayHints ?count?] }

                    event -
                    redo  { return [DisplayHints ?event?] }

                    clear  -
                    nextid { return "" }
                }
            }
        }
        return ""
    }

    # --- HTTP PACKAGE ---

    # create a http namespace inside
    # tclreadline and import some commands.
    #
    namespace eval http {
        catch {
            namespace import \
                ::tclreadline::DisplayHints ::tclreadline::PreviousWord \
                ::tclreadline::CompleteFromList ::tclreadline::CommandCompletion \
                ::tclreadline::RemoveUsedOptions ::tclreadline::HostList \
                ::tclreadline::ChannelId ::tclreadline::Lindex \
                ::tclreadline::CompleteBoolean
        }
    }
}
