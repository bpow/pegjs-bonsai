/*
   An attempt at parsing [HGVS variant nomenclature](http://www.w3.org/TR/prov-n/)
*/

start = (hgvs:hgvs "\n"?)*

hgvs = sequence:(id:sequence_identifier ":" {return id; })?
	allele:allele

// Arguably could make *, X and Ter separate from AA and AA2
AA1 = [GAVLIMFWPSTCYNQDEKRHX*]

AA3 = 'Gly' / 'Ala' / 'Val' / 'Leu' / 'Ile' / 'Met' / 'Phe' /
      'Trp' / 'Pro' / 'Ser' / 'Thr' / 'Cys' / 'Tyr' / 'Asn' /
      'Gln' / 'Asp' / 'Glu' / 'Lys' / 'Arg' / 'His' / 'Sec' /
      'Ter' / 'TER' // NOTE: 'TER' is non-standard

AA = AA3 / AA1

BASE = [ACGTUBDHVKMNRSWY]i // NOTE: lower-case is non-standard
BASES = $(BASE+)

sequence_identifier =
    sequence_name:name
    version:("." _:integer)?
    gene:("(" _:name ")")? // TODO: isoforms/transcripts

allele =
    genomic_allele /
	transcript_allele /
	protein_allele

base_del_ins_dup = (
        "del" del:BASES "ins" ins:BASES /
        "delins" ins:BASES /
        "del" del:BASES? /
        "ins" ins:BASES /
        "dup" dup:BASES?
    )

genomic_allele = type:("g" / "m") "." locvar:(
    genomic_simple_allele /
	trans_genomic_alleles /
	cis_genomic_alleles
)

cis_genomic_alleles =
	"[" cisalleles:( _:genomic_simple_allele (";" / &"]") )+ "]"

trans_genomic_alleles = (alleles:cis_genomic_alleles (";" / !cis_genomic_alleles))+ 

genomic_simple_allele = (
    loc:simple_coord variant:(
        base:BASE "=" /
        ref:BASE ">" alt:BASE /
        indel:base_del_ins_dup
    ) /
    loc:simple_coord_range variant:base_del_ins_dup
)

transcript_allele = type:("r" / "c" / "n") "." allele:(
    transcript_simple_allele /
    trans_transcript_alleles /
    cis_transcript_alleles
)

cis_transcript_alleles =
	"[" cisalleles:( transcript_simple_allele _:(";" / &"]") )+ "]"

trans_transcript_alleles = (alleles:cis_transcript_alleles (";" / !cis_transcript_alleles))+ 

transcript_simple_allele = (
    transcript_coord (
        base:BASE "=" /
        from:BASE ">" to:BASE /
        base_del_ins_dup
    ) /
    transcript_coord_range base_del_ins_dup
)

protein_allele = type:"p" "."
	locvar:(certain:protein_locvar / uncertain:('(' _:protein_locvar ')'))

protein_locvar = untested:'?' / equal:'=' /
	coord:protein_coord edit:protein_edit

protein_edit =
	fs:(alt:AA? frameshift:frameshift) /
	subst:(AA / '?') /
	equals:"=" /
	delins:("delins" _:$(AA+)) /
	del:("del") /
	ins:("ins" _:$(AA+)) /
	dup:("dup") 

frameshift = fs:"fs" [*X]? offset:(integer/"?")?

protein_coord = pep:AA pos:integer rangeto:(pep:AA pos:integer)?

pep_extra = ("=" / "?")? "fs"

transcript_coord = special_offset:([\-*])? anchor:integer offset:([\-+] integer )?

transcript_coord_range = from:transcript_coord "_" to:transcript_coord

simple_coord = coord:integer

simple_coord_range = from:simple_coord "_" to:simple_coord

integer = digits:[0-9]+ { return parseInt(text()); }

name = $([a-zA-Z0-9_\-]+)
gene_symbol = $([a-zA-Z0-9\-])
