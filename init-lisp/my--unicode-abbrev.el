;; unicode; utf-8; my/unicode-abbrev

(require 'my--trie)

(my/defvar
 my/unicode-abbrev/list
 '(("∪" "cup")           ;; UNION; set
   ("∆" "sxor")          ;; U+2206; symmetric difference
   ("∆" "symdiff")       ;; U+2206; symmetric difference
   ("∪" "sor")
   ("⋃" "∪")             ;; U+22c3 N-ARY UNION; set
   ("⊍" "cup.")          ;; U+228d; union of disjoint sets
   ("⨃" "⊍")             ;; U+2a03; n-ary union operator with dot
   ("∩" "cap")           ;; INTERSECTION; set
   ("∩" "sand")
   ("⋂" "∩")             ;; U+22c2; N-ARY INTERSECTION; set
   ("∖" "wo")            ;; set; without
   ("⨯" "times")         ;; set;
   ("⨯" "x")             ;; u+2a2f; set;
   ;; subset relationships
   ("⊊" "s<")            ;; U+228a; set;
   ("⊊" "slt")           ;; U+228a; set;
   ("⊆" "sle")           ;; U+2286; set;
   ("⊈" "nsle")          ;; U+2288; set;
   ("⊋" "s>")            ;; U+228b; set;
   ("⊋" "sgt")           ;; U+228b; set;
   ("⊇" "sge")           ;; U+2287; set;
   ("⊉" "nsge")          ;; U+2289; set;
   ;; ("⊂" "ss")    ;; U+2282; set; DEPRECATED
   ;; ("⊆" "sseq")  ;; set; DEPRECATED
   ;; square subset relationships
   ("⋤" "qlt")           ;; u+22e4
   ("⊑" "qle")           ;; u+2291
   ("⋢" "nqle")          ;; u+22e2
   ("⋥" "qgt")           ;; u+22e5
   ("⊒" "qge")           ;; u+2292
   ("⋣" "nqge")          ;; u+22e3
   ("∈" "in")            ;; set; element
   ("∋" "ni")            ;; U+220b; set; element
   ("∉" "nin")           ;; set
   ("∌" "nni")           ;; U+220c; set; element
   ("∅" "{}")            ;; set; empty set; ≠ diameter sign
   ("∅" "0")             ;; set; empty set;
   ("∁" "comp")          ;; u+2201; set complement
   ("‰" "%")             ;; u+2030; per mille sign
   ;; mathematical fraktur capital
   ("𝔄" "Af")            ;; U+1d504; \mathfrak{A}
   ("𝔅" "Bf")            ;; U+1d505; \mathfrak{B}
   ("ℭ" "Cf")            ;; U+212d;  \mathfrak{C}
   ("𝔇" "Df")            ;; U+1d507; \mathfrak{D}
   ("𝔈" "Ef")            ;; U+1d508; \mathfrak{E}
   ("𝔉" "Ff")            ;; U+1d509; \mathfrak{F}
   ("𝔊" "Gf")            ;; U+1d50a; \mathfrak{G}
   ("ℌ" "Hf")            ;; U+210c;  \mathfrak{H}
   ("ℑ" "If")            ;; U+2111;  \mathfrak{I}
   ("𝔍" "Jf")            ;; U+1d50d; \mathfrak{J}
   ("𝔎" "Kf")            ;; U+1d50e; \mathfrak{K}
   ("𝔏" "Lf")            ;; U+1d50f; \mathfrak{L}
   ("𝔐" "Mf")            ;; U+1d510; \mathfrak{M}
   ("𝔑" "Nf")            ;; U+1d511; \mathfrak{N}
   ("𝔒" "Of")            ;; U+1d512; \mathfrak{O}
   ("𝔓" "Pf")            ;; U+1d513; \mathfrak{P}
   ("𝔔" "Qf")            ;; U+1d514; \mathfrak{Q}
   ("ℜ" "Rf")            ;; U+211c;  \mathfrak{R}
   ("𝔖" "Sf")            ;; U+1d516; \mathfrak{S}
   ("𝔗" "Tf")            ;; U+1d517; \mathfrak{T}
   ("𝔘" "Uf")            ;; U+1d518; \mathfrak{U}
   ("𝔙" "Vf")            ;; U+1d519; \mathfrak{V}
   ("𝔚" "Wf")            ;; U+1d51a; \mathfrak{W}
   ("𝔛" "Xf")            ;; U+1d51b; \mathfrak{X}
   ("𝔜" "Yf")            ;; U+1d51c; \mathfrak{Y}
   ("ℨ" "Zf")            ;; U+2128;  \mathfrak{Z}
   ;; mathematical fraktur small
   ("𝔞" "af")            ;; U+1d51e; \mathfrak{a}
   ("𝔟" "bf")            ;; U+1d51f; \mathfrak{b}
   ("𝔠" "cf")            ;; U+1d520; \mathfrak{c}
   ("𝔡" "df")            ;; U+1d521; \mathfrak{d}
   ("𝔢" "ef")            ;; U+1d522; \mathfrak{e}
   ("𝔣" "ff")            ;; U+1d523; \mathfrak{f}
   ("𝔤" "gf")            ;; U+1d524; \mathfrak{g}
   ("𝔥" "hf")            ;; U+1d525; \mathfrak{h}
   ("𝔦" "if")            ;; U+1d526; \mathfrak{i}
   ("𝔧" "jf")            ;; U+1d527; \mathfrak{j}
   ("𝔨" "kf")            ;; U+1d528; \mathfrak{k}
   ("𝔩" "lf")            ;; U+1d529; \mathfrak{l}
   ("𝔪" "mf")            ;; U+1d52a; \mathfrak{m}
   ("𝔫" "nf")            ;; U+1d52b; \mathfrak{n}
   ("𝔬" "of")            ;; U+1d52c; \mathfrak{o}
   ("𝔭" "pf")            ;; U+1d52d; \mathfrak{p}
   ("𝔮" "qf")            ;; U+1d52e; \mathfrak{q}
   ("𝔯" "rf")            ;; U+1d52f; \mathfrak{r}
   ("𝔰" "sf")            ;; U+1d530; \mathfrak{s}
   ("𝔱" "tf")            ;; U+1d531; \mathfrak{t}
   ("𝔲" "uf")            ;; U+1d532; \mathfrak{u}
   ("𝔳" "vf")            ;; U+1d533; \mathfrak{v}
   ("𝔴" "wf")            ;; U+1d534; \mathfrak{w}
   ("𝔵" "xf")            ;; U+1d535; \mathfrak{x}
   ("𝔶" "yf")            ;; U+1d536; \mathfrak{y}
   ("𝔷" "zf")            ;; U+1d537; \mathfrak{z}
   ;; small roman numeral
   ("ⅰ" "1rn")           ;; u+2170 ; small roman numeral one
   ("ⅱ" "2rn")           ;; u+2171 ; small roman numeral two
   ("ⅲ" "3rn")           ;; u+2172 ; small roman numeral three
   ("ⅳ" "4rn")           ;; u+2173 ; small roman numeral four
   ("ⅴ" "5rn")           ;; u+2174 ; small roman numeral five
   ("ⅵ" "6rn")           ;; u+2175 ; small roman numeral six
   ("ⅶ" "7rn")           ;; u+2176 ; small roman numeral seven
   ("ⅷ" "8rn")           ;; u+2177 ; small roman numeral eight
   ("ⅸ" "9rn")           ;; u+2178 ; small roman numeral nine
   ("ⅹ" "10rn")          ;; u+2179 ; small roman numeral ten
   ("⌀" "avg")           ;; diameter sign; ≠ empty set sign; average;
   ;; TODO: handling complement etc
   ;;    ?:TODO: function used as expansion
   ("⁰" "^0")            ;; superscript
   ("¹" "^1")            ;; superscript
   ("²" "^2")            ;; superscript
   ("³" "^3")            ;; superscript
   ("⁴" "^4")            ;; superscript
   ("⁻" "^-")            ;; superscript
   ("⁺" "^+")            ;; superscript
   ("⃰" "^*")           ;; superscript; combining asterisk above
   ("⁻¹" "^-1")          ;; superscript
   ("⁻¹" "iv")           ;; superscript
   ("∣" "div")          ;; U+2223; divides
   ("∤" "ndiv")         ;; U+2224; not divides
   ;; TODO: superscript
   ("₀" "_0")            ;; U+2080 subscript
   ("₁" "_1")            ;; U+2081 subscript
   ("₂" "_2")            ;; U+2082 subscript
   ("₃" "_3")            ;; U+2083 subscript
   ("₄" "_4")            ;; U+2084 subscript
   ("₅" "_5")            ;; U+2085 subscript
   ("₆" "_6")            ;; U+2086 subscript
   ("₇" "_7")            ;; U+2087 subscript
   ("₈" "_8")            ;; U+2088 subscript
   ("₉" "_9")            ;; U+2089 subscript
   ("↯" "zz")            ;; arrow; zig zag arrow
   ("§" "sec")           ;; u+00a7; section sign
   ("¶" "ps")            ;; u+00b6; pilcrow sign; paragraph sign
   ("␣" "ob")            ;; u+2423; open box
   ("␣" " ")             ;; space indicator / blank
   ("⍽" "obs")           ;; u+237d; shouldered open box
   ("⍽" "nbs")           ;; non breakable space
   ("⍽" "␣")
   ("　" " w")           ;; u+3000; ideographic space
   ("¤" "cur")           ;; u+00a4; generic currency sign
   ("¡" "!")             ;; u+00a1; inverted exclamation mark
   ("✓" "kk")            ;; done; checkmark
   ("✗" "xm")            ;; x mark; ballot
   ("∝" "prop")          ;; U+221d; proportional to; comp
   ("∷" "::")            ;; U+2237
   ("∾" "s")             ;; U+223e; inverted lazy s
   ("∿" "sin")           ;; U+223f; sine wave
   ("∿" "wave")          ;; U+223f; sine wave
   ("≟" "?=")            ;; U+225f; comp
   ("=̇" "=.")            ;; combining dot above
   ("=̇" "=")             ;; combining dot above
   ("⇔̇" "iff.")          ;; combining dot above
   ("⇔̇" "⇔.")            ;; combining dot above
   ("⇒̇" "⇒.")            ;; combining dot above
   ("⇒̇" "im.")           ;; combining dot above
   ("≡̇" "eqv.")          ;; combining dot above
   ("≡̇" "≡.")            ;; combining dot above
   ("=" "eq")            ;; comp
   ("⩵" "==")            ;; comp
   ("⩶" "===")           ;; comp
   ("≠" "neq")           ;; comp
   ("≝" "def=")          ;; comp; definition, equality
   ("≔" ":=")            ;; comp; definition, equality
   ("≕" "=:")            ;; comp; definition, equality
   ("≡" "eqv")           ;; comp
   ("≢" "neqv")          ;; comp
   ("≈" "apx")           ;; comp
   ("≙" "^=")            ;; comp
   ("≃" "sim")           ;; U+2243; comp; similar
   ("≄" "nsim")          ;; U+2243; comp; similar
   ("≅" "~=")            ;; U+2245; comp;
   ("≅" "iso")           ;; U+2245; comp; isomorph
   ("≇" "niso")          ;; U+2247; comp; not isomorph
   ("≤" "le")            ;; comp
   ("≥" "ge")            ;; comp
   (">" "gt")            ;; ASCII
   ("<" "lt")            ;; ASCII
   ("⟕" "ljoin")         ;; U+27d5; left  outer join
   ("⟖" "rjoin")         ;; U+27d6; right outer join
   ("⟗" "fjoin")         ;; U+27d7; full  outer join
   ("°" "deg")           ;; degree
   ("℃" "degC")          ;; u+2103; degree celsius
   ("℉" "degF")          ;; u+2109; degree fahrenheit
   ("K" "degK")          ;; u+212a; degree kelvin
   ("∑" "sum")
   ("〈" "ds<")           ;; u+2329; my/zk2; delimited section; delimiter;
   ("〉" "ds>")           ;; u+232a; my/zk2; delimited section; delimiter
   ("⟨" "<1")             ;; u+27e8; \langle; delimiter
   ("⟩" ">1")             ;; u+27e9; \rangle; delimiter
   ((progn
      (insert-char #x27e8)
      (save-excursion
        (insert-char #x27e9)))
    "<")
   ("⧼" "⟨")             ;; u+29fc;
   ("⧽" "⟩")             ;; u+29fd;
   ("⦑" "<.")            ;; u+2991;
   ("⦒" ">.")            ;; u+2992;
   ;; ("⦓" "(")             ;; U+2993; NOTE: see next entry
   ((progn
      (insert-char #x2993)
      (when (= (char-after) #x29)  ;; )
        (delete-char 1)
        (save-excursion
          (insert-char #x2994))))
    "(")             ;; U+2993; U+2994;
   ("⦔" ")")             ;; U+2994;
   ("⦕" "⦓")             ;; U+2995;
   ("⦖" "⦔")             ;; U+2996;
   ("⦇" "(z")            ;; U+2987; z notation
   ("⦈" ")z")            ;; U+2988; z notation
   ("⌇" "wbar")          ;; u+2307; wavy line; vertical line / bar
   ("⦚" "zbar")          ;; u+299a; vergical zigzag line; vertical line / bar
   ("⦁" "spot")          ;; u+2981; z-notation spot
   ("⋄" "dia")           ;; u+22c4; operator; diamond operator
   ("⊲" "sglt")          ;; u+22b2; operator; LEFT normal subgroup (of) RIGHT
   ("⊳" "sggt")          ;; u+22b3; operator; LEFT contains as a normal subgroup RIGHT
   ("⊴" "sgle")          ;; u+22b4; operator; LEFT normal subgroup of or equal to RIGHT
   ("⊵" "sgge")          ;; u+22b5; operator; LEFT contains as a normal subgroup or equal to RIGHT
   ("⋪" "nsglt")         ;; u+22ea;
   ("⋫" "nsggt")         ;; u+22eb;
   ("⋬" "nsgle")         ;; u+22ec;
   ("⋭" "nsgge")         ;; u+22ed;
   ;; o for order
   ("≺" "o<")            ;; U+227a;
   ("≺" "olt")           ;; U+227a;
   ("≻" "o>")            ;; U+227b;
   ("≻" "ogt")           ;; U+227b;
   ("≼" "ole")           ;; U+227c;
   ("≽" "oge")           ;; U+227d;
   ("⪻" "o<<")           ;; U+2abb; double precedes
   ("⪼" "o>>")           ;; U+2abc; double succeeds
   ("" "pua")           ;; start of private use area
   ("∏" "prod")          ;; n-ary product
   ("∐" "cprod")         ;; n-ary coproduct
   ("∘" ".")             ;; function; compose
   ("∘2" ".2")
   ("∘3" ".3")
   ("⌜" "tlc")           ;; u+231c; top left  corner
   ("⌝" "trc")           ;; u+231d; top right corner
   ("⌞" "blc")           ;; u+231e; bottom left  corner
   ("⌟" "brc")           ;; u+231f; bottom right corner
   ((progn
      (insert-char #x231c)
      (save-excursion
        (insert-char #x231d)))
    "ttc")              ;; top top corners
   ((progn
      (insert-char #x231c)
      (save-excursion
        (insert-char #x231f)))
    "tbc")              ;; top bottom corners
   ((progn
      (insert-char #x231e)
      (save-excursion
        (insert-char #x231d)))
    "btc")              ;; bottom top corners
   ((progn
      (insert-char #x231e)
      (save-excursion
        (insert-char #x231f)))
    "bbc")              ;; bottom bttom corners
   ("⌌" "blr")          ;; u+230c; unicode name: bottom right crop; down  minus; my name: bottom left crop
   ("⌍" "brr")          ;; u+230d; unicode name: bottom left  crop; minus down;  my name: bottom right crop
   ("⌎" "tlr")          ;; u+230e; unicode name: top    right crop; up    minux; my name: top left crop
   ("⌏" "trr")          ;; u+230f; unicode name: top    left  crop; minus up;    my name: top right crop
   ((progn
      (insert-char #x230e)
      (save-excursion
        (insert-char #x230f)))
    "ttr")              ;; top top crop
   ((progn
      (insert-char #x230e)
      (save-excursion
        (insert-char #x230d)))
    "tbr")              ;; top bottom crop
   ((progn
      (insert-char #x230c)
      (save-excursion
        (insert-char #x230f)))
    "btr")              ;; bottom top crop
   ((progn
      (insert-char #x230c)
      (save-excursion
        (insert-char #x230d)))
    "bbr")              ;; bottom bttom crop
   ("⸁" "sm.")          ;; u+2e01; right angle dotted substitution marker
   ("⸂" "subbl")        ;; LEFT SUBSTITUTION BRACKET
   ("⸃" "subbr")        ;; RIGHT SUBSTITUTION BRACKET
   ("⸄" "subdl")        ;; LEFT DOTTED SUBSTITUTION BRACKET
   ("⸅" "subdr")        ;; RIGHT DOTTED SUBSTITUTION BRACKET
   ("⎴" "sbt")          ;; u+23b4 ; top    square bracket
   ("⎵" "sbb")          ;; u+23b5 ; bottom square bracket
   ("⏜" "pat")          ;; u+23dc ; top    parenthesis
   ("⏝" "pab")          ;; u+23dd ; bottom parenthesis
   ("⎵⎴" "icc")         ;; left-closed right-closed interval
   ("⎵⏜" "ico")         ;; left-closed right-open   interval
   ("⏝⎴" "ioc")         ;; left-open   right-closed interval
   ("⏝⏜" "ioo")         ;; left-open   right-open   interval
   ((progn
      (insert-char #x2308)
      (save-excursion
        (insert-char #x2309)))
    "ceil")              ;; U+2308, U+2309; operator ceil
   ((progn
      (insert-char #x230a)
      (save-excursion
        (insert-char #x230b)))
    "floor")              ;; U+230a, U+230b; operator floor
   ((progn
      (insert-char #x2016)
      (save-excursion
        (insert-char #x2016)))
    "norm")              ;; U+2016, vector norm
   ((progn
      (insert-char #x2016)
      (save-excursion
        (insert-char #x2016)))
    "||")                ;; U+2016, vector norm
   ("⋆" "star")          ;; U+22c6; star operator
   ("⋇" "/t")            ;; U+22c7; DIVISION TIMES
   ("⋅" "t")             ;; U+22c5; math; operator
   ("⋅" "cdot")          ;; U+22c5; math; operator
   ("∗" "*")             ;; U+2217; math; operator; \ast{}; convolution
   ("∙" "bullet")        ;; U+2219; bullet point
   ("∙" "it")            ;; U+2219; bullet point
   ("±" "+-")            ;; U+00b1; operator; plus-minus sign
   ("﬩" "+")             ;; U+fb29; operator; hebrew letter alternative plus sign
   ("¯" "-")             ;; U+00af; operator; macron
   ("−" "¯")             ;; U+2212; operator; minus sign
   ;; suffix 'cc' for cirlce
   ("⊕" "+cc")            ;; U+2295; operator
   ("⊖" "-cc")            ;; U+2296; operator
   ("⊗" "xcc")            ;; U+2297; operator
   ("⊗" "⨯cc")            ;; U+2297; operator
   ("⊘" "/cc")            ;; U+2298; operator
   ("⊙" "⋅cc")            ;; U+2299; operator
   ("⊙" "tcc")            ;; U+2299; operator
   ("⊚" ".cc")            ;; U+229a; operator
   ("⊚" "∘cc")            ;; U+229a; operator
   ("⊛" "*cc")            ;; U+229b; operator
   ("⊛" "∗cc")            ;; U+229b; operator
   ("⊜" "=cc")            ;; U+229c; operator
   ("⦶" "|cc")            ;; U+29b6; operator
   ("⦷" "paracc")         ;; U+29b7; operator
   ("⦸" "\\pcc")          ;; U+29b8; operator
   ("⦹" "perpcc")         ;; U+29b9; operator
   ("⧀" "<cc")            ;; U+29c0; operator
   ("⧁" ">cc")            ;; U+29c1; operator
   ;; suffix 's' for square
   ("⊞" "+s")             ;; U+229e; operator
   ("⊟" "-s")             ;; U+229f; operator
   ("⊠" "xs")             ;; U+22a0; operator
   ("⊠" "⨯s")             ;; U+22a0; operator
   ("⊡" "ts")             ;; U+22a1; operator
   ("⊡" "⋅s")             ;; U+22a1; operator
   ("⟎" "ands")          ;; u+27ce; logical operator; squared and
   ("⟏" "ors")           ;; u+27cf; logical operator; squared or
   ("∫" "int")           ;; U+222b; operator; integral
   ("∬" "int2")          ;; U+222c; operator; double integral
   ("∭" "int3")          ;; U+222d; operator; triple integral
   ("∮" "into")          ;; U+222e; operator; countour integral
   ("⌒" "arc")           ;; U+2312; arc; geometry
   ("⌁" "eot")           ;; U+2301; end of transimssion
   ("⌂" "house")         ;; U+2302; operator
   ("◻" "op")            ;; U+25fb; operatora¯a
   ("÷" "/")             ;; U+00f7; operator; division sign (obelus)
   ("⫽" "//")            ;; U+2afd; operator; double solidus operator
   ("⫻" "///")           ;; U+2afb; operator; triple solidus binary relation
   ("⟌" "/l")            ;; U+27cc; operator; LONG DIVISION
   ("⧺" "pp")            ;; U+29fa; operator; double plus
   ("⧺" "++")            ;; U+29fa; operator; double plus
   ("⧺→" "ppe")          ;; infix matrix col concat
   ("⧺↓" "pps")          ;; infix matrix row concat
   ("⧻" "+++")           ;; U+29fb; operator; triple plus
   ("≪" "<<")            ;; U+226a; operator; much less than
   ("≫" ">>")            ;; U+226b; operator; much more than
   ("√" "sqrt")          ;; U+221a; square root
   ("√" "rt")            ;; U+221a; square root
   ("→" "to")            ;; U+2192; function; arrow; \to
   ("↦" "mto")           ;; function; arrow; \mapsto
   ("⇢" "pto")           ;; U+21e2 function; arrow; "partial \to"
   ("Þ" "thrn")          ;; U+00de; latin capital letter thorn
   ("þ" "Thrn")          ;; U+00fe; latin small   letter thorn
   ;; suffix 'pa' for paired arrow
   ("⇉" "topa")          ;; U+21c9; function; paired rightwars arrow;
   ("∞" "inf")
   ;; "t" suffix for tailed / with tail
   ("↣" "tot")           ;; U+21a3; function; tail
   ;; for sets
   ("lin𝔖" "lins")        ;; operator
   ("lin𝔖π" "linsc")      ;; operator
   ("coni𝔖" "conis")      ;; operator
   ("coni𝔖π" "conisc")    ;; operator
   ("conv𝔖" "convs")      ;; operator
   ("conv𝔖π" "convsc")    ;; operator
   ("aff𝔖" "affs")        ;; operator
   ("aff𝔖π" "affsc")      ;; operator
   ;; for sequences
   ("lin𝔉" "linf")        ;; operator
   ("lin𝔉π" "linfc")      ;; operator
   ("coni𝔉" "conif")      ;; operator
   ("coni𝔉π" "conifc")    ;; operator
   ("conv𝔉" "convf")      ;; operator
   ("conv𝔉π" "convfc")    ;; operator
   ("aff𝔉" "afff")        ;; operator
   ("aff𝔉π" "afffc")      ;; operator
   ("ι0↦" "seq0")        ;; iota maps to; sequence operator
   ("ι1↦" "seq1")        ;; iota maps to; sequence operator
   ("☐" "cb")             ;; U+2610; checkbox
   ("☒" "cbx")            ;; U+2612; checkbox with x
   ("☑" "cbkk")           ;; U+2611; checkbox with check
   ("⚠" "warn")           ;; U+26a0; warning sign
   ("⌢" "smile")          ;; U+2322; smile
   ("⌣" "frown")          ;; U+2323; frown
   ("⏏" "eject")          ;; U+23cf; frown
   ;; "a" suffix for arrow
   ("⥓" "pj")            ;; U+2953; projection
   ("⥚" "cpj")           ;; U+2951; "converse" projection
   ("⥊" "cv")            ;; U+294a; left barb ub right barb down harpoon; converse (relation)
   ("↔" "swap")          ;; U+2194; arrow;
   ("↔" "wea")           ;; U+2194; arrow; left (west) right (east) arrow
   ("↕" "nsa")           ;; U+2195; arrow; up (north) down (south) arrow
   ("↗" "nea")           ;; U+2197; arrow
   ("↘" "sea")           ;; U+2198; arrow
   ("↑" "na")            ;; U+2191; arrow
   ("←" "wa")            ;; U+2190; arrow
   ("←" "gets")          ;; U+2190; arrow
   ("→" "ea")            ;; U+2192; arrow
   ("↓" "sa")            ;; U+2193; arrow
   ("↥" "nba")           ;; U+21a5; arrow
   ("↤" "wba")           ;; U+21a4; arrow
   ("↦" "eba")           ;; U+21a6; arrow
   ("↧" "sba")           ;; U+21a7; arrow
   ("⤒" "nab")           ;; U+2912; arrow
   ("⤓" "sab")           ;; U+2913; arrow
   ("↚" "w/a")           ;; U+219a; arrow; wa with /
   ("↛" "e/a")           ;; U+219b; arrow; ea with /
   ("⇷" "wpa")           ;; U+21f7; arrow; wa with |
   ("⇸" "epa")           ;; U+21f8; arrow; ea with |
   ("⇺" "wppa")          ;; U+21fa; arrow; wa with ||
   ("⇻" "eppa")          ;; U+21fb; arrow; ea with ||
   ("↺" "ccw")           ;; U+21ba; counter clockwise gapped circle arrow
   ("↻" "cw")            ;; U+21bb;         clockwise gapped circle arrow
   ("𝟚↺"  "2l")          ;; [l]eft
   ("𝟚↺̅"  "2nl")         ;; [n]ot [l]ight
   ("𝟚↻"  "2r")          ;; [r]right
   ("𝟚↻̅"  "2nr")         ;; [n]ot [r]ight
   ("𝟚↕"  "2s")          ;; [s]traight
   ("𝟚↕̅"  "2ns")         ;; [n]ot [s]traight
   ("𝟚↺𝓈" "2ls")         ;; [2]-dimensional-input [l]eft [s]egment-input
   ("𝟚↻𝓈" "2rs")         ;; [2]-dimensional-input [r]right [2]egment-input
   ("𝟚↕𝓈" "2ss")         ;; [2]-dimensional-input [r]right [2]egment-input
   ;; suffix 'l' for loop
   ("⥀" "ccwl")          ;; U+2940; counter clockwise circle arrow
   ("⥁" "cwl")           ;; U+2941;         clockwise circle arrow
   ("↤" "mgets")         ;; arrow
   ("⇝" "rsa")           ;; arrow; right squiggle
   ("⇜" "lsa")           ;; arrow; left  squiggle
   ("⬿" "lwa")           ;; arrow;
   ("⤳" "rwa")           ;; arrow;
   ("⇒" "im")            ;; u+21d2; logic; arrow; implies
   ("∴" "tf")            ;; logic; therefore
   ("∵" "bcl")            ;; logic; because
   ("⇏" "nim")           ;; U+21cf; logic; arrow; not implies
   ("⇐" "imb")           ;; logic; arrow; implied by
   ("⇍" "nimb")          ;; U+21cd; logic; arrow; not implied by
   ("⇔" "iff")           ;; logic; arrow; iff.
   ("⇎" "niff")          ;; logic; arrow; niff.
   ("Θ" "OW")            ;; greek; complexity; OW = big O [O] and omega [W]
   ("∀" "fa")            ;; logic; forall
   ("∃" "ex")            ;; logic; exist
   ("∄" "nex")           ;; logic; exist
   ("¬" "not")           ;; logic;
   ("∨" "o")             ;; LOGICAL OR; logic;
   ("∨" "or")            ;; LOGICAL OR; logic;
   ("∧" "a")             ;; LOGICAL AND; logic;
   ("∧" "and")           ;; LOGICAL AND; logic;
   ("∧" "wdg")           ;; wedge product / exterior product; linear algebra / differential geometry
   ("⋎" "orc")           ;; u+22de; CURLY LOGICAL OR
   ("⋏" "andc")          ;; u+22cf; CURLY LOGICAL AND
   ("⊼" "nand")          ;; U+22bc; NAND; logic;
   ("⊽" "nor")           ;; U+22bd; NOR; logic;
   ("⋀" "∧")             ;; N-ARY LOGICAL AND; logic;
   ("⩒" "xor")           ;; U+2a52;; LOGICAL OR WITH DOT ABOVE; XOR
   ("⋁" "∨")             ;; N-ARY LOGICAL OR; logic;
   ("⊥" "bot")           ;; U+22a5; logic
   ("⊤" "top")           ;; U+22a4; logic
   ("⊢" "yld")           ;; logic; yield
   ("∂" "dee")           ;; U+2202; cursive d, partial derivative
   ("α" "ag")            ;; U+03b1; greek; alpha
   ("β" "bg")            ;; U+03b2; greek; beta
   ("γ" "gg")            ;; U+03b3; greek; gamma
   ("Γ" "γ")             ;; U+0393; greek; gamma
   ("δ" "dg")             ;; U+03b4; greek; delta
   ("Δ" "δ")             ;; U+0384; greek; delta
   ("ε" "eg")             ;; U+03b5; greek; epsilon (\varepsilon)
   ("ϵ" "ε")             ;; U+03fb; greek; lunate epsilon (\epsilon)
   ("ζ" "zg")             ;; U+03b6; greek; zeta
   ("η" "hg")             ;; U+03b7; greek; eta
   ("ϑ" "th")            ;; U+03d1; greek; theta
   ("θ" "ϑ")             ;; U+03b8; greek; theta
   ("Θ" "θ")             ;; U+0398; greek; theta
   ("ι" "ig")             ;; U+03b9; greek; iota
   ("κ" "kg")             ;; U+03ba; greek; kappa
   ("λ" "^")              ;;       ; greek; lambda
   ("Λ" "λ")              ;;       ; greek; lambda
   ("μ" "mg")             ;; U+03bc; greek; mu
   ("ν" "ng")             ;; U+03bd; greek; nu
   ("ξ" "xi")             ;; U+03be; greek; xi
   ("Ξ" "Xi")             ;; U+039e; greek; capital xi
   ("Ξ" "ξ")              ;; U+039e; greek; capital xi
   ("π" "pi")             ;; U+03c0; greek; small pi
   ("Π" "Pi")             ;; U+03a0; greek; capital pi
   ("Π" "π")              ;; U+03a0; greek; capital pi
   ("ϱ" "pg")             ;; U+03f1; greek; rho; \varrho
   ("ρ" "ϱ")              ;; U+03c1;  greek; rho; \rho
   ("σ" "sg")             ;; U+03c3; greek; sigma
   ("Σ" "σ")              ;; U+03a3; greek; sigma
   ("τ" "tg")             ;; U+03c4; greek; tau
   ("ω" "wg")             ;; greek; complexity; omega
   ("Ω" "ω")              ;; greek; complexity; omega
   ("φ" "phi")            ;; U+03c6; greek; phi \varphi
   ("ϕ" "φ")              ;; U+03d5; greek; phi \phi
   ("Φ" "Phi")            ;; U+03a6; greek; phi \Phi
   ("Φ" "ϕ")              ;; U+03a6; greek; phi \Phi
   ("χ" "chi")            ;; U+03c7; greek; chi
   ("ψ" "psi")            ;; U+03c8; greek; psi
   ("Ψ" "Psi")            ;; U+03a8; greek; psi
   ("Ψ" "ψ")              ;; U+03a8; greek; psi
   ("⋔" "pif")             ;; U+22d4; pitchfork; upside down / turned psi
   ("𝒫" "P")              ;; U+1d4ab  \mathcal{P}; power set
   ("↑" "gst")            ;; order relation
   ("↓" "lst")            ;; order relation
   ;; braille patterns
   ;; TODO:
   ;; d:  double struck
   ;; capital letters
   ("𝔸" "Ad")             ;; U+1d538; \mathbb{A}; algebraic numbers
   ("𝔹" "Bd")             ;; U+1d539; \mathbb{B}; binary digits
   ("ℂ" "Cd")             ;; U+2102;  \mathbb{C}; complex numbers
   ("𝔻" "Dd")             ;; U+1d53b; \mathbb{D};
   ("𝔼" "Ed")             ;; U+1d53c; \mathbb{E};
   ("𝔽" "Fd")             ;; U+1d53d; \mathbb{F};
   ("𝔾" "Gd")             ;; U+1d53e; \mathbb{G};
   ("ℍ" "Hd")             ;; U+210d;  \mathbb{H};
   ("𝕀" "Id")             ;; U+1d540; \mathbb{I};
   ("𝕁" "Jd")             ;; U+1d541; \mathbb{J};
   ("𝕂" "Kd")             ;; U+1d542; \mathbb{K};
   ("𝕃" "Ld")             ;; U+1d543; \mathbb{L};
   ("𝕄" "Md")             ;; U+1d544; \mathbb{M};
   ("ℕ" "Nd")             ;; U+2115;  \mathbb{N}; natural numbers
   ("ℕ₀" "ℕ")             ;; natural numbers; 0 explicitly included
   ("ℕ₀" "Nd0")           ;; natural numbers; 0 explicitly included
   ("ℕ⁺" "Nd+")           ;; natural numbers; 0 explicitly excluded
   ("𝕆" "Od")             ;; U+1d546; \mathbb{O};
   ("ℙ" "Pd")             ;; U+2119;  \mathbb{P};
   ("ℚ" "Qd")             ;; U+211a;  \mathbb{Q}; rational numbers
   ("ℝ" "Rd")             ;; U+211d;  \mathbb{R}; real numbers
   ("𝕊" "Sd")             ;; U+1d54a; \mathbb{S};
   ("𝕋" "Td")             ;; U+1d54b; \mathbb{T};
   ("𝕌" "Ud")             ;; U+1d54c; \mathbb{U};
   ("𝕍" "Vd")             ;; U+1d54d; \mathbb{V};
   ("𝕎" "Wd")             ;; U+1d54e; \mathbb{W};
   ("𝕏" "Xd")             ;; U+1d54f; \mathbb{X};
   ("𝕐" "Yd")             ;; U+1d550; \mathbb{Y};
   ("ℤ" "Zd")             ;; U+2124;  \mathbb{Z}; integers
   ;; small letters
   ("𝕒" "ad")             ;; U+1d552; \mathbb{a};
   ("𝕓" "bd")             ;; U+1d553; \mathbb{b};
   ("𝕔" "cd")             ;; U+1d554; \mathbb{c};
   ("𝕕" "dd")             ;; U+1d555; \mathbb{d};
   ("𝕖" "ed")             ;; U+1d556; \mathbb{e};
   ("𝕗" "fd")             ;; U+1d557; \mathbb{f};
   ("𝕘" "gd")             ;; U+1d558; \mathbb{g};
   ("𝕙" "hd")             ;; U+1d559; \mathbb{h};
   ("𝕚" "id")             ;; U+1d55a; \mathbb{i};
   ("𝕛" "jd")             ;; U+1d55b; \mathbb{j};
   ("𝕜" "kd")             ;; U+1d55c; \mathbb{k};
   ("𝕝" "ld")             ;; U+1d55d; \mathbb{l};
   ("𝕞" "md")             ;; U+1d55e; \mathbb{m};
   ("𝕟" "nd")             ;; U+1d55f; \mathbb{n};
   ("𝕠" "od")             ;; U+1d560; \mathbb{o};
   ("𝕡" "pd")             ;; U+1d561; \mathbb{p};
   ("𝕢" "qd")             ;; U+1d562; \mathbb{q};
   ("𝕣" "rd")             ;; U+1d563; \mathbb{r};
   ("𝕤" "sd")             ;; U+1d564; \mathbb{s};
   ("𝕥" "td")             ;; U+1d565; \mathbb{t};
   ("𝕦" "ud")             ;; U+1d566; \mathbb{u};
   ("𝕧" "vd")             ;; U+1d567; \mathbb{v};
   ("𝕨" "wd")             ;; U+1d568; \mathbb{w};
   ("𝕩" "xd")             ;; U+1d569; \mathbb{x};
   ("𝕪" "yd")             ;; U+1d56a; \mathbb{y};
   ("𝕫" "zd")             ;; U+1d56b; \mathbb{z};
   ;; symbols
   ("⦃" "{d")            ;; U+2983; delimiter
   ("⦄" "}d")            ;; U+2984; delimiter
   ((progn
      (insert-char #x2983)
      (when (= (char-after) #x7d)  ;; }
        (delete-char 1)
        (save-excursion
          (insert-char #x2984))))
    "{")
   ;; ("⦅" "(d")            ;; U+2985; delimiter
   ((progn
      (insert-char #x2985)
      (when (= (char-after) #x29)  ;; )
        (delete-char 1)
        (save-excursion
          (insert-char #x2986))))
    "(d")
   ("⦆" ")d")            ;; U+2986; delimiter
   ("⟦" "[d")            ;; U+27e6; delimiter
   ((progn
      (insert-char #x27e6)
      (when (= (char-after) #x5d)  ;; }
        (delete-char 1)
        (save-excursion
          (insert-char #x27e7))))
    "[")
   ("⟧" "]d")            ;; U+27e7; delimiter
   ("⟬" "[td")           ;; U+27ec; delimiter; tortoise shell bracket
   ("⟭" "]td")           ;; U+27ed; delimiter; tortoise shell bracket
   ;; numbers
   ("𝟘" "0d")           ;; U+1d7d8; number 0
   ("𝟙" "1d")           ;; U+1d7d9; number 1
   ("𝟚" "2d")           ;; U+1d7da; number 2
   ("𝟛" "3d")           ;; U+1d7db; number 3
   ("𝟜" "4d")           ;; U+1d7dc; number 4
   ("𝟝" "5d")           ;; U+1d7dd; number 5
   ("𝟞" "6d")           ;; U+1d7de; number 6
   ("𝟟" "7d")           ;; U+1d7df; number 7
   ("𝟠" "8d")           ;; U+1d7e0; number 8
   ("𝟡" "9d")           ;; U+1d7e1; number 9
   ("⦗" "[t")             ;; U+2997; delimiter; tortoise shell bracket
   ("⦘" "]t")             ;; U+2998; delimiter; tortoise shell bracket
   ((progn
      (insert-char #x2997)
      (save-excursion
        (insert-char #x2998)))
    ";;")            ;; U+2997, U+2998; delimiter; tortoise shell bracket; comment
   ((progn
      (insert-char #x27)
      (save-excursion
        (insert-char #x27)))
    "'")             ;; u+27; delimiter
   ((progn
      (insert-char #x22)
      (save-excursion
        (insert-char #x22)))
    "\"")            ;; u+22; delimiter
   ("’" "q9")           ;; u+2019; right single quotation mark
   ("‘" "q6")           ;; u+2018; left  single quotation mark
   ((progn
      (insert-char #x2019)
      (save-excursion
        (insert-char #x2018)))
    ".'")
   ("„" "q99")           ;; u+201e; double low-9 quotation mark
   ("“" "q66")           ;; u+201c; double turned comma quotation mark
   ((progn
      (insert-char #x201e)
      (save-excursion
        (insert-char #x201c)))
    ".\"")
   ("‹" "q<")           ;; u+2039; single left-‿pointing angle quotation mark
   ("›" "q>")           ;; u+203a; single right-pointing angle quotation mark
   ((progn
      (insert-char #x2039)
      (save-excursion
        (insert-char #x203a)))
    ".<")
   ("«" "q<<")           ;; u+ab; left-‿pointing double angle quotation mark
   ("»" "q>>")           ;; u+bb; right-pointing double angle quotation mark
   ((progn
      (insert-char #xab)
      (save-excursion
        (insert-char #xbb)))
    ".<<")
   ((progn
      (insert "/* ")
      (save-excursion
        (insert " */")))
    "/*")
   ("⫶" ":")             ;; U+2af6; three dots / triple dot
   ("⦙" "⫶")             ;; U+2999; four dots; dotted fence
   ("⦙" ".f")            ;; U+2999; dotted fence
   ;; ellipsis
   ("‥" "..")          ;; U+2025; two dot leader
   ("…" "...")         ;; U+2026; horizontal ellipsis
   ("⋰" ".../")        ;; U+22f0; up right diagonal ellipsis
   ("⋱" "...\\")       ;; U+22f1; down right diagonal ellipsis
   ("⋮" "...|")        ;; U+22ee; vertical ellipsis
   ("⋯" "...-")        ;; U+22ef; midline horizontal ellipsis
   ("⦂" ":z")            ;; U+2982; z notation colon
   ("⨟" ";")             ;; U+2a1f; z notation schema composition
   ("⍡" "T:")            ;; U+2361; APL
   ("⍣" "*:")            ;; U+2363; APL
   ("⍤" ".:")            ;; U+2364; APL; rank operator
   ("⌨" "kbd")           ;; U+2328; keyboard
   ("⁊" "&")             ;; u+204a; tironian sign et
   ("⌖" "pos")           ;; U+2316; position indicator
   ;; pair stuff
   ("⅄" "p")             ;; u+2144; turned capital y
   ("╮" "pl")            ;; u+256e; some box drawing stuff
   ("╭" "pr")            ;; u+256d; some box drawing stuff
   ("☡" "caut")          ;; u+2621; caution sign
   ;; graph stuff
   ("𝒢V"   "gcv")
   ("𝒢Vl"  "gcvl")
   ("𝒢Vi"  "gcvi")
   ("𝒢E"   "gce")
   ("𝒢E⥀"  "gcel")
   ("𝒢E⥀"  "𝒢El")
   ("𝒢Φ"   "gcphi")
   ("𝒢I"   "gci")
   ("𝒢I⥀"  "gcil")
   ("𝒢I⥀"  "𝒢Il")
   ("𝒢J"   "gcj")
   ("𝒢N"   "gcn")
   ("𝒢N2"  "𝒢N")
   ("𝒢N̅"   "gccn")
   ("𝒢N̅2"  "𝒢N̅")
   ("𝒢°"   "gcd")
   ("𝒢°"   "gcdeg")
   ("𝒢min°"   "gcmindeg")
   ("𝒢min°"   "gcmind")
   ("𝒢max°"   "gcmaxdeg")
   ("𝒢max°"   "gcmaxd")
   ("𝒢="   "gc=")
   ("𝒢="   "gceq")
   ("𝒢⊆"   "gcle")
   ("𝒢⊊"   "gclt")
   ("𝒢⊇"   "gcge")
   ("𝒢⊋"   "gcgt")
   ("𝒢∩"   "gccap")
   ("𝒢∪"   "gccup")
   ("𝒢:"   "gc:")
   ("𝒢:V"  "gc:v")
   ;; component stuff
   ("𝒢C"   "gcc")
   ("𝒢Cv"  "gccv")
   ("𝒢Ce"  "gcce")
   ;; subtree stuff
   ("𝒢ST"   "gcst")
   ("𝒢STe"  "gcste")
   ("𝒢STv"  "gcstv")
   ("𝒢STr"  "gcstr")
   ("𝒢STev" "gcstev")
   ("𝒢STer" "gcster")
   ("𝒢SF"   "gcsf")
   ;; 𝒟: di-graph
   ;; a : arcs
   ;; i: in
   ;; o: out
   ("𝒟V"   "dcv")
   ("𝒟Vl"  "dcvl")
   ("𝒟Vi"  "dcvi")
   ("𝒟E"   "dce")
   ("𝒟iE"  "dcie")
   ("𝒟oE"  "dcoe")
   ("𝒟E⥀"  "dcel")
   ("𝒟E⥀"  "𝒟Al")
   ("𝒟Φ"   "dcphi")
   ("𝒟iΦ"  "dciphi") ;; target
   ("𝒟oΦ"  "dcophi") ;; source
   ("𝒟I"   "dci")
   ("𝒟I⥀"  "dcil")
   ("𝒟I⥀"  "𝒟Il")
   ("𝒟iI"  "dcii")
   ("𝒟oI"  "dcoi")
   ("𝒟J"   "dcj")
   ("𝒟iJ"  "dcij")
   ("𝒟oJ"  "dcoj")
   ("𝒟°"   "dcd")
   ("𝒟°"   "dcdeg")
   ("𝒟i°"  "dcideg")
   ("𝒟o°"  "dcodeg")
   ("𝒟="   "dc=")
   ("𝒟="   "dceq")
   ("𝒟⊆"   "dcle")
   ("𝒟⊊"   "dclt")
   ("𝒟⊇"   "dcge")
   ("𝒟⊋"   "dcgt")
   ("𝒟∩"   "dccap")
   ("𝒟∪"   "dccup")
   ("𝒟:"   "dc:")
   ("𝒟:V"  "dc:v")
   ;; component stuff
   ("𝒟wC"  "dcwc") ;; weakly
   ("𝒟wCv" "dcwcv")
   ("𝒟wCe" "dcwce")
   ("𝒟sC"  "dcsc") ;; strongly
   ;; relation stuff
   ("ℛh"   "rch")
   ("ℛ2"   "rc2")
   ("ℛ2h"  "rc2h")
   ("ℛ∘"   "rc.")
   ("ℛ∩"   "rccap")
   ("ℛ∪"   "rccup")
   ("ℛ+"   "rc+")
   ("ℛ*"   "rc*")
   ("ℛ="   "rc=")
   ("ℛ="   "rceq")
   ("ℛ⊆"   "rcle")
   ("ℛ⊊"   "rclt")
   ("ℛ⊇"   "rcge")
   ("ℛ⊋"   "rcgt")
   ;; function & expression stuff
   ("𝔢⇝̇"   "efw")  ;; when
   ("𝔢⇝̈"   "efif") ;; if
   ("𝔣⇝̇"   "ffw")  ;; when
   ("𝔣⇝̈"   "ffif") ;; if
   ;; sequence stuff
   ;; index   stuff (𝔇)
   ("𝔰𝔦↓"   "sfilst")
   ("𝔰𝔦↑"   "sfigst")
   ;; element stuff (c𝔇)
   ("𝔰𝔢↓"   "sfelst")
   ("𝔰𝔢↑"   "sfegst")
   ;; sequence stuff  revamp
   ("ⓠ"  "sq")        ;; u+24ce; circled latin small letter q
   ("ⓠ◃" "sqpp")      ;; u+25c3; white left pointing small triangle
   ("ⓠ▹" "sqap")      ;; u+25b9; white right pointing small triangle
   ;; set stuff revamp
   ("Ⓢ"  "st")       ;; u+24c8; circled latin capital letter s
   ("Ⓢ"  "set")       ;; u+24c8; circled latin capital letter s
   ;; geometry stuff
   ("Ⓨ"  "gy")        ;; u+24ce; circled latin capital letter y
   ("Ⓨ⋅"  "gyp")
   ("Ⓨ↔"  "gyl")
   ("Ⓨ←"  "gyrl")
   ("Ⓨ→"  "gyrr")
   ("Ⓨ-"  "gys")
   ("Ⓨ⇀"  "gysr")
   ("Ⓨ↼"  "gysl")
   ("⋅"   "gy/p")
   ("↔"   "gy/l")
   ("←"   "gy/rl")
   ("→"   "gy/rr")
   ("-"   "gy/s")
   ("⇀"   "gy/sr")
   ("↼"   "gy/sl")
   ;; [p]olygonal [chain]
   ("Ⓨ⌁"  "gypc")        ;; u+2301; electric arrow
   ("⌁"   "gy/pc")        ;; u+2301; electric arrow
   ("Ⓨ⌁⋅"  "gypcp")
   ("Ⓨ⌁AⓈ"  "gypcas")
   ("Ⓨ⌁VⓈ"  "gypcvs")
   ("Ⓨ⌁Aⓠ"  "gypcaq")
   ("Ⓨ⌁Vⓠ"  "gypcvq")
   ;; expression stuff
   ;; substitution
   ("↶"  "efwh")        ;; u+21b6; anticlockwise top semicircle; arrow
   ("↷"  "efin")        ;; u+21b7; clockwise top semicircle; arrow
   ;; mi:  mathematical italic
   ("𝐴" "Ami")             ;; U+1d434
   ("𝐵" "Bmi")             ;; U+1d435
   ("𝐶" "Cmi")             ;; U+1d436
   ("𝐷" "Dmi")             ;; U+1d437
   ("𝐸" "Emi")             ;; U+1d438
   ("𝐹" "Fmi")             ;; U+1d439
   ("𝐺" "Gmi")             ;; U+1d43a
   ("𝐻" "Hmi")             ;; U+1d43b
   ("𝐼" "Imi")             ;; U+1d43c
   ("𝐽" "Jmi")             ;; U+1d43d
   ("𝐾" "Kmi")             ;; U+1d43e
   ("𝐿" "Lmi")             ;; U+1d43f
   ("𝑀" "Mmi")             ;; U+1d440
   ("𝑁" "Nmi")             ;; U+1d441
   ("𝑂" "Omi")             ;; U+1d442
   ("𝑃" "Pmi")             ;; U+1d443
   ("𝑄" "Qmi")             ;; U+1d444
   ("𝑅" "Rmi")             ;; U+1d445
   ("𝑆" "Smi")             ;; U+1d446
   ("𝑇" "Tmi")             ;; U+1d447
   ("𝑈" "Umi")             ;; U+1d448
   ("𝑉" "Vmi")             ;; U+1d449
   ("𝑊" "Wmi")             ;; U+1d44a
   ("𝑋" "Xmi")             ;; U+1d44b
   ("𝑌" "Ymi")             ;; U+1d44c
   ("𝑍" "Zmi")             ;; U+1d44d
   ("𝑎" "ami")             ;; U+1d44e
   ("𝑏" "bmi")             ;; U+1d44f
   ("𝑐" "cmi")             ;; U+1d450
   ("𝑑" "dmi")             ;; U+1d451
   ("𝑒" "emi")             ;; U+1d452
   ("𝑓" "fmi")             ;; U+1d453
   ("𝑔" "gmi")             ;; U+1d454
   ("ℎ" "hmi")             ;; U+210e
   ("𝑖" "imi")             ;; U+1d456
   ("𝑗" "jmi")             ;; U+1d457
   ("𝑘" "kmi")             ;; U+1d458
   ("𝑙" "lmi")             ;; U+1d459
   ("𝑚" "mmi")             ;; U+1d45a
   ("𝑛" "nmi")             ;; U+1d45b
   ("𝑜" "omi")             ;; U+1d45c
   ("𝑝" "pmi")             ;; U+1d45d
   ("𝑞" "ami")             ;; U+1d45e
   ("𝑟" "rmi")             ;; U+1d45f
   ("𝑠" "smi")             ;; U+1d460
   ("𝑡" "tmi")             ;; U+1d461
   ("𝑢" "umi")             ;; U+1d462
   ("𝑣" "vmi")             ;; U+1d463
   ("𝑤" "wmi")             ;; U+1d464
   ("𝑥" "xmi")             ;; U+1d465
   ("𝑦" "ymi")             ;; U+1d466
   ("𝑧" "zmi")             ;; U+1d467
   ;; c:  cal
   ("𝒜" "Ac")             ;; U+1d49c; \mathcal{A}
   ("ℬ" "Bc")             ;; U+212c;  \mathcal{B}
   ("𝒞" "Cc")             ;; U+1d49e; \mathcal{C}
   ("𝒟" "Dc")             ;; U+1d49f; \mathcal{D}
   ("ℰ" "Ec")             ;; U+2130;  \mathcal{E}
   ("ℱ" "Fc")             ;; U+2131;  \mathcal{F}
   ("𝒢" "Gc")             ;; U+1d4a2; \mathcal{G}
   ("ℋ" "Hc")             ;; U+210b;  \mathcal{H}
   ("ℐ" "Ic")             ;; U+2110;  \mathcal{I}
   ("𝒥" "Jc")             ;; U+1d4a5; \mathcal{J}
   ("𝒦" "Kc")             ;; U+1d4a6; \mathcal{K}
   ("ℒ" "Lc")             ;; U+2112;  \mathcal{L}
   ("ℳ" "Mc")             ;; U+2133;  \mathcal{M}
   ("𝒩" "Nc")             ;; U+1d4a9; \mathcal{N}
   ("𝒪" "Oc")             ;; U+1d4aa;  mathcal{O}
   ("𝒫" "Pc")             ;; U+1d4ab;  mathcal{P}
   ("𝒬" "Qc")             ;; U+1d4ac;  mathcal{Q}
   ("ℛ" "Rc")             ;; U+211b;  \mathcal{R}
   ("𝒮" "Sc")             ;; U+1d4ae; \mathcal{S}
   ("𝒯" "Tc")             ;; U+1d4af; \mathcal{T}
   ("𝒰" "Uc")             ;; U+1d4b0; \mathcal{U}
   ("𝒱" "Vc")             ;; U+1d4b1; \mathcal{V}
   ("𝒲" "Wc")             ;; U+1d4b2; \mathcal{W}
   ("𝒳" "Xc")             ;; U+1d4b3; \mathcal{X}
   ("𝒴" "Yc")             ;; U+1d4b4; \mathcal{Y}
   ("𝒵" "Zc")             ;; U+1d4b5; \mathcal{Z}
   ("𝒶" "ac")             ;; U+1d4b6; \mathcal{a}
   ("𝒷" "bc")             ;; U+1d4b7; \mathcal{b}
   ("𝒸" "cc")             ;; U+1d4b8; \mathcal{c}
   ("𝒹" "dc")             ;; U+1d4b9; \mathcal{d}
   ("ℯ" "ec")             ;; U+212f;  \mathcal{e}
   ("𝒻" "fc")             ;; U+1d4bb; \mathcal{f}
   ("ℊ" "gc")             ;; U+210a;  \mathcal{g}
   ("𝒽" "hc")             ;; U+1d4bd; \mathcal{h}
   ("𝒾" "ic")             ;; U+1d4be; \mathcal{i}
   ("𝒿" "jc")             ;; U+1d4bf; \mathcal{j}
   ("𝓀" "kc")             ;; U+1d4c0; \mathcal{k}
   ("𝓁" "lc")             ;; U+1d4c1; \mathcal{l}
   ("𝓂" "mc")             ;; U+1d4c2; \mathcal{m}
   ("𝓃" "nc")             ;; U+1d4c3; \mathcal{n}
   ("ℴ" "oc")             ;; U+2134;  \mathcal{0}
   ("𝓅" "pc")             ;; U+1d4c5; \mathcal{p}
   ("𝓆" "qc")             ;; U+1d4c6; \mathcal{q}
   ("𝓇" "rc")             ;; U+1d4c7; \mathcal{r}
   ("𝓈" "sc")             ;; U+1d4c8; \mathcal{s}
   ("𝓉" "tc")             ;; U+1d4c9; \mathcal{t}
   ("𝓊" "uc")             ;; U+1d4ca; \mathcal{u}
   ("𝓋" "vc")             ;; U+1d4cb; \mathcal{v}
   ("𝓌" "wc")             ;; U+1d4cc; \mathcal{w}
   ("𝓍" "xc")             ;; U+1d4cd; \mathcal{x}
   ("𝓎" "yc")             ;; U+1d4ce; \mathcal{y}
   ("𝓏" "zc")             ;; U+1d4cf; \mathcal{z}
   ;; crc:  circled
   ("Ⓐ" "Acrc")             ;; u+24b6
   ("Ⓑ" "Bcrc")             ;; u+24b7
   ("Ⓒ" "Ccrc")             ;; u+24b8
   ("Ⓓ" "Dcrc")             ;; u+24b9
   ("Ⓔ" "Ecrc")             ;; u+24ba
   ("Ⓕ" "Fcrc")             ;; u+24bb
   ("Ⓖ" "Gcrc")             ;; u+24bc
   ("Ⓗ" "Hcrc")             ;; u+24bd
   ("Ⓘ" "Icrc")             ;; u+24be
   ("Ⓙ" "Jcrc")             ;; u+24bf
   ("Ⓚ" "Kcrc")             ;; u+24c0
   ("Ⓛ" "Lcrc")             ;; u+24c1
   ("Ⓜ" "Mcrc")             ;; u+24c2
   ("Ⓝ" "Ncrc")             ;; u+24c3
   ("Ⓞ" "Ocrc")             ;; u+24c4
   ("Ⓟ" "Pcrc")             ;; u+24c5
   ("Ⓠ" "Qcrc")             ;; u+24c6
   ("Ⓡ" "Rcrc")             ;; u+24c7
   ("Ⓢ" "Scrc")             ;; u+24c8
   ("Ⓣ" "Tcrc")             ;; u+24c9
   ("Ⓤ" "Ucrc")             ;; u+24ca
   ("Ⓥ" "Vcrc")             ;; u+24cb
   ("Ⓦ" "Wcrc")             ;; u+24cc
   ("Ⓧ" "Xcrc")             ;; u+24cd
   ("Ⓨ" "Ycrc")             ;; u+24ce
   ("Ⓩ" "Zcrc")             ;; u+24cf
   ("ⓐ" "acrc")             ;; u+24d0
   ("ⓑ" "bcrc")             ;; u+24d1
   ("ⓒ" "ccrc")             ;; u+24d2
   ("ⓓ" "dcrc")             ;; u+24d3
   ("ⓔ" "ecrc")             ;; u+24d4
   ("ⓕ" "fcrc")             ;; u+24d5
   ("ⓖ" "gcrc")             ;; u+24d6
   ("ⓗ" "hcrc")             ;; u+24d7
   ("ⓘ" "icrc")             ;; u+24d8
   ("ⓙ" "jcrc")             ;; u+24d9
   ("ⓚ" "kcrc")             ;; u+24da
   ("ⓛ" "lcrc")             ;; u+24db
   ("ⓜ" "mcrc")             ;; u+24dc
   ("ⓝ" "ncrc")             ;; u+24dd
   ("ⓞ" "ocrc")             ;; u+24de
   ("ⓟ" "pcrc")             ;; u+24df
   ("ⓠ" "qcrc")             ;; u+24e0
   ("ⓡ" "rcrc")             ;; u+24e1
   ("ⓢ" "scrc")             ;; u+24e2
   ("ⓣ" "tcrc")             ;; u+24e3
   ("ⓤ" "ucrc")             ;; u+24e4
   ("ⓥ" "vcrc")             ;; u+24e5
   ("ⓦ" "wcrc")             ;; u+24e6
   ("ⓧ" "xcrc")             ;; u+24e7
   ("ⓨ" "ycrc")             ;; u+24e8
   ("ⓩ" "zcrc")             ;; u+24e9
   ("∇" "nbl")           ;; U+2207; nabla; gradient; differentiation; derivative
   ("△" "tri")           ;; U+25b3; geometry; white up pointing triangle
   ("□" "quad")          ;; U+25a1; geometry; quadrilateral
   ;; closed polygonal chain
   ("△" "cpc")           ;; U+25b3; geometry; white up pointing triangle;
   ("◬" "cpcio")         ;; U+25ec; geometry; white up pointing triangle with dot; [i]nside , [o]pen region
   ("△̣" "cpcoo")         ;; U+25b3 , u+0323 ; geometry; white up pointing triangle , combining dot below;  [o]utside , [o]pen region
   ("◬̅" "cpcic")         ;; U+25ec , u+0305; geometry; white up pointing triangle with dot;  [i]nside , [c]losed region
   ("△̣̅" "cpcoc")         ;; U+25b3 , u+0323 , u+0305 ; geometry; white up pointing triangle , combining dot below;  [o]utside , [c]losed region
   ("⟂" "orth")          ;; U+27c2; geometry; orthogonal
   ("⟂" "perp")          ;; U+27c2; geometry; perpendicular
   ("∥" "para")          ;; U+2225; geometry; parallel
   ("∦" "npara")         ;; U+2226; geometry; not parallel
   ("∠" "ang")           ;; U+2220; geometry; angle; \angle{}
   ("∡" "mang")          ;; U+2221; geometry; measured angle
   ("∟" "rang")          ;; U+221f; geometry; right angle
   ("⊾" "mrang")         ;; U+22be; geometry; right angle with arc (measured right angle)
   ("⊢" "tee")           ;; U+22a2; right tack; turnstile, tee, yields; syntactic consequence; \vdash{}; proof theory
   ("⊬" "ntee")          ;; U+22ac; DOES NOT PROVE; proof theory
   ("⊨" "dtee")          ;; U+22a8; double turnstile; entails; semantic consequence; \models{}; model theory
   ("⊭" "ndtee")         ;; U+22ad; NOT TRUE; not entails; model theory
   ("⁀" "ti")            ;; u+2040; character tie; typography
   ("‿" "ut")            ;; u+203f; undertie
   ("TODO:" "t;")        ;; tag
   ("DONE:" "d;")        ;; tag
   ("WIP:"  "w;")        ;; tag
   ("NOTE:" "n;")        ;; tag
   ("NOTE: / TODO: " "nt;")        ;; tag
   ("NEXT:" "tt;")       ;; tag
   ("DEFERRED:" "df;")   ;; tag
   ("ORG:TODO: " "ot;")  ;; tag
   ("ORG:" "o;")  ;; tag
   ("ORG:DONE: " "od;")  ;; tag
   ("ß" "ss")            ;;
   ("ö" "oe")            ;;
   ("ä" "ae")            ;;
   ("ü" "ue")            ;;
   ("Ö" "ö")             ;;
   ("Ä" "ä")             ;;
   ("Ü" "ü")             ;;
   ;; open and closed balls; 'tb' for "topolgical ball"
   ("◌"  "tbo")            ;; u+25cc; dotted circle; open ball (ball open)
   ("○"  "tbc")            ;; u+25cb; white circle; closed ball (ball closed)
   ("◌3" "tb3")          ;; u+25cc; dotted circle; open ball (ball open)
   ("○3" "tb3")          ;; u+25cb; white circle; closed ball (ball closed)
   ("◌2" "tb2")          ;; u+25cc; dotted circle; open ball (ball open)
   ("○2" "tb2")          ;; u+25cb; white circle; closed ball (ball closed)
   ("∎"  "eop")          ;; u+220e; end of proof; q e d
   ("𝕃≥" "ldge")
   ("𝕃≤" "ldle")
   ("𝕃=" "lde")
   ("𝕃>" "ldgt")
   ("𝕃<" "ldlt")
   ("⤢" "sca")           ;; u+2922; north east and south west arrow; transformation; scale; arrow
   ("↶2" "ht2")          ;; u+21b6; anticlockwise top semicircle; arrow
   ("↶2" "ht2ccw")       ;; u+21b6; anticlockwise top semicircle; arrow
   ("↷2" "ht2cw")        ;; u+21b7; clockwise top semicircle; arrow
   ("⇶" "ea3")           ;; u+21f6; arrow; three rightwards arrows
   ("⇉" "ea2")           ;; u+21c9; arrow; rightwards paired arrows
   ("⇇" "wa2")           ;; u+21c7; arrow; leftwards paired arrows
   ("⇶"  "tpv")          ;; translation ∈ point-sets ⨯ vectors
   ("⇉2" "tvp2")         ;; u+21c9; arrow; rightwards paired arrows; translation ∈ vectors ⨯ point-sets
   ("⍆2" "ref2")         ;; u+2346; APL; apl functional symbol rightwards vane; reflection on line
   ("⍆2" "ref2")         ;; u+2346; APL; apl functional symbol rightwards vane; reflection on hyperplane
   ("⤿2" "rot2ccw")      ;; u+293f + .; rotate ccw
   ("⤿2" "rot2")         ;; u+293f + .; rotate ccw
   ("⤾2" "rot2cw")       ;; u+293f + .; rotate cw
   ;; half-space stuff
   ("𝟚𝒽↺"  "2hol")     ;; [2]-dimensions [h]alf space [o]pen   [l]eft
   ("𝟚𝒽↻"  "2hor")     ;; [2]-dimensions [h]alf space [o]pen   [r]ight
   ("𝟚𝒽∋"  "2hop")     ;; [2]-dimensions [h]alf space [o]pen   [p]oint
   ("𝟚𝒽↺𝓈⃗" "2hols")    ;; [2]-dimensions [h]alf space [o]pen   [l]eft  [s]egment input
   ("𝟚𝒽↻𝓈⃗" "2hors")    ;; [2]-dimensions [h]alf space [o]pen   [r]ight [s]egment input
   ("𝟚𝒽̅↺"  "2hcl")     ;; [2]-dimensions [h]alf space [c]losed [l]eft
   ("𝟚𝒽̅↻"  "2hcr")     ;; [2]-dimensions [h]alf space [c]losed [r]ight
   ("𝟚𝒽̅∋"  "2hcp")     ;; [2]-dimensions [h]alf space [c]losed [p]oint
   ("𝟚𝒽̅↺𝓈⃗" "2hcls")    ;; [2]-dimensions [h]alf space [c]losed [l]eft  [s]egment input
   ("𝟚𝒽̅↻𝓈⃗" "2hcrs")    ;; [2]-dimensions [h]alf space [c]losed [r]ight [s]egment input
   ((insert-char #x0338) ";/")       ;; U+0338; combining long solidus
   ("∽" "~")                         ;; u+223d; reverse tilde
   ((insert-char #x0303) "^~")       ;; U+0303; combining tilde
   ((insert-char #x0305) "ov")       ;; U+0305; combining overline
   ((insert-char #x030a) "°")        ;; U+030a; combining ring above
   ((insert-char #x034f) "cgj")      ;; U+034f; combining graphemere joiner
   ((progn
      (insert-char #x1d4c8)
      (insert-char #x20d7))
    "scr")                           ;; U+1d4c8; \mathcal{s} with: U+20d7; combining right arrow above; right directed segment
   ((progn
      (insert-char #x1d4c8)
      (insert-char #x20d6))
    "scl")                           ;; U+1d4c8; \mathcal{s} with: U+20d6; combining left arrow above; left directed segment
   ;; a: above suffix
   ((insert-char #x20d7) "toa")      ;; U+20d7; combining right arrow above
   ((insert-char #x20d7) "eaa")      ;; U+20d7; combining right arrow above
   ((insert-char #x20d6) "waa")      ;; U+20d6; combining left arrow above
   ;; currency
   ("$" "usd")
   ("€" "eur")
   ("₣" "Fr")
   ("₩" "krw")
   )
 "entries have form (EXPANSION ABBREV-OR-LIST-OF-ABBREVS)
ere EXPANSION is either a string (replacing the abbrev) or a function that will be executed after deleting the abbrev.
so see `my/unicode-abbrev/table'.
TE: / TODO: currently only (UNICODE-CHAR ABBREV) supported")

(defun my/unicode-abbrev/table:create ()
  "see `my/unicode-abbrev/table'"
  (-sort
   #'(lambda (list1 list2)
       (string< (car list1) (car list2)))
   (mapcar #'(lambda (list)
               (let ((abbrev (cadr list))
                     (todo (car list)))
                 (cons abbrev
                       (cond
                        ((stringp todo)
                         (cons 'string todo))
                        (t
                         (cons 'function `(lambda () ,todo)))))))
           my/unicode-abbrev/list)))

(defvar my/unicode-abbrev/table
  (my/unicode-abbrev/table:create)
  "Table to be used for `my/unicode-abbrev/reverse-abbrevs-prefix-tree'.
tries have form (ABBREV . EXPANSION).
nerated from `my/unicode-abbrev/list' and sorted by ABBREV entry.")

(defun my/unicode-abbrev/reverse-abbrevs-prefix-tree:create ()
  "see `my/unicode-abbrev/reverse-abbrevs-prefix-tree'"
  (let* ((table my/unicode-abbrev/table)
         ;; entries in table have form (ABBREV . EXPANSION)
         (root (my/trie/init-with-first-string
                (cdar table) (reverse (caar table)))))
    (mapc #'(lambda (pair)
              (my/trie/insert root (cdr pair) (reverse (car pair))))
          (cdr table))
    root))

(defvar my/unicode-abbrev/reverse-abbrevs-prefix-tree
  (my/unicode-abbrev/reverse-abbrevs-prefix-tree:create)
  "Data structure used in `my/unicode-abbrev/expand'.
eated from `my/unicode-abbrev/table'")

(defun my/unicode-abbrev/update (&optional unicode-abbrev-list)
  "`unicode-abbrev-list' has form of `my/unicode-abbrev/list'"
  (interactive)
  (when unicode-abbrev-list
    (setq my/unicode-abbrev/list unicode-abbrev-list))
  (setq my/unicode-abbrev/table (my/unicode-abbrev/table:create))
  (setq my/unicode-abbrev/reverse-abbrevs-prefix-tree (my/unicode-abbrev/reverse-abbrevs-prefix-tree:create))
  my/unicode-abbrev/table)

(defun my/unicode-abbrev/expand ()
  "Expands stuff in `my/unicode-abbrev/table' via
 `my/unicode-abbrev/reverse-abbrevs-prefix-tree'.
 NOTE: expands shortest possible abbrev (greedy)." 
  (interactive)
  (let ((info
         (when (> (point) (point-min))
           (cl-do* ((start (- (point) 1) (- start 1))
                    (node (my/trie/find-char (char-after start) my/unicode-abbrev/reverse-abbrevs-prefix-tree)
                          (my/trie/find-char (char-after start) node)))
               ((or (null node) (my/trie/string node) (>= (point-min) start))
                (when (and node (my/trie/string node))
                  (cl-values start (my/trie/value node))))))))
    (when info
      (cl-destructuring-bind (start expansion) info
        (delete-region start (point))
        (insert expansion)))))

(defun my/unicode-abbrev/expand ()
  "Expands stuff in `my/unicode-abbrev/table' via
y/unicode-abbrev/reverse-abbrevs-prefix-tree'.
TE: expands longest possible abbrev." 
  (interactive)
  (let ((info
         (when (> (point) (point-min))
           (cl-do* ((start (- (point) 1)
                           (- start 1))
                    (node (my/trie/find-char (char-after start) my/unicode-abbrev/reverse-abbrevs-prefix-tree)
                          (my/trie/find-char (char-after start) node))
                    (exp  (my/trie/value node)
                          (my/trie/value node))
                    (info (when (and node exp) (list start exp))
                          (or (when (and node exp) (list start exp))
                              info)))
               ((or (null node) (>= (point-min) start))
                info)))))
    (if info
        (cl-destructuring-bind (start expansion) info
          (delete-region start (point))
          (let ((type (car expansion))
                (payload (cdr expansion)))
            (cond
             ((eq type 'string)
              (insert payload))
             ((eq type 'function)
              (funcall payload))
             (t (message "expansion type not implemented")))))
      (message "no expansion found"))))


(provide 'my--unicode-abbrev)
