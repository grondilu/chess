unit module Chess::Openings;
use Chess::PGN;
# https://github.com/lichess-org/chess-openings.git
#

our constant @data = [
    %?RESOURCES<chess-openings/a.tsv>,
    %?RESOURCES<chess-openings/b.tsv>,
    %?RESOURCES<chess-openings/c.tsv>,
    %?RESOURCES<chess-openings/d.tsv>,
    %?RESOURCES<chess-openings/e.tsv>
]
    .map(*.slurp).join
    .lines
    .grep(none /^eco/)
    .map(*.split("\t"))
    .map(*.Array)
    .map:
	{
	    .splice(
		2, 1, .tail.comb(/<Chess::PGN::SAN>/).join
	    );
	    $_ 
	}
;

our sub identify(Str $compacted-moves) {
    return Hash.new: <ECO name> Z=>
    @data
    .grep({ .[2] eq $compacted-moves.substr(0, .[2].chars) })
    .max(:by({ .[2].chars }))
    .head(2)
}

# vi: shiftwidth=4 nowrap
