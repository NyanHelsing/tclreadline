# -*- tclsh -*-
# Tk command completers.
# Sourced by ../tclreadlineCompleter.tcl.

namespace eval tclreadline {
    proc complete(bell) {text start end line pos mod} {
        switch -- $pos {
            1 { return [CompleteFromList $text -displayof] }
            2 {
                if {"-displayof" == [PreviousWord $start $line]} {
                    return [CompleteFromList $text [ToplevelWindows]]
                }
            }
        }
    }

    proc CompleteSequence {text fulltext} {
        set modifiers {
            Alt Control Shift Lock Double Triple
            B1 B2 B3 B4 B5 Button1 Button2 Button3 Button4 Button5
            M M1 M2 M3 M4 M5
            Meta Mod1 Mod2 Mod3 Mod4 Mod5
        }
        set events {
            Activate Button ButtonPress ButtonRelease
            Circulate Colormap Configure Deactivate Destroy
            Enter Expose FocusIn FocusOut Gravity
            Key KeyPress KeyRelease Leave Map Motion
            MouseWheel Property Reparent Unmap Visibility
        }
        set sequence [concat $modifiers $events]
        return [CompleteListFromList $text $fulltext $sequence < - >]
    }

    proc complete(bind) {text start end line pos mod} {
        switch -- $pos {
            1 {
                set widgets [WidgetChildren $text]
                set toplevels [ToplevelWindows]
                if {[catch {set toplevelClass [winfo class .]}]} {
                    set toplevelClass ""
                }
                set rest {
                    Button Canvas Checkbutton Entry Frame Label
                    Listbox Menu Menubutton Message Radiobutton
                    Scale Scrollbar Text
                    all
                }
                return [CompleteFromList $text \
                            [concat $toplevels $widgets $toplevelClass $rest]]
            }
            2 {
                return [CompleteSequence $text [Lindex $line 2]]
            }
            default {
                # return [DisplayHints {<script> <+script>}]
                return [BraceOrCommand $text $start $end $line $pos $mod]
            }
        }
        return ""
    }

    proc complete(bindtags) {text start end line pos mod} {
        switch -- $pos {
            1 { return [CompleteFromList $text [WidgetChildren $text]] }
            2 {
                # set current_tags [RemoveUsedOptions $line [bindtags [Lindex $line 1]]]
                set current_tags [bindtags [Lindex $line 1]]
                return [CompleteListFromList $text [Lindex $line 2] \
                            $current_tags \{ { } \}]
            }
        }
        return ""
    }

    proc complete(button) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-activebackground -activeforeground -anchor
                             -background -bitmap -borderwidth -cursor
                             -disabledforeground -font -foreground
                             -highlightbackground -highlightcolor
                             -highlightthickness -image -justify
                             -padx -pady -relief -takefocus -text
                             -textvariable -underline -wraplength
                             -command -default -height -state -width}]
            }
        }
        return ""
    }

    proc complete(canvas) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-background -borderwidth -cursor -highlightbackground
                             -highlightcolor -highlightthickness -insertbackground
                             -insertborderwidth -insertofftime -insertontime
                             -insertwidth -relief -selectbackground -selectborderwidth
                             -selectforeground -takefocus -xscrollcommand -yscrollcommand
                             -closeenough -confine -height -scrollregion -width
                             -xscrollincrement -yscrollincrement}]
            }
        }
        return ""
    }

    proc complete(checkbutton) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-activebackground activeBackground Foreground
                             -activeforeground -anchor -background -bitmap
                             -borderwidth -cursor -disabledforeground -font
                             -foreground -highlightbackground -highlightcolor
                             -highlightthickness -image -justify -padx -pady
                             -relief -takefocus -text -textvariable -underline
                             -wraplength -command -height -indicatoron -offvalue
                             -onvalue -selectcolor -selectimage -state -variable
                             -width}]
            }
        }
        return ""
    }

    proc complete(clipboard) {text start end line pos mod} {
        switch -- $pos {
            1       { return [CompleteFromList $text {append clear}] }
            default {
                set sub [Lindex $line 1]
                set prev [PreviousWord $start $line]
                switch -- $sub {
                    append {
                        switch -- $prev {
                            -displayof {
                                return [CompleteFromList $text [ToplevelWindows]]
                            }
                            -format    { return [DisplayHints <format>] }
                            -type      { return [DisplayHints <type>] }
                            default    {
                                set opts [RemoveUsedOptions $line \
                                              {-displayof -format -type --} {--}]
                                if {![string length $opts]} {
                                    return [DisplayHints <data>]
                                } else {
                                    return [CompleteFromList $text $opts]
                                }
                            }
                        }
                    }
                    clear {
                        switch -- $prev {
                            -displayof {
                                return [CompleteFromList $text [ToplevelWindows]]
                            }
                            default    {
                                return [CompleteFromList $text \
                                            [RemoveUsedOptions $line {-displayof}]]
                            }
                        }
                    }
                }
            }
        }
    }

    proc complete(destroy) {text start end line pos mod} {
        set remaining [RemoveUsedOptions $line [WidgetChildren $text]]
        return [CompleteFromList $text $remaining]
    }

    proc complete(entry) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-background -borderwidth -cursor -exportselection
                             -font -foreground -highlightbackground -highlightcolor
                             -highlightthickness -insertbackground -insertborderwidth
                             -insertofftime -insertontime -insertwidth -justify -relief
                             -selectbackground -selectborderwidth -selectforeground
                             -takefocus -textvariable -xscrollcommand -show -state
                             -width}]
            }
        }
        return ""
    }

    proc complete(event) {text start end line pos mod} {
        set sub [Lindex $line 1]
        switch -- $pos {
            1       {
                return [CompleteFromList $text {add delete generate info}]
            }
            2       {
                switch -- $sub {
                    add      { return [DisplayHints <<virtual>>] }
                    info     -
                    delete   { return [CompleteFromList $text [event info] "<"] }
                    generate { return [TryFromList $text [WidgetChildren $text]] }
                }
            }
            3       {
                switch -- $sub {
                    add      -
                    delete   -
                    generate { return [CompleteSequence $text [Lindex $line 3]] }
                    info     {}
                }
            }
            default {
                switch -- $sub {
                    add      -
                    delete   { return [CompleteSequence $text [Lindex $line 3]] }
                    info     {}
                    generate {
                        switch -- [PreviousWord $start $line] {
                            -above     -
                            -root      -
                            -subwindow { return [TryFromList $text [WidgetChildren $text]] }

                            -borderwidth { return [DisplayHints <size>] }

                            -button  -
                            -delta   -
                            -keycode -
                            -serial  -
                            -count   { return [DisplayHints <number>] }

                            -detail {
                                return [CompleteFromList $text \
                                            {NotifyAncestor    NotifyNonlinearVirtual
                                             NotifyDetailNone  NotifyPointer
                                             NotifyInferior    NotifyPointerRoot
                                             NotifyNonlinear   NotifyVirtual}]
                            }

                            -focus     -
                            -override  -
                            -sendevent { return [CompleteBoolean $text] }

                            -height -
                            -width  { return [DisplayHints <size>] }

                            -keysym { return [DisplayHints <name>] }

                            -mode {
                                return [CompleteFromList $text \
                                            {NotifyNormal NotifyGrab
                                             NotifyUngrab NotifyWhileGrabbed}]
                            }

                            -place {
                                return [CompleteFromList $text {PlaceOnTop PlaceOnBottom}]
                            }

                            -rootx -
                            -rooty -
                            -x     -
                            -y     { return [DisplayHints <coord>] }

                            -state {
                                return [CompleteFromList $text \
                                            {VisibilityUnobscured VisibilityPartiallyObscured
                                             VisibilityFullyObscured <integer>}]
                            }

                            -time { return [DisplayHints <integer>] }
                            -when { return [CompleteFromList $text {now tail head mark}] }

                            default {
                                return [CompleteFromList $text \
                                            [RemoveUsedOptions $line \
                                                 {-above -borderwidth -button -count -delta
                                                  -detail -focus -height -keycode -keysym
                                                  -mode -override -place -root -rootx -rooty
                                                  -sendevent -serial -state -subwindow -time
                                                  -width -when -x -y}]]
                            }
                        }
                    }
                    default {}
                }
            }
        }
        return ""
    }

    proc complete(focus) {text start end line pos mod} {
        switch -- $pos {
            1       {
                return [CompleteFromList $text \
                            [concat [WidgetChildren $text] -displayof -force -lastfor]]
            }
            default {
                switch -- [PreviousWord $start $line] {
                    -displayof -
                    -force     -
                    -lastfor   {
                        return [CompleteFromList $text [WidgetChildren $text]]
                    }
                }
            }
        }
        return ""
    }

    proc FontConfigure {text line prev} {
        set fontopts {-family -overstrike -size -slant -underline -weight}
        switch -- $prev {
            -family     { return [CompleteFromList $text [font families]] }
            -underline  -
            -overstrike { return [CompleteBoolean $text] }
            -size       { return [DisplayHints <size>] }
            -slant      { return [CompleteFromList $text {roman italic}] }
            -weight     { return [CompleteFromList $text {normal bold}] }
            default     {
                return [CompleteFromList $text [RemoveUsedOptions $line $fontopts]]
            }
        }
    }

    proc complete(font) {text start end line pos mod} {
        set fontopts {-family -overstrike -size -slant -underline -weight}
        set fontmetrics {-ascent -descent -linespace -fixed}
        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]
        switch -- $pos {
            1 {
                return [CompleteFromList $text \
                            {actual configure create delete
                             families measure metrics names}]
            }
            2 {
                switch -- $sub {
                    actual    -
                    measure   -
                    metrics   { return [DisplayHints <font>] }
                    configure -
                    delete    {
                        set names [font names]
                        if {[string length $names]} {
                            return [CompleteFromList $text $names]
                        } else {
                            return [DisplayHints <fontname>]
                        }
                    }
                    create    { return [CompleteFromList $text [concat ?fontname? $fontopts]] }
                    families  { return [CompleteFromList $text -displayof] }
                    names     {}
                }
            }
            3 {
                switch -- $sub {
                    actual    { return [CompleteFromList $text [concat -displayof $fontopts]] }
                    configure -
                    create    { return [FontConfigure $text $line $prev] }
                    delete    {
                        set names [font names]
                        if {[string length $names]} {
                            return [CompleteFromList $text $names]
                        } else {
                            return [DisplayHints <fontname>]
                        }
                    }
                    families  {
                        switch -- $prev {
                            -displayof { return [CompleteFromList $text [WidgetChildren $text]] }
                        }
                    }
                    measure   { return [CompleteFromList $text {-displayof <text>}] }
                    metrics   { return [CompleteFromList $text [concat -displayof $fontmetrics]] }
                    names     {}
                }
            }
            4 {
                switch -- $sub {
                    actual    {
                        switch -- $prev {
                            -displayof { return [CompleteFromList $text [WidgetChildren $text]] }
                            default    { return [FontConfigure $text $line $prev] }
                        }
                    }
                    configure -
                    create    { return [FontConfigure $text $line $prev] }
                    delete    {
                        set names [font names]
                        if {[string length $names]} {
                            return [CompleteFromList $text $names]
                        } else {
                            return [DisplayHints <fontname>]
                        }
                    }
                    families  {}
                    measure   {
                        switch -- $prev {
                            -displayof { return [CompleteFromList $text [WidgetChildren $text]] }
                            default    { return [DisplayHints <text>] }
                        }
                    }
                    metrics   {
                        switch -- $prev {
                            -displayof { return [CompleteFromList $text [WidgetChildren $text]] }
                            default    { return [CompleteFromList $text $fontmetrics] }
                        }
                    }
                    names     {}
                }
            }
            default {
                switch -- $sub {
                    actual    -
                    configure -
                    create    { return [FontConfigure $text $line $prev] }
                    delete    {
                        set names [font names]
                        if {[string length $names]} {
                            return [CompleteFromList $text $names]
                        } else {
                            return [DisplayHints <fontname>]
                        }
                    }
                    families  {}
                    measure   { return [DisplayHints <text>] }
                    metrics   { return [CompleteFromList $text $fontmetrics] }
                    names     {}
                }
            }
        }
        return ""
    }

    proc complete(frame) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-borderwidth -cursor -highlightbackground -highlightcolor
                             -highlightthickness -relief -takefocus -background
                             -class -colormap -container -height -visual -width}]
            }
        }
        return ""
    }

    proc complete(grab) {text start end line pos mod} {
        switch -- $pos {
            1 {
                return [CompleteFromList $text \
                            [concat current release set status -global [WidgetChildren $text]]]
            }
            2 {
                switch -- [Lindex $line 1] {
                    -global -
                    current -
                    release -
                    status  { return [CompleteFromList $text [WidgetChildren $text]] }
                    set     {
                        return [CompleteFromList $text [concat -global [WidgetChildren $text]]]
                    }
                }
            }
            3 {
                switch -- [Lindex $line 1] {
                    set {
                        switch -- [PreviousWord $start $line] {
                            -global { return [CompleteFromList $text [WidgetChildren $text]] }
                        }
                    }
                }
            }
        }
        return ""
    }

    proc GridConfig {text start line prev} {
        set opts {
            -column -columnspan -in -ipadx -ipady
            -padx -pady -row -rowspan -sticky
        }
        if {-1 == [string first "-" $line]} {
            set slave [WidgetChildren $text]
        } else {
            set slave ""
        }
        switch -- $prev {
            -column     -
            -columnspan -
            -row        -
            -rowspan    { return [DisplayHints <n>] }

            -ipadx -
            -ipady -
            -padx  -
            -pady  { return [DisplayHints <amount>] }

            -in     { return [CompleteFromList $text [WidgetChildren $text]] }
            -sticky {
                set prev [PreviousWordOfIncompletePosition $start $line]
                return [CompleteListFromList $text \
                            [string trimleft [IncompleteListRemainder $line]] \
                            {n e s w} \{ { } \}]
            }

            default {
                return [CompleteFromList $text \
                            [RemoveUsedOptions $line [concat $opts $slave]]]
            }
        }
    }

    proc complete(grid) {text start end line pos mod} {
        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]
        switch -- $pos {
            1 {
                return [CompleteFromList $text \
                            [concat [WidgetChildren $text] \
                                 {bbox columnconfigure configure forget
                                  info location propagate rowconfigure
                                  remove size slaves}]]
            }
            2 {
                switch -- $sub {
                    bbox            -
                    columnconfigure -
                    configure       -
                    forget          -
                    info            -
                    location        -
                    propagate       -
                    rowconfigure    -
                    remove          -
                    size            -
                    slaves          { return [CompleteFromList $text [WidgetChildren $text]] }
                    default         { return [GridConfig $text $start $line $prev] }
                }
            }
            default {
                switch -- $sub {
                    bbox            {
                        switch [expr {$pos % 2}] {
                            0 { return [DisplayHints ?row?] }
                            1 { return [DisplayHints ?column?] }
                        }
                    }
                    rowconfigure    -
                    columnconfigure {
                        switch -- $pos {
                            3       { return [DisplayHints <index>] }
                            default {
                                switch -- $prev {
                                    -minsize { return [DisplayHints <minsize>] }
                                    -weight  { return [DisplayHints <weight>] }
                                    -pad     { return [DisplayHints <pad>] }
                                    default  {
                                        return [CompleteFromList $text \
                                                    [RemoveUsedOptions $line \
                                                         {-minsize -weight -pad}]]
                                    }
                                }
                            }
                        }
                    }
                    configure       { return [GridConfig $text $start $line $prev] }
                    forget          -
                    remove          { return [CompleteFromList $text [WidgetChildren $text]] }
                    info            {}
                    location        {
                        switch -- $pos {
                            3 { return [DisplayHints <x>] }
                            4 { return [DisplayHints <y>] }
                        }
                    }
                    propagate       {
                        switch -- $pos {
                            3 { return [CompleteBoolean $text] }
                        }
                    }
                    size            {}
                    slaves          {
                        switch -- $prev {
                            -row    { return [DisplayHints <row>] }
                            -column { return [DisplayHints <column>] }
                            default {
                                return [CompleteFromList $text \
                                            [RemoveUsedOptions $line {-row -column}]]
                            }
                        }
                    }
                    default         { return [GridConfig $text $start $line $prev] }
                }
            }
        }
        return ""
    }

    proc complete(image) {text start end line pos mod} {
    set sub [Lindex $line 1]
        switch -- $pos {
            1 { return [TrySubCmds $text image] }
            2 {
                switch -- $sub {
                    create { return [CompleteFromList $text [image types]] }
                    delete -
                    height -
                    type   -
                    width  { return [CompleteFromList $text [image names]] }
                    names  {}
                    types  {}
                }
            }
            3 {
                switch -- $sub {
                    create  {
                        set type [Lindex $line 2]
                        switch -- $type {
                            bitmap  {
                                return [CompleteFromList $text \
                                            {?name? -background -data -file
                                             -foreground -maskdata -maskfile}]
                            }
                            photo   {
                                return [CompleteFromList $text \
                                            {?name? -data -format -file -gamma
                                             -height -palette -width}]
                            }
                            default {}
                        }
                    }
                    delete  { return [CompleteFromList $text [image names]] }
                    default {}
                }
            }
            default {
                switch -- $sub {
                    create  {
                        set type [Lindex $line 2]
                        set prev [PreviousWord $start $line]
                        switch -- $type {
                            bitmap {
                                switch -- $prev {
                                    -background -
                                    -foreground { return [DisplayHints <color>] }
                                    -data       -
                                    -maskdata   { return [DisplayHints <string>] }
                                    -file       -
                                    -maskfile   { return "" }
                                    default     {
                                        return [CompleteFromList $text \
                                                    [RemoveUsedOptions $line \
                                                         {-background -data -file
                                                          -foreground -maskdata -maskfile}]]
                                    }
                                }
                            }
                            photo  {
                                switch -- $prev {
                                    -data    { return [DisplayHints <string>] }
                                    -file    { return "" }
                                    -format  { return [DisplayHints <format-name>] }
                                    -gamma   { return [DisplayHints <value>] }
                                    -height  -
                                    -width   { return [DisplayHints <number>] }
                                    -palette {
                                        return [DisplayHints <palette-spec>]
                                    }
                                    default  {
                                        return [CompleteFromList $text \
                                                    [RemoveUsedOptions $line \
                                                         {-data -format -file -gamma
                                                          -height -palette -width}]]
                                    }
                                }
                            }
                        }
                    }
                    delete  { return [CompleteFromList $text [image names]] }
                    default {}
                }
            }
        }
    }

    proc complete(label) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-anchor -background -bitmap -borderwidth -cursor -font
                             -foreground -highlightbackground -highlightcolor
                             -highlightthickness -image -justify -padx -pady -relief
                             -takefocus -text -textvariable -underline -wraplength
                             -height -width}]
            }
        }
        return ""
    }

    proc complete(listbox) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-background -borderwidth -cursor -exportselection -font
                             -foreground -height -highlightbackground -highlightcolor
                             -highlightthickness -relief -selectbackground
                             -selectborderwidth -selectforeground -setgrid -takefocus
                             -width -xscrollcommand -yscrollcommand -height -selectmode
                             -width}]
            }
        }
        return ""
    }

    proc complete(lower) {text start end line pos mod} {
        switch -- $pos {
            1 -
            2 { return [CompleteFromList $text [WidgetChildren $text]] }
        }
    }

    proc complete(menu) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-activebackground -activeborderwidth -activeforeground
                             -background -borderwidth -cursor -disabledforeground
                             -font -foreground -relief -takefocus -postcommand
                             -selectcolor -tearoff -tearoffcommand -title -type}]
            }
        }
        return ""
    }

    proc complete(menubutton) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-activebackground -activeforeground -anchor -background
                             -bitmap -borderwidth -cursor -disabledforeground -font
                             -foreground -highlightbackground -highlightcolor
                             -highlightthickness -image -justify -padx -pady -relief
                             -takefocus -text -textvariable -underline -wraplength
                             -direction -height -indicatoron -menu -state -width}]
            }
        }
        return ""
    }

    proc complete(message) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-anchor -background -borderwidth -cursor -font -foreground
                             -highlightbackground -highlightcolor -highlightthickness
                             -padx -pady -relief -takefocus -text -textvariable -width
                             -aspect -justify -width}]
            }
        }
        return ""
    }

    proc OptionPriority text {
        return [CompleteFromList $text {widgetDefault startupFile userDefault interactive}]
    }

    proc complete(option) {text start end line pos mod} {
        set sub [Lindex $line 1]
        switch -- $pos {
            1 { return [CompleteFromList $text {add clear get readfile}] }
            2 {
                switch -- $sub {
                    add      { return [DisplayHints <pattern>] }
                    get      { return [CompleteFromList $text [WidgetChildren $text]] }
                    readfile { return "" }
                }
            }
            3 {
                switch -- $sub {
                    add      { return [DisplayHints <value>] }
                    get      { return [DisplayHints <name>] }
                    readfile { return [OptionPriority $text] }
                }
            }
            4 {
                switch -- $sub {
                    add      { return [OptionPriority $text] }
                    get      { return [CompleteFromList $text [ClassTable [Lindex $line 2]]] }
                    readfile {}
                }
            }
        }
    }

    proc PackConfig {text line prev} {
        set opts {
            -after -anchor -before -expand -fill
            -in -ipadx -ipady -padx -pady -side
        }
        if {-1 == [string first "-" $line]} {
            set slave [WidgetChildren $text]
        } else {
            set slave ""
        }
        switch -- $prev {
            -after  -
            -before { return [CompleteFromList $text [WidgetChildren $text]] }
            -anchor { return [CompleteAnchor $text] }
            -expand { return [CompleteBoolean $text] }
            -fill   { return [CompleteFromList $text { none x y both }] }

            -ipadx -
            -ipady -
            -padx  -
            -pady  { return [DisplayHints <amount>] }

            -in   { return [CompleteFromList $text [WidgetChildren $text]] }
            -side { return [CompleteFromList $text { left right top bottom }] }

            default {
                return [CompleteFromList $text \
                            [RemoveUsedOptions $line [concat $opts $slave]]]
            }
        }
    }

    proc complete(pack) {text start end line pos mod} {
        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]
        switch -- $pos {
            1 {
                return [CompleteFromList $text \
                            [concat [WidgetChildren $text] \
                                 {configure forget info propagate slaves}]]
            }
            2 {
                switch -- $sub {
                    configure -
                    forget    -
                    info      -
                    propagate -
                    slaves    { return [CompleteFromList $text [WidgetChildren $text]] }
                    default   { return [PackConfig $text $line $prev] }
                }
            }
            default {
                switch -- $sub {
                    configure { return [PackConfig $text $line $prev] }
                    forget    { return [CompleteFromList $text [WidgetChildren $text]] }
                    info      {}
                    propagate {
                        switch -- $pos {
                            3 { return [CompleteBoolean $text] }
                        }
                    }
                    slaves    {}
                    default   { return [PackConfig $text $line $prev] }
                }
            }
        }
        return ""
    }

    proc PlaceConfig {text line prev} {
        set opts {
            -in -x -relx -y -rely -anchor -width
            -relwidth -height -relheight -bordermode
        }
        switch -- $prev {

            -in { return [CompleteFromList $text [WidgetChildren $text]] }

            -x    -
            -relx -
            -y    -
            -rely { return [DisplayHints <location>] }

            -anchor { return [CompleteAnchor $text] }

            -width     -
            -relwidth  -
            -height    -
            -relheight { return [DisplayHints <size>] }

            -bordermode { return [CompleteFromList $text {ignore inside outside}] }

            default { return [CompleteFromList $text [RemoveUsedOptions $line $opts]] }
        }
    }

    proc complete(place) {text start end line pos mod} {
        set sub [Lindex $line 1]
        set prev [PreviousWord $start $line]
        switch -- $pos {
            1 {
                return [CompleteFromList $text \
                            [concat [WidgetChildren $text] \
                                 {configure forget info slaves}]]
            }
            2 {
                switch -- $sub {
                    configure -
                    forget    -
                    info      -
                    slaves    { return [CompleteFromList $text [WidgetChildren $text]] }
                    default   { return [PlaceConfig $text $line $prev] }
                }
            }
            default {
                switch -- $sub {
                    configure { return [PlaceConfig $text $line $prev] }
                    forget    {}
                    info      {}
                    slaves    {}
                    default   { return [PlaceConfig $text $line $prev] }
                }
            }
        }
        return ""
    }

    proc complete(radiobutton) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-activebackground -activeforeground -anchor -background
                             -bitmap -borderwidth -cursor -disabledforeground -font
                             -foreground -highlightbackground -highlightcolor
                             -highlightthickness -image -justify -padx -pady -relief
                             -takefocus -text -textvariable -underline -wraplength -command
                             -height -indicatoron -selectcolor -selectimage -state -value
                             -variable -width}]
            }
        }
        return ""
    }

    proc complete(raise) {text start end line pos mod} {
        return [complete(lower) $text $start $end $line $pos $mod]
    }

    proc complete(scale) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-activebackground -background -borderwidth -cursor -font
                             -foreground -highlightbackground -highlightcolor
                             -highlightthickness -orient -relief -repeatdelay
                             -repeatinterval -takefocus -troughcolor -bigincrement
                             -command -digits -from -label -length -resolution
                             -showvalue -sliderlength -sliderrelief -state -tickinterval
                             -to -variable -width}]
            }
        }
        return ""
    }

    proc complete(scrollbar) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-activebackground -background -borderwidth -cursor
                             -highlightbackground -highlightcolor -highlightthickness
                             -jump -orient -relief -repeatdelay -repeatinterval
                             -takefocus -troughcolor -activerelief -command
                             -elementborderwidth -width}]
            }
        }
        return ""
    }

    proc SelectionOpts {text start end line pos mod lst} {
        set prev [PreviousWord $start $line]
        if {-1 == [lsearch $lst $prev]} {
            set prev "" ;# force the default arm
        }
        switch -- $prev {
            -displayof { return [CompleteFromList $text [WidgetChildren $text]] }
            -selection {
                variable selection-selections
                return [CompleteFromList $text ${selection-selections}]
            }
            -type      {
                variable selection-types
                return [CompleteFromList $text ${selection-types}]
            }
            -command   {
                return [BraceOrCommand $text $start $end $line $pos $mod]
            }
            -format    {
                variable selection-formats
                return [CompleteFromList $text ${selection-formats}]
            }
            default    {
                return [CompleteFromList $text [RemoveUsedOptions $line $lst]]
            }
        }
    }

    proc complete(selection) {text start end line pos mod} {
        switch -- $pos {
            1       { return [TrySubCmds $text [Lindex $line 0]] }
            default {
                set sub [Lindex $line 1]
                set widgets [WidgetChildren $text]
                switch -- $sub {
                    clear  {
                        return [SelectionOpts $text $start $end $line \
                                    $pos $mod {-displayof -selection}]
                    }
                    get    {
                        return [SelectionOpts $text $start $end $line \
                                    $pos $mod {-displayof -selection -type}]
                    }
                    handle {
                        return [SelectionOpts $text $start $end $line $pos $mod \
                                    [concat {-selection -type -format} $widgets]]
                    }
                    own    {
                        return [SelectionOpts $text $start $end $line $pos $mod \
                                    [concat {-command -selection} $widgets]]
                    }
                }
            }
        }
    }

    proc complete(send) {text start end line pos mod} {
        set prev [PreviousWord $start $line]
        if {"-displayof" == $prev} {
            return [TryFromList $text [WidgetChildren $text]]
        }
        set cmds [RemoveUsedOptions $line {-async -displayof --} {--}]
        if {[llength $cmds]} {
            return [string trim [CompleteFromList $text [concat $cmds <app>]]]
        } else {
            if {[regexp -- --$ $line]} {
                return [list {--}]; # append a blank
            } else {
                # TODO make this better!
                return [DisplayHints [list {<app cmd ?arg ...?>}]]
            }
        }
        return ""
    }

    proc complete(text) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-background -borderwidth -cursor -exportselection -font
                             -foreground -highlightbackground -highlightcolor
                             -highlightthickness -insertbackground -insertborderwidth
                             -insertofftime -insertontime -insertwidth -padx -pady
                             -relief -selectbackground -selectborderwidth
                             -selectforeground -setgrid -takefocus -xscrollcommand
                             -yscrollcommand -height -spacing1 -spacing2 -spacing3
                             -state -tabs -width -wrap}]
            }
        }
        return ""
    }

    proc complete(tk) {text start end line pos mod} {
        switch -- $pos {
            1       { return [TrySubCmds $text [Lindex $line 0]] }
            default {
                switch -- [Lindex $line 1] {
                    appname { return [DisplayHints ?newName?] }
                    scaling {
                        switch -- [PreviousWord $start $line] {
                            -displayof {
                                return [TryFromList $text [WidgetChildren $text]]
                            }
                            default    {
                                return [CompleteFromList $text \
                                            [RemoveUsedOptions $line {-displayof ?number?}]]
                            }
                        }
                    }
                }
            }
        }
    }

    # proc complete(tk_bisque) {text start end line pos mod} {
    # }

    proc complete(tk_chooseColor) {text start end line pos mod} {
        switch -- [PreviousWord $start $line] {
            -initialcolor { return [CompleteColor $text] }
            -parent       { return [TryFromList $text [WidgetChildren $text]] }
            -title        { return [DisplayHints <string>] }
            default       {
                return [TryFromList $text \
                            [RemoveUsedOptions $line {-initialcolor -parent -title}]]
            }
        }
    }

    proc complete(tk_dialog) {text start end line pos mod} {
        switch -- $pos {
            1       { return [CompleteFromList $text [ToplevelWindows]] }
            2       { return [DisplayHints <title>] }
            3       { return [DisplayHints <text>] }
            4       { return [CompleteFromBitmaps $text] }
            5       { return [DisplayHints <defaultIndex>] }
            default { return [DisplayHints ?buttonName?] }
        }
    }

    proc complete(tk_focusNext) {text start end line pos mod} {
        switch -- $pos {
            1 { return [CompleteFromList $text [WidgetChildren $text]] }
        }
    }

    proc complete(tk_focusPrev) {text start end line pos mod} {
        switch -- $pos {
            1 { return [CompleteFromList $text [WidgetChildren $text]] }
        }
    }

    # proc complete(tk_focusFollowsMouse) {text start end line pos mod} {
    # }

    proc GetOpenSaveFile {text start end line pos mod {add ""}} {
        # enable filename completion for the first four switches.
        switch -- [PreviousWord $start $line] {
            -defaultextension {}
            -filetypes        {}
            -initialdir       {}
            -initialfile      {}
            -parent           { return [CompleteFromList $text [WidgetChildren $text]] }
            -title            { return [DisplayHints <titleString>] }
            default           {
                return [CompleteFromList $text \
                            [RemoveUsedOptions $line \
                                 [concat {-defaultextension -filetypes
                                          -initialdir -parent -title} $add]]]
            }
        }
    }

    proc complete(tk_getOpenFile) {text start end line pos mod} {
        return [GetOpenSaveFile $text $start $end $line $pos $mod]
    }

    proc complete(tk_getSaveFile) {text start end line pos mod} {
        return [GetOpenSaveFile $text $start $end $line $pos $mod -initialfile]
    }

    proc complete(tk_messageBox) {text start end line pos mod} {
        switch -- [PreviousWord $start $line] {
            -default { return [CompleteFromList $text {abort cancel ignore no ok retry yes}] }
            -icon    { return [CompleteFromList $text {error info question warning}] }
            -message { return [DisplayHints <string>] }
            -parent  { return [CompleteFromList $text [WidgetChildren $text]] }
            -title   { return [DisplayHints <titleString>] }
            -type    {
                return [CompleteFromList $text \
                            {abortretryignore ok okcancel
                             retrycancel yesno yesnocancel}]
            }
            default  {
                return [CompleteFromList $text \
                            [RemoveUsedOptions $line \
                                 {-default -icon -message
                                  -parent -title -type}]]
            }
        }
    }

    proc complete(tk_optionMenu) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            2       { return [VarCompletion $text #0] }
            3       { return [DisplayHints <value>] }
            default { return [DisplayHints ?value?] }
        }
    }

    proc complete(tk_popup) {text start end line pos mod} {
        switch -- $pos {
            1 {
                # display only menu widgets
                #
                set widgets [WidgetChildren $text]
                set menu_widgets ""
                foreach widget $widgets {
                    if {"Menu" == [winfo class $widget]} {
                        lappend menu_widgets $widget
                    }
                }
                if {[llength $menu_widgets]} {
                    return [TryFromList $text $menu_widgets]
                } else {
                    return [DisplayHints <menu>]
                }
            }
            2 { return [DisplayHints <x>] }
            3 { return [DisplayHints <y>] }
            4 { return [DisplayHints ?entryIndex?] }
        }
    }

    # TODO: the name - value construct didn't work in my wish.
    #
    proc complete(tk_setPalette) {text start end line pos mod} {
        set database {
            activeBackground        foreground              selectColor
            activeForeground        highlightBackground     selectBackground
            background              highlightColor          selectForeground
            disabledForeground      insertBackground        troughColor
        }
        switch -- $pos {
            1       { return [CompleteColor $text $database] }
            default {
                switch [expr {$pos % 2}] {
                    1 { return [CompleteFromList $text $database] }
                    0 { return [CompleteColor $text] }
                }
            }
        }
    }

    proc complete(tkwait) {text start end line pos mod} {
        switch -- $pos {
            1 { return [CompleteFromList $text {variable visibility window}] }
            2 {
                switch [Lindex $line 1] {
                    variable   { return [VarCompletion $text #0] }
                    visibility -
                    window     { return [TryFromList $text [WidgetChildren $text]] }
                }
            }
        }
    }

    proc complete(toplevel) {text start end line pos mod} {
        switch -- $pos {
            1       { return [EventuallyInsertLeadingDot $text <pathName>] }
            default {
                return [CompleteWidgetConfigurations $text $start $line \
                            {-borderwidth -cursor -highlightbackground -highlightcolor
                             -highlightthickness -relief -takefocus -background
                             -class -colormap -container -height -menu -screen
                             -use -visual -width}]
            }
        }
        return ""
    }

    proc complete(winfo) {text start end line pos mod} {
        set sub [Lindex $line 1]
        switch -- $pos {
            1       { return [TrySubCmds $text winfo] }
            2       {
                switch -- $sub {
                    atom       { return [TryFromList $text {-displayof <name>}] }
                    containing { return [TryFromList $text {-displayof <rootX>}] }
                    interps    { return [TryFromList $text -displayof] }
                    atomname   -
                    pathname   { return [TryFromList $text {-displayof <id>}] }
                    default    { return [TryFromList $text [WidgetChildren $text]] }
                }
            }
            default {
                switch -- $sub {
                    atom             {
                        switch -- [PreviousWord $start $line] {
                            -displayof { return [TryFromList $text [WidgetChildren $text]] }
                            default    { return [DisplayHints <name>] }
                        }
                    }
                    containing       {
                        switch -- [Lindex $line 2] {
                            -displayof {
                                switch -- $pos {
                                    3 { return [TryFromList $text [WidgetChildren $text]] }
                                    4 { return [DisplayHints <rootX>] }
                                    5 { return [DisplayHints <rootY>] }
                                }
                            }
                            default    { return [DisplayHints <rootY>] }
                        }
                    }
                    interps          {
                        switch -- [PreviousWord $start $line] {
                            -displayof { return [TryFromList $text [WidgetChildren $text]] }
                            default    {}
                        }
                    }
                    atomname         -
                    pathname         {
                        switch -- [PreviousWord $start $line] {
                            -displayof { return [TryFromList $text [WidgetChildren $text]] }
                            default    { return [DisplayHints <id>] }
                        }
                    }
                    visualsavailable { return [DisplayHints ?includeids?] }
                    default          { return [TryFromList $text [WidgetChildren $text]] }
                }
            }
        }
        return ""
    }

    proc complete(wm) {text start end line pos mod} {
        set sub [Lindex $line 1]
        switch -- $pos {
            1 {
                return [CompleteFromList $text \
                            {aspect client colormapwindows command deiconify focusmodel
                             frame geometry grid group iconbitmap iconify iconmask iconname
                             iconposition iconwindow maxsize minsize overrideredirect
                             positionfrom protocol resizable sizefrom state title transient
                             withdraw}]
            }
            2 { return [TryFromList $text [ToplevelWindows]] }
            3 {
                switch -- $sub {
                    aspect           { return [DisplayHints ?minNumer?] }
                    client           { return [DisplayHints ?name?] }
                    colormapwindows  {
                        return [CompleteListFromList $text \
                                    [string trimleft [IncompleteListRemainder $line]] \
                                    [WidgetChildren .] \{ { } \}]
                    }
                    command          { return [DisplayHints ?value?] }
                    focusmodel       { return [CompleteListFromList $text {active passive}] }
                    geometry         { return [DisplayHints ?<width>x<height>+-<x>+-<y>?] }
                    grid             { return [DisplayHints ?baseWidth?] }
                    group            { return [TryFromList $text [WidgetChildren $text]] }
                    iconbitmap       -
                    iconmask         { return [CompleteFromBitmaps $text] }
                    iconname         { return [DisplayHints ?newName?] }
                    iconposition     { return [DisplayHints ?x?] }
                    iconwindow       { return [TryFromList $text [WidgetChildren $text]] }
                    maxsize          -
                    minsize          { return [DisplayHints ?width?] }
                    overrideredirect { return [CompleteBoolean $text] }
                    positionfrom     -
                    sizefrom         { return [CompleteFromList $text {position user}] }
                    protocol         {
                        return [CompleteFromList $text \
                                    {WM_TAKE_FOCUS WM_SAVE_YOURSELF WM_DELETE_WINDOW}]
                    }
                    resizable        { return [DisplayHints ?width?] }
                    title            { return [DisplayHints ?string?] }
                    transient        { return [TryFromList $text [WidgetChildren $text]] }
                    default          { return [TryFromList $text [ToplevelWindows]] }
                }
            }
            4 {
                switch -- $sub {
                    aspect       { return [DisplayHints ?minDenom?] }
                    grid         { return [DisplayHints ?baseHeight?] }
                    iconposition { return [DisplayHints ?y?] }
                    maxsize      -
                    minsize      { return [DisplayHints ?height?] }
                    protocol     {
                        return [BraceOrCommand $text $start $end $line $pos $mod]
                    }
                    resizable    { return [DisplayHints ?height?] }
                }
            }
            5 {
                switch -- $sub {
                    aspect { return [DisplayHints ?maxNumer?] }
                    grid   { return [DisplayHints ?widthInc?] }
                }
            }
            6 {
                switch -- $sub {
                    aspect { return [DisplayHints ?maxDenom?] }
                    grid   { return [DisplayHints ?heightInc?] }
                }
            }
        }
        return ""
    }

    # ==== ObjCmd completers ==========================
    #
    # @note when a proc is commented out, the fallback
    #       completers do the job rather well.
    #
    # =================================================


    # proc ButtonObj {text start end line pos} {
    #   return ""
    # }
}
