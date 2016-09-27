
cd $processed
use ngrams_top_new, clear
keep ngramid ngram
cd $outpath
save ngram_temp, replace

clear
gen ngramid=.
cd $outpath
save ngramsmeshtermsraw_forwarddispersion, replace

set more off
forvalues i=1/746 {

	display in red "------- File `i' --------"

	cd $ngramfilepath
	use medline14_`i'_ngrams, clear
	drop if dim=="null"
	keep pmid version ngram
	duplicates drop
	cd $outpath
	merge m:1 ngram using ngram_temp
	keep if _merge==3
	drop _merge
	keep pmid version ngramid
	tempfile hold1
	save `hold1', replace

	cd $medlinemesh
	import delimited "medline14_`i'_mesh.txt", clear varnames(1) delimiter(tab)
	keep if type=="Descriptor"
	keep filenum pmid version mesh
	tempfile hold2
	save `hold2', replace

	cd $meshtree
	import delimited "desc2014_meshtreenumbers.txt", clear varnames(1) delimiter(tab)	
	keep mesh meshid
	duplicates drop
	merge 1:m mesh using `hold2'
	drop if _merge==1
	drop _merge
	drop mesh

	if (_N>0) {

		gen meshcount=1
		by pmid version, sort: egen meshtotal=total(meshcount)
		gen meshweight=meshcount/meshtotal
		drop meshtotal

		joinby pmid version using `hold1'
		collapse (sum) meshcount meshweight, by(meshid ngram) fast
		
		cd $outpath
		append using ngramsmeshtermsraw_forwarddispersion
		collapse (sum) meshcount meshweight, by(meshid ngram) fast
		order ngram meshid
		sort ngram meshid
		compress
		save ngramsmeshtermsraw_forwarddispersion, replace
	}
}



clear
gen ngramid=.
cd $outpath
save ngramsmeshterms4digit_forwarddispersion, replace

set more off
forvalues i=1/746 {

	display in red "------- File `i' --------"

	cd $ngramfilepath
	use medline14_`i'_ngrams, clear
	drop if dim=="null"
	keep pmid version ngram
	duplicates drop
	cd $outpath
	merge m:1 ngram using ngram_temp
	keep if _merge==3
	drop _merge
	keep pmid version ngramid
	tempfile hold
	save `hold', replace
	
	cd $processed
	use medline14_mesh_4digit if filenum==`i', clear
	joinby pmid version using `hold'

	if (_N>0) {

		gen meshcount_4digit=1
		collapse (sum) meshcount_4digit mesh_4digit_weight, by(meshid ngram) fast
		
		cd $outpath
		append using ngramsmeshterms4digit_forwarddispersion
		collapse (sum) meshcount_4digit mesh_4digit_weight, by(meshid ngram) fast
		order ngram meshid
		sort ngram meshid
		compress
		save ngramsmeshterms4digit_forwarddispersion, replace
	}
}







