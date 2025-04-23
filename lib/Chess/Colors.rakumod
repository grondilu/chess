unit module Chess::Colors;

enum color is export <black white>;

multi prefix:<¬>(color $color --> color) is export { $color ~~ white ?? black !! white }
