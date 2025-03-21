unit grammar Chess::PGN;

rule TOP { ^ <game>+ $ }

rule game {
  [ <info>* <move>+ | <info>+ ] <adjudication>?
  <?{ [&&] $<move>»<move-number>».made Z== 1..* }>
}

rule info { '[' ~ ']' [ <tag> <string> ] }
token tag { <.alpha>+ }
rule string { '"' ~ '"' <print>* }

rule move {
  <move-number> [ <half-move> <nag> *  <comment> * ] ** 1..2
}
token half-move {
    [
	|| <castle>
	|| <promotion>
	|| <piece-moves>
	|| <pawn-moves>
    ]< + ++ # >?<annotation>?
}
token annotation { < ?? ? !? ?! ! !! > }
token nag { '$'<.digit>+ }
rule comment { 
    | '{' .+? '}' 
    | '(' <move>+ ')'
}

token pawn-moves { [<file>x]?<square> }
token piece-moves { <piece><disambiguation>??x?<square> }
token castle     { [ 'O-O' '-O'? | 'o-o' '-o'? ] }
token promotion  { <pawn-moves>'='<piece> }

token disambiguation { <file> | <rank> | <file><rank> }

token move-number { (<digit>+)< . ... > { make +$0 } }

token adjudication { <white-wins> | <black-wins> | <draw> | <aborted-game> }
token white-wins { '1-0' }
token black-wins { '0-1' }
token draw       { '1/2-1/2' | \c[VULGAR FRACTION ONE HALF] ** 2 % '-' }
token aborted-game { '*' }

token piece { <[KQRBN]> }
token rank  { <[1..8]> }
token file  { <[a..h]> }
token square { <file> <rank> }


# vi: shiftwidth=2
