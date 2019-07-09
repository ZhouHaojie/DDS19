

## MAP For state
set enums [list]
lappend enums 0000000000000000 IDLE
lappend enums FFFFFFFFFFFFFFFF BUSY
lappend enums 3000000000000000 OTHER
lappend enums 0123456789ABCDEF HEXSTATE
lappend enums 1111111111111111 "All 1s"
set which_f [ gtkwave::setCurrentTranslateEnums $enums ]
gtkwave::installFileFilter $which_f