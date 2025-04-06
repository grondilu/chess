unit grammar Chess::UCI;
# https://gist.github.com/aliostad/f4470274f39d29b788c1b09519e67372

token square { <[a..h]><[1..8]> }
token natural-integer { 0 | <[1..9]><[0..9]>* }
token relative-integer { '-'?<natural-integer> }
token move { <square>**2 <promotion=[qbnr]>? }

rule best-move { bestmove <(<move>)> [ ponder <move> ]? }

rule depth    { depth    <(<.natural-integer>)> }
rule seldepth { seldepth <(<.natural-integer>)> }
rule time     { time     <(<.natural-integer>)> }
rule pv       { pv       <(<.move> +)>          }
rule multipv  { multipv  <(<.natural-integer>)> }
rule hashfull { hashfull <(<.natural-integer>)> }
rule score    { score  [ <(<cp> | <mate> | <bound>)> ] }
rule cp       { cp       <(<.relative-integer>)> }
rule mate     { mate     <(<.natural-integer>)> }
rule bound    { < lowerbound upperbound >       }
rule currmove { currmove <(<.move>)>            }
rule nps      { nps      <(<.natural-integer>)> }
rule tbhits   { tbhits   <(<.natural-integer>)> }
rule nodes    { nodes    <(<.natural-integer>)> }
rule currline { currline <(<natural-integer> <move> +)> }

rule info {
	info [
		| <depth>
		| <seldepth>
		| <time>
		| <pv>
		| <multipv>
		| <score>
		| <hashfull>
		| <currmove>
		| <nps>
		| <tbhits>
		| <nodes>
		| <currline>
	]+
}

