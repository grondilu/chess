grammar Chess::PGN;

rule TOP { ^ <game>+ $ }

rule game { <info>* <move>+ <adjudication>? }

rule info { '[' ~ ']' [ <tag> <string> ] }
token tag { <.alpha>+ }
token string { '"' .+? '"' }

rule move { <move-number> [ <single-move> <long-comment>? ] ** 1..2 }
token single-move {
    [
	| <pawn-moves>
	| <pawn-takes>
	| <piece-moves>
	| <piece-takes>
	| <castle>
	| <promotion>
    ]< + ++ # >?<comment>?
}
token comment { < ?? ? !? ?! ! !! > }
token long-comment { '{' .+? '}' }

token pawn-moves { <square> }
token pawn-takes { <file>'x'<square>'ep'? }
token piece-moves { <piece><disambiguation>??<square> }
token piece-takes { <piece><disambiguation>??'x'<square> }
token castle     { 'O-O' | 'O-O-O' }
token promotion  { [ <pawn-moves> | <pawn-takes> ]'='<piece> }

token disambiguation { <file> | <rank> }

token move-number { <.digit>+\. }

token adjudication { <white-wins> | <black-wins> | <draw> }
token white-wins { '1-0' }
token black-wins { '0-1' }
token draw       { '1/2-1/2' }

token piece { < K Q R B N > }
token rank  { < 1 2 3 4 5 6 7 8 > }
token file  { < a b c d e f g h > }
token square { <file><rank> }
