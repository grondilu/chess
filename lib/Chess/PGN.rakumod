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
rule movetext-section { <move>+ }

regex tag-pair { \[ ~ \] [\s*<name=symbol>\s*<value=string>\s*] }

rule move {
  <move-number-indication>?\h*<SAN><[+#]>?[<[!?]> ** 1..2]? <NAG> * <RAV> *
}

rule RAV { \( ~ \) <move>* }
rule move-number-indication { <integer>\.* }

token SAN {
  <castle> |
  <promotion> |
  <piece-move> |
  <pawn-move>
}
token pawn-move { [<file>x]?<square> }
rule piece-move { <piece><disambiguation>??x?<square> }
token castle     { O ** 2..3 % \- }
token promotion  { <pawn-move>'='<piece> }

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

token string { '"' ~ '"' [ '\"' | '\\' | <.print> ] **? 0..255 }
token symbol { <alnum> <symbol-continuation-character> ** 0..254 }
token integer { \d ** 0..255 }

token symbol-continuation-character { <+alnum+[+\#=:-]> }
token NAG { '$'<.digit>+ }


# vi: shiftwidth=2
