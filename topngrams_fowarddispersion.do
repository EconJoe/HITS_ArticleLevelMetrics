
cd $processed
use ngrams_top_new, clear
keep ngramid ngram
cd $outpath
save ngram_temp, replace



******************************************************************************************
******************************************************************************************
* Compute both the total number (raw) and fractionalized number of times that each RAW
*   MeSH term uses each n-gram. 

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
	*_merge==1 (n-grams that are not top n-grams--drop these since we are only computing dispersion metrics for top-n-grams)
	*_merge==2 (top n-grams that are not in file `i'. No problem here-drop).
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

	* Replace the MeSH terms with the MeSH IDs. This is just to reduce memory requirements.
	cd $meshtree
	import delimited "desc2014_meshtreenumbers.txt", clear varnames(1) delimiter(tab)	
	keep mesh meshid
	duplicates drop
	merge 1:m mesh using `hold2'
	drop if _merge==1
	drop _merge
	drop mesh

	if (_N>0) {

		* Compute the total number of raw MeSH terms that tag each article.
		* Then apportion the article equally across these MeSH terms.
		gen meshcount=1
		by pmid version, sort: egen meshtotal=total(meshcount)
		gen meshweight=meshcount/meshtotal
		drop meshtotal

		* Create every pairwise combintation of an article, n-gram, and RAW MeSH term. Our goal is to apportion each
		*  n-gram across the MeSH terms of the articles that use the MeSH term.
		* CONSIDER MOVING THE PROCESSING OF THE N-GRAM FILE DOWN HERE. NO REASON TO HOLD SUCH A LARGE FILE IN 
		*  MEMORY FOR SO LONG. THOUGH KEEPING IT UP THERE IS MORE CONSISTENT WITH 4DIGIT TERM CODE BELOW.
		joinby pmid version using `hold1'
		*order ngramid meshid pmid version
		*sort ngramid pmid meshid
		* Compute the total number of times each n-gram is used by a raw MeSH term. Also compute
		*  the fractionalized total.
		collapse (sum) meshcount meshweight, by(meshid ngram) fast
		
		* Append the full file and re-collapse across MeSH terms and n-grams.
		cd $outpath
		append using ngramsmeshtermsraw_forwarddispersion
		collapse (sum) meshcount meshweight, by(meshid ngram) fast
		order ngram meshid
		sort ngram meshid
		compress
		save ngramsmeshtermsraw_forwarddispersion, replace
	}
}
******************************************************************************************



******************************************************************************************
******************************************************************************************
* Compute both the total number (raw) and fractionalized number of times that each 4DIGIT
*   MeSH term uses each n-gram. 

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
	*_merge==1 (n-grams that are not top n-grams--drop these since we are only computing dispersion metrics for top-n-grams)
	*_merge==2 (top n-grams that are not in file `i'. No problem here-drop).
	keep if _merge==3
	drop _merge
	keep pmid version ngramid
	tempfile hold
	save `hold', replace
	
	cd $processed
	use medline14_mesh_4digit if filenum==`i', clear
	* Create every pairwise combintation of an article, n-gram, and 4DIGIT MeSH term. Our goal is to apportion each
	*  n-gram across the MeSH terms of the articles that use the MeSH term.
	joinby pmid version using `hold'
	*order ngramid meshid pmid version
	*sort ngramid pmid meshid

	if (_N>0) {
	
		* Compute the total number of times each n-gram is used by a 4DIGIT MeSH term. Also compute
		*  the fractionalized total.
		gen meshcount_4digit=1
		collapse (sum) meshcount_4digit mesh_4digit_weight, by(meshid ngram) fast
		
		* Append the full file and re-collapse across MeSH terms and n-grams.
		cd $outpath
		append using ngramsmeshterms4digit_forwarddispersion
		collapse (sum) meshcount_4digit mesh_4digit_weight, by(meshid ngram) fast
		order ngram meshid
		sort ngram meshid
		compress
		save ngramsmeshterms4digit_forwarddispersion, replace
	}
}
******************************************************************************************
