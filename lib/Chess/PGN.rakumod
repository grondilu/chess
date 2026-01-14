unit grammar Chess::PGN;
# https://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm

# treating comments as white space
token ws {
  <!ww>
  [ <comment> | \s ]*
}
rule comment { 
  \{ ~ \} [<+print-[}]>* % \s*] |
  \; <.print>* $$
}

rule TOP { ^ <game>* $ }

rule game { <tag-pair-section> <movetext-section> <game-termination> }

rule tag-pair-section { <tag-pair>* % \s* }
rule movetext-section { <annotated-move>+ }

regex tag-pair { \[ ~ \] [\s*<name=symbol>\s*<value=string>\s*] }

rule annotated-move {
  <move-number-indication>?\h*<move><annotation>? <NAG> * <RAV> *
}

proto
token move               {*}
token move:sym<LAN>      { <from=square><to=square><promotion-piece>? }
token move:sym<pawn>     { [<file>x]?<to=square>['='<promotion-piece>]? }
token move:sym<piece>    { <piece>:!ratchet<disambiguation>??x?<to=square> }
token move:sym<XOLALG>   { <piece>?<from=square><[-x]><to=square>'ep'?<promotion-piece>? }
token move:sym<castle>   { O ** 2..3 % \- }

token SAN { O**2..3%'-'|<piece>:!ratchet<disambiguation>?x?<square>|[<file>x]?<square>['='<promotion-piece>]? }

proto
token annotation {*}
token annotation:sym<check>     { '+' }
token annotation:sym<checkmate> { '#' }
token annotation:sym<comment>   { <[!?]>**1..2 }

rule RAV { \( ~ \) <move>* }
rule move-number-indication { <integer>\.* }

token promotion-piece { <[QBNR]> }

token disambiguation { <file> | <rank> | <square> }

token game-termination { <white-wins> | <black-wins> | <draw> | <aborted-game> }
token white-wins { '1-0' }
token black-wins { '0-1' }
token draw       { '1/2-1/2' | \c[VULGAR FRACTION ONE HALF] ** 2 % '-' }
token aborted-game { '*' }

token piece { <[KQRBN]> }
token rank  { <[1..8]> }
token file  { <[a..h]> }
token square { <file> <rank> }

token string { '"' ~ '"' [ '\"' | '\\' | <+graph+space+[`\'+-]-[\"]-cntrl> ] **? 0..255 }
#token string { '"' ~ '"' [ '\"' | '\\' | <+print-[\"]> ] **? 0..255 }
token symbol { <alnum> <symbol-continuation-character> ** 0..254 }
token integer { \d ** 0..255 }

token symbol-continuation-character { <+alnum+[+\#=:-]> }
token NAG { '$'<.digit>+ }


# vi: shiftwidth=2
