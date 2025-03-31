unit module Chess::Polyglot;
# http://hgm.nubati.net/book_format.html

our constant $Random64 = Blob[uint64].new: map *.parse-base(36), <
	2E2N45RBYICE9 NISIPF0NTHON 11P1IJC0Y1V0N 2DG844O58KMHU 1SC08HZSUAYRT ROKCX8X58DZ3 8M2RLDKOV4VT 3J4W5G69Y177U
	7DY3FMGWF95C E91ZHPTGLNVX 2A4QD1N9LWGC0 35XZVF7W5FXZP ZFYXPUMLOXTE L735SU454T1 1FASJ1ZJXG4X1 JI2YDR1BC34C
	36OJBLLYOVC1 1KQ9F78W4U8A9 1RNV9WKSGOTU3 1WGXTZSWAZNXS 1ZLGS43DBBMX8 3P3RFNOVY46LO RYPN6HIX5GIU 15FYQCDXZ0V2B
	2LA76X4C781KS 25LI33PXGBOCR 22CTO0DU5Y9LJ E7HC14XHGMHT 2QWPVVCOODJ9B 1VCJC81I2C4AS 326QT6S0KCNZ1 K2MM5R17BWN4
	15Y3U7A3WD1DZ BAZSCBFOOS3L 2JHGC5VTA2D8Z 1SPL0XKNTR0V 1IGMNCNG8XR9C 5DIUYEDI5N6C T9LAP1IU07QZ 1R5QELQPRIXPF
	DDTCYVHG9MVF HEN8FM310GYV 37JSBYVRTPVMD 2WW1Z457J12KK 2FANIS7NH84YS 18UJTZFHTMZW5 1EN95Q3XDUGOQ 3UHNBEOY9Y2IP
	RJV8PA1Q8YCE 24W6PY03PTK6T 2TOL6OSXFW4X3 1XI3SQFXNZHGG 9RG13NXBPZ7J 1JIN9U78TMXXF 16MUUFJYRFE0O 2AKSVXZ8FZTCT
	10M6L4OCW7GHB 1NRLXH6KOS675 10F8KGGXTU5OX 1G1HMP0QGE8QE VQIUUGPNLCW8 28WDMFQZ3J0JV 1IO3LJFAGI6WO 3L8Z1AY064LTI
	19MFFK893FHL3 4DBXKXZR8E9U 1840R78FEEEZI 1VRU7JDGUJEPO E85MA84PYBBO 1IGKPB9LBZ7Q1 1ZBS4QDOIWNP3 1UM32KFYK0QG8
	BBGVSJP3EEEU 3O34MF29FSVIT 3BR6JSW0RWSFW K4KWRJ1XOKQE 2ULZAKYINCKQ2 71XMKY9PP4NT 2I49X5CC82HFO 3JW7KW49198OP
	LUE4VQUPCPBZ 20XE1MNUHSQUP 1ADDF33XF8WAB 1QSEXUAP2X1RF 3MM4OEL4ES0G7 2CLEP7BJHHPY9 1POMF4IVA88AD 3SPN4U2HU1IGY
	22AI4IDVAKGQ9 2HGEZ1B019FP4 2NF12CR3PA1V6 DR8GV6CDU6YL 22BCYJ6T66L7T 500ELLVKLDND 3VMAL5VQSRKK0 25OTZX6LH2T72
	2DG8RH75EP5ZD 2QIH3QVUECB1P V8HSEK3NKZM3 1ED2ZA0SARNC9 GGI4NQ890J2C 2CK3L3J3N0BEB 17IWK6U0RZZT0 1I7IMN39P5BYC
	IB5FOQ64FSI0 1E5FVYIDDDTL8 180WABYY0B4G2 DEZM9XMCUZ86 1JASP9DL5Y81W 3EJAO72KA6ZS7 3N5ME9Q1P425U 1VG2QEHFGR2EK
	2TTLFRYN6L2KJ 33GWG63M9SON 2RDRJXVD5N0C5 14RFYN7XU8SFR 35H2Z90M06SUI 3Q8XQ38K18GTG X3VKL1ZZ1O5B 3M8OZWDECMJKT
	1UKXRJFSTBRXT 21JD9FJ2WXZM4 2B4K65N8XJJOZ 2GU7D7H0CPICY 2BQU0LB9QJS0 27YJP815MJTEM 1PTGAKFRJR83W 1RAX7G7369SXP
	1B84JRIA0SMTP 3N7LWSYVFJV5T 2UG2E1O3OCXBJ 12AIR86FN3PM0 28ICMTA12RN8I 3VTM6XEJ0V069 2NGUOF92XY5PS 3D306WAEB7HTO
	1XHJ1JR2H5AL5 J5O5AV55EVBW 3239MA8J0K9IH 1YDGKSS7GRP0L 3DYF3PG05ORG6 FAG0ZPZLFTAA 10UWOV9JLX7NM 2LE1R8A0ZSBCQ
	2K8AGOIQJWL7A 1JLYYS61Q80BY 3DZJ3GXG7K3CM IKWDBBENL3S5 2QL784EFSH5J0 27RXKX2N60PJK 97CGOLQ2R2OA M9STQKGF60NX
	30AARPVN6W8D2 1B8JWDHBOC7Y9 OPR9U41YCR77 2DA1HJSH1OSLW 3MXYPMUDT9EIK 2NVHASZW9T8BC 13FBUXQVN96WA 2NS1R66KJR6TF
	E2975YNADW1R 192YX5PZMNNEO 3Q3EDU7LMM0OG 9FBOYVCRK0KZ 2VEWFWL9GUCYD 2EAVNXT4LRRKF 3ITWM01KXHQV 16KPQC712VZ8C
	18CO4QAS0INK3 2XDGC0MH0RB1W 2QS2TNSZNUYRG 2Q9T43PC2B153 IEPAALT06PEO P5GZY1HXLPOV 1SQ9107IYJQWT 3RJDZV8QGC0PS
	39SGLNSHW01TD 3DN997JQ5JPE3 6JRYUQHBX9UR OAL7XOW20WJ7 13L8SMN8F89D0 35QS4WIUUOD23 2OJU5D9HVZM3D 2CSH86F3LW5IG
	2IBMJIYIXHGWA 3IN85WWEFB3P2 1LVOF8FCTVFNI 3SPF3UKEJ3YJA 3U6R6ZF3TBX8B 2DMKAYD2Y4MC7 2664JZ2D2S1XS 1KEA1UX2R8JUM
	3004HVD3DGAXA 1U6JD5F4JWHB2 3VDUKLIFPY5MI 4S8GN17X63V9 28IUCT5TCJJRI 291C3LGRHQ6B9 3E5ADABF8855C WP5F2ZYJPOYL
	37CXQFTGHG3LR 3RKIDEACUM5MG 3A872QVF7VKAP 3AZTY0U0WQOPZ S5PFV1F974RR 2JK9ZZUU086SX 2H7QDJZLCPCXH 17C8J6XV40DRN
	22CXR490I3MU1 CFWL6CUM43S1 1VON8QS2SNG3Y 3PDZSZ36MWOSS VKZT7PUB72JM 3UC1XUW764XES DOHA3TH0IJ6C 15M9JF37KSLAB
	ZIMSLGYC47IL 256VOEXHPS7NL 1LD9ACMXHDVOF 1UUTN0AK67E8Y 2E0I60HSWR0J3 UOZ92NWZ6W82 RE5BV8HECOMP TG5QK95M1ZEY
	2KJLPVGG80X4H 1THSU382B39OD 18H6ZWZKGM88H 10VZYDT1XT442 3AXT8JAIQ7K9N 1975BOODTU3Y3 199B617M15CW9 2E0JTR9CNWCQB
	1QIGS16K0D3K8 FWYNVQI4OOLZ 1UV9EUAIO2LYA 29CA0L4FVSUU 1DB2YNYDGQHSW 719ANDUBAQAG 1BMF9FWSL0N64 M28DWSYWM84U
	2QFUWN7GTNT7 1RLQQKEZL0BCZ 2CMOHYAE54TVG 22IHBME59EQCI 1816M9QZHD25G 2OEKKUIISNDYX 84OJ7GSKHN5Q 1FHZDKIRX2BNO
	3QXKMAF8O9UUM F2FMJV5H7OHX 3BQS7MOUQ70GX 75U4HCC4JOD1 2K6V1KZTHLQU1 28W9ABNSFE1VF 2C98U4PAF7WHD 13UPY65VEASEY
	1XUY8YS73USOF 1CDXO5O1W0AOX OJASDBSXKCOJ 37Q75E9H87PNA 71Y87P0T9O19 EIARNY69K1TT 273TN9769J2SE 17V3NK4AQPP1J
	UBJCSBKAJH0P 29U3H4N23ELHQ VZF7MDMMQHE2 38DOO6JTZFYH1 4OLO1ZI3K5B4 3SGN23GQ7IPQ0 1N93WY2CCLL1V TQDL8J0LG5KE
	396TGGOKFERKY 1BEI1QCP25O74 CKGCU5ZY92NJ 3MWALW5GTKTJN 1B9K1TS08IHPK 3LL64TJX7STX1 2U95UB4FM3TCB 2Q54IAKT441UA
	1JQTVTN2UQNCT 2QXPOHID2E76Q 2QM5Q1R9W06UF 3VM60YT07T59 1UTZ8NSAQUZ91 2V26IBN11M18Y 1D4C8NK3A80FC 2BT6KI1SWXAV8
	1OWQUSO1GRC3D RKAI5GA1CZH0 36CY54OBXJIV7 1BA179LYC721Z QSWGALVLQ9LG 3AHYT4SBIHZRJ 1VSVQM02X7HRW 31ES3XMJCTMDW
	29ABQ597AA9TO 31X79RIHFII5B W33P87Q2WIX6 3B55RZ246RUG4 8NSZK4CIZMQ2 2QIHKCPHBVCMX 2OGEYQNR6OH38 THL1211EPO6N
	3K3186W2QNY32 3L6TY6WH4HEFT 2841LEPC5EDTS 2TN9Q6YSV78C3 1LLH8PXSJA72P 30HPH8ORRU7R3 34DL7XKC40INE 2UVDNPRFVGM2Z
	3CQ21Y99WNS4W 2U4CE1EIWPM0O 2HN0FUADOJFM3 3K32F0P5SFMLD 5CRL2WJWBX9R 20WVQB2WX34Y1 1YN0NR3E3Z51Y 57Y6QS9UYFLS
	JJW4IMMZF5J3 2YUXHFI7BQ8WT 12WZTZQGXZ37U 2KFNONCZVO68D 2ZDI07S04X4R 2RCVVM2TWCBLZ 3JH5TJ2QDSA4F Q7WP5VA5XI6O
	9EURZX0I2HLC 1XXP8E24VYJFW CO7F8N1U1ZB4 2AABXUYKDBCP3 Y1A6H6U2DOBX 2W9KQWCN5I9BG 3RYQN410WQSVR 142TNSBCT5AY9
	GBKHS3Q2JX4A HEK3B7JYW51H 3U85AC0KYMVI2 DHU3IC3K3OHP 3447G3812HPQL WRPXMLTS6BDY 2LB4Q2CGL9NS2 3JPYLSUE04P6N
	2SJ1BAN09Y7HQ 38J4GOTXEKEJX P8HX0VSSNLUW P46AYR8HZVH8 2TOY6PDON10N2 1J2HS6KNYSK80 298GB600RJ0QS 3CB0NB9D963Q1
	377O1GTRV4A3Z 1X8CMDQ09DDN1 1NMRZBKM8LT7V 2B7FYTVQWDPUS 1VLC2WD0POUTU 20YRWN6Z4RPUC 1UKK75YAJD1AJ 35V8DM92T5NHG
	1ZHO6FAGN4WRB 28GRHGYLIT81D 1IOK4GXS3HATF 30NL4OXWJJCPO 1CF8WE1KC9DYF 57DHJRHT2NAL 2F9GZLBK0NQ68 2FKESO39379YN
	3H2XQNSYLNO98 3IZCKZTVURLCD 1BHR2PJNA6I9Q 1AOJBIG56DSDR 1VH03I46G7QBZ 9WDXJ0TWSLEF 1XP8F42EBZ63R 1V1KMFQ8W4BO3
	XKYD8R68WGFT 23LV0HEXXUY0K 1VHV6KREPHJS2 29KNNU62835DV 16IJD6COJY6JT WPULR2LH8IQF 1EXO5NRRBVHE9 1XV2X1CT5IR6V
	3BGY27802B06P 3CWXLPBFCW8PX TUD1TXFNC1S7 34ZZFMTJDYGZT 2LXAIH2SNKI0K 10ZYSTU6FVY79 2QNWQM14MXMG9 98C6Z6KY39G2
	3CB58K8OC57SV 2CZIE76FWT6RM 2RWGN6QG3MIYS 2X097ROOE4K0G 2KK3MXNV890HP HIMT7GW8DAO5 2M7BYVAZEK4PZ 2NTOFAYSLGPBX
	ET3TV8IPEFK4 2RA657BI2HTF6 2Z0NP2B4BFUEY 2Z48TBNA47Z6X 3PFECXGCNHQM7 2FGS9VZ9NWS7U 1KI9A5KFGR9VV 1O4VY8VLVC75I
	2HAHB6LNIP9O1 3YDS589F43FI 23UR31HZWOSDH 3FHOXARZ7SQUT 1RWZVEJFB2L8E 16MD2WU3NTXU2 2E178V42ANJFW 1RN70OOK0BVNI
	AICNZMKMEJZ3 39KDE6X6SVTQ8 13JE3GQNV0UBZ GGVTIZ5GZYLM 26KHR0YS6M4LB 1QU7MLMW45PN5 3A1O15NRDON6K 29J0NG7K2CJ3I
	2FGISXQFKX140 3DRCR3Q1YSNAE 2HY4OTWNDEL6M 2E0IK2WMLY3OL 18SM30ANJ3DIU Q6X82X5CERNW 1JQ54YUM0EZ9S 3D7Q02865K57X
	1GPZ1V8511WPU 1RBM2E9E3HX26 EJ7JS2NXU4W8 2LHJO9JLKWP0G 1SRLEMAZREN52 GR3AC2P00UIZ OAGKWOQ5TGSJ W2GFI17UC77L
	LAP4K6CYLEDA 12MXWN9B9J3X9 31QT9Z34FDJ0S YPZHBBU6LVF9 1XSLAHZES2AF9 2DE5R2NOIPHAM 230CLS4EOMJJ0 26S84SOY26I0M
	2FXKOST59RYZI 3T4UT7PSEMVKJ 39JPDFZ5GQ36H 3EL162UVV9AEB 2RWIGAO1IML88 32NGCI10WWY5H FVA5PK6RUKHL 36PZDS5BWSIY2
	175CUJNBL3P6D 3HAHDCWL8ZS9E CSU7TSUSW3R2 19QEE9146WLED 1R4HBWJPVTL7E L2TZ0QNJY1ZR MQQWZ7QVBQ23 1UIW42CHT9P05
	1K96GYY8IJCLL 2EJSGZ7IYNL4X 3M4T64BGBLBET 186RVFK8LU3OP 160VB2CRW309V 1K863PRZPT9GI IECZNYN7ZT8D KV9ALC4IIQVX
	HGFBNKNBIJRK 39VIROT7S1FP7 2TGSFHJKRBO3S GCHHWEH6HPZY 35GJIC5UDJOVE 3Q3T7KTL5K2F7 V1PR1JMV5TE6 U37DGTKXUXVK
	3KRMUKSJX4HXQ 2DKG6TWHHHDZ7 2NTXOI6PLQ2YY KK6BTBITRIOB 24E08BXC9BRDP 3Q0ZXM01SPLCL 38696EPC33OHV 3I8TFOWJHW2Z1
	JYCWHTTZMZK4 2YJX9CPK5SBLH 2LS9W2INQKGDO 1IG9LEW3MWH9W 2IO2U1YFCG948 9JFQB6D5I7EX OMEMO6MGI4DB 61HN6NVRND2B
	2M4JVJ3L1N27L 1COT6GJ4UEMBX 30VYKL7GJAQCG PJSTDZ11K3BR BALZMRMNBIUU 1VWHLHVY40E4W 39V64NPNEZWSN 1Y7YEYVJZIRMB
	3L5INRW45VUMF 1PPNIW7EDLWW 14801MRSRN604 2GN124JZYCOJS 1DYUXPI0FTCRZ 2QVKF9EWNTIK6 387U48PBA7JG1 A7RDM1HO977M
	2FC99TSQPT0 DE7YLW3JTVPX 2GZ1JF523TNU6 2BW6VBMY2EZ2O 2Q6PZ2YC7JKNQ KCV0YM19P29N 373GHRC8NBEO0 F8WYC535GT4E
	IJOMP3NWUMKF WBJ8OMLM0FNY 258IGKKBOMNHQ 3SIL7X8CWBSVO UWEU5U5IMX4Z 32T2JDUOWZLZQ 1J6BKRJ1JT2Z9 JQX7ZKZPOY9P
	8ZNK07QNWSO2 1XXBA61BSYII8 1TZ95C1VSFAAG 3FS8Z9VAI0Q1 1IDV3JPKYM5IS 17OFYDZ6FFF37 G9TEFI0F01O9 2T732RDYQ4EM3
	2H6Y63OHMNW81 3BBDSAQICKR9L 3NCM5FB6V4YGB PEZHMIQEW4U7 2KVUTY0PSWK9N 2RSSTREPZB5C1 1PR0NVHD615O0 2BQ7NHT326YI6
	2WUIMETLE8H9B 29FW0Q4AQU9DF XXY5ZZ2D5V55 2TCZBFYIBFYLV 1HICCLB8A6DC0 2WV7OA4R4ZSY0 JQBYQU9PRN6O 3U8Z7DFSAML1J
	3MUK5XZ939AGI 2G5PFA3L6AJNU 1Z7SPS7E648NC 37UHRNC8T87V3 LGYF5E0FKSGK 1HJOU0PR0XVEL F0F4V2JFGA57 1SCXI1RMKOOI3
	29WUB5B3IIQ8P 2OKEAUKR2C5L9 1H1YBMJJCALZL 1VJW9LIXIQ4KF 3UIVTHNWKIPBU 24YCYBBYZ021K 8ZX0CVV7RHQO 1UHTJ67Z99LCI
	2IADE1MPE0957 1R3B1XAKJLJSN 2R08R3V2M50TJ 2EKKD3YB24B89 2E7CSX52XUXRH 37JFITFDWQP67 1F8AZ8H0P2EL7 EEG5Y34CC6ZD
	1PB8LKPIUYGTV 3DISB3P22P3UY 1J6XPYHNX5UWJ 4UQ97J8Z3KV7 4NELDU64HQMR 3GCZLW8BOTL2Z FEPQOFWTAOCE 1QFP1WB3MVXRE
	2OLW1G4AHVVFF 11D28J27G7XJP ZMI5BJGWRV2M 3AAL01998LARU 1JVADSBR835DA 1D3BDXZOE68WZ 3J5TGY65BTN9Z 28V6N1IKBZJSO
	2XIWB856JUH8V 333RN2K8XXT3G 1BPOKEZSQHLKL 18105DQXUYN19 3ADQ3V02WFFQ7 14LND55KLVWSX 3LUGPT5HWC9SN 2RAWBEDURZ84I
	IZKAC2EAES5T 19DWXN7O3BBJP 2CT9AKHS3FANK 296ZB8EYTB7HY 1NA1P5QAK1F09 1MH53BDMUKIKK 2IPLM6D8X73VR 1W18K2X7URGWY
	183ZVA5KG4G0B 28LJD6SBBBPTN 11YUAQOW2FMYD 1ML1DSFLWAL14 1MMN0ROSOLQ1Z 36WE6Y6G0Q63T 3DK9I9RX4WFHS 17T6A8CIO2M7Q
	2DFVHZ1X5DILW 1U7CE9YW9UBJH 1O3Q3S44X946G 3MMC12S6X9FXP RQLHI33KRUMR VZ4LR2WTAUUF R429ZI07EZR1 1KXLZB31US4NK
	H2A8HYRR1P5O 2RZ4YDPNXV2HX 2LDMHXRSL3TH0 3PPJGYM3GHGYB 3TKK8VN6FJPW2 T6RQRQ8BC598 U6E5FL2QZWJI 1N43WG4PW8CXL
	348MUOAP4WHA0 3GCUYO7DHIBPM 2FCUI26ULU4WA 2IQ80O3KNCDC 3UCMH0EKHKJ2Z 4USU26PSFY57 26M2DHOT8TACH 2RH3VTRPMENVQ
	J6W56TBMBQK3 116R9BEBNA73X W1M4MKRLS8RN ICSQF62QS28F F99QGZQUMEH5 19UME23JGPOO8 3GFJPFKF53XIJ 39J7BGX5FMPHA
	1FRP9QRNSFKML O3IMYOS5AT19 2OXBCAW9Z5A92 YUPSDYBZREL5 7OO1W6P8ET9R 99925VCG6N93 2F09NVMG5XZXV 38HJH95034JFJ
	1YSTQPS6MTXCW 27ROV7BGIOMIU 3LH6OZYCWZLVC DPTQ4YQZY4BY 2REJN8WZB1BVN 23F3WLROFNIRL 2M66Y9JKMPVXU 2QVHWPNUQUFZ4
	3TGH7J7S1051L Y5TDQDGFH3PX WHAMKZT2E5MH 3J0TG5DPRPEFQ K3B1JEIU4MJB 3IM5NVA9C5Z29 5QYO1K3QRN91 1C44UIL71MDLB
	150A4OOM00DE3 OXRJV3H3C6VC 36WTEK3BV4SY3 23NO5X98JLP2K 46K7D97TFSNU 20G17RRVSVD78 2BS830OE6VPSZ EEKRLCK67L3D
	3R7E94KQ8Y5TS QOTHWYUZ7V30 259UIZDJLNH52 12R5DXAWYBMKI 346PT29VLRCIP 171D6I6TPUBV6 E6UWT4U8MJ9R 12III124U3UB0
	2A94NFR8RA435 1S1B4ZCRUQ0E5 1DAY75E0EPCT4 1VXOZD3KJV75 31GZPMV5S9D29 T3LH85KDRBXR 2BE5S4K553FP1 2M0RWEBTUITLS
	35C4D9FTLLRJK 14EC84HID9O2M 1UYAS9IPSJC86 3BAPFZO1BGCDA ARWJ9AQYYATZ 1QYU5SW5HK7WF 16V2P4SSM3T0K 3VSEVM3OVAIBE
	1AX95LM3T5H9Q 2SXXFSAI1ZZVK 32ZYEQQPR6KS4 3BVMLACC93YOV 2RMSUYBBBGBDK QUP38EE9B66B 3JA7UJFTMWGLQ I2L6VVZYC1MW
	3RY8HFG7LD91P 46SAZ9GQCYZE 2ZPQQ1PTTFUSU 3SU97HME8O5YW ER72BXZZJPAY 3QII86AT4XB5G 2A7KTZ2E7B1QC 2FBKTBLVBQAX
	3NL7UQQVW3I30 2A9SDDI9ICBR8 2DI50UT0ADQ65 18ZNJ17F9O7MM CUZWJ9TPFY4X NYPPODI80GKY IPGIPM8Q1QFA 13MLO6F10LJ0G
	1WUXBPBNSQ9VK 242J19W3G3ERK HC5RMF11SBG7 3HA9Y2EHPPC2I 2EAL5BCY8RKSS K4CVJ6MT9BXS J9HULWYSD0A5 38WAM7TDLWAUU
	1FN8P2JE1AGQ3 1XDMQLWKG8AX7 5NR84ZIJ19PU 3A0RO7O54TM2U 2ENT3459C8LKN D3RNJLIRIPTS G72LJ1BUBOP2 28WUPQZJ07PEL
	1JTU1AJA2BCE1 3955T6IPHOUDX 2YLFWZPVYKFOV 1CTR9EECFVRWG 34VMCHWFMFZDO 1W8WLSTTDS1VS LMVZ7U9VP24O 30GFCEMN2PJT8
	BJ1TP7N3J4FA 2F9U9178Y0JQS 1J3KREPTUJMIX B1PCNYK6S4L9 6OGBZTBHSLPJ 5T3ZHUF33SP1 3IC2EGX3N4LKE 1QDOK8UD8NLZB
	3OCAKOPY472MY 3IJTPLSFSXRAS 2ANOIY4VY60IS 1YYTNHG6OPCX1 1GD7JV6ZAJQ6H 1BEO57IB4ZYFV 27NIYCZJVLV8H 36ZU7QY6REOGV
	RAA34GDIV28G 3O5LAQAZPILCG 2ILN3C3K6A2ZK GY9J2NC27CUH 1PR3J3YK551YC 3FS60E71H6YTZ 4ICJO1QLB36 FNOOC767YY75
>;

our sub RandomPiece     { $Random64.subbuf: 0, 768 }
our sub RandomCastle    { $Random64.subbuf: 768, 4 }
our sub RandomEnPassant { $Random64.subbuf: 772, 8 }
our sub RandomTurn      { $Random64.subbuf: 780, 1 }
