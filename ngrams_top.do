
* This dofile identifies the top n-grams in terms of lifetime mentions within each vintage
* It also identifies all of the PMIDs that use these top n-grams

**************************************************************************************************
**************************************************************************************************
* User must set the outpath and the inpath.
global inpath1="B:\Research\RAWDATA\MEDLINE\2014\Parsed\NGrams\dtafiles"
global inpath2="B:\Research\RAWDATA\MEDLINE\2014\Processed"
global outpath="B:\Research\RAWDATA\MEDLINE\2014\Processed"
**************************************************************************************************

clear
cd $inpath2
use ngrams_mentions, replace

cd $inpath2
merge 1:1 ngram using ngrams_vintage
drop _merge
keep ngram mentions_wi mentions_bt vintage

cd $inpath2
merge 1:1 ngram using ngrams_id
drop _merge

* Sort the top ngrams within each vintage
gsort vintage -mentions_bt ngram
by vintage, sort: gen rank_=_n
by vintage mentions_bt, sort: egen rank=min(rank_)
by vintage, sort: gen total=_N
gen pct=rank/total
gen top_001=0
replace top_001=1 if pct<0.001
gen top_0001=0
replace top_0001=1 if pct<0.0001

keep if top_001==1

* Give each ngram a numeric identifier. This dramatically decreases storage requirements
sort vintage ngram
order ngramid ngram

compress
cd $outpath
save ngrams_top_new, replace




************************************************************************************
*************************************************************************************

************************************************************************************
*************************************************************************************
clear
gen filenum=.
cd $outpath
save ngrams_top_pmids_001_new, replace

local initialfiles 1 101 201 301 401 501 601 701
local terminalfile=746
local fileinc=99

clear
set more off
foreach h in `initialfiles' {

	local startfile=`h'
	local endfile=`startfile'+`fileinc'
	if (`endfile'>`terminalfile') {
		local endfile=`terminalfile'
	}
	
	clear
	set more off
	gen ngramid=.
	cd $outpath
	save ngrams_top_pmids_001_`startfile'_`endfile', replace

	forvalues i=`startfile'/`endfile' {

		display in red "------ File `i' --------"

		cd $inpath1
		use medline14_`i'_ngrams, clear
		keep filenum pmid version ngram
		cd $outpath
		merge m:1 ngram using ngrams_top_new
		keep if _merge==3
		keep filenum pmid version ngramid vintage
		
		if (_N>0) {
			compress
			duplicates drop

			cd $outpath
			append using ngrams_top_pmids_001_`startfile'_`endfile'
			save ngrams_top_pmids_001_`startfile'_`endfile', replace
		}
	}
	
	cd $outpath
	use ngrams_top_pmids_001_new, clear
	append using ngrams_top_pmids_001_`startfile'_`endfile'
	compress
	sort ngram
	save ngrams_top_pmids_001_new, replace
	erase ngrams_top_pmids_001_`startfile'_`endfile'.dta
}


cd $inpath2
use medline_wos_intersection if filenum==`i'
merge 1:m pmid using `hold2'
keep if _merge==3
keep filenum pmid pubyear version ngramid vintage ngram
