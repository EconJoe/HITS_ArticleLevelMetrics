
* Set paths for files used in the dofile metrics_articlelevel_importclean.do
* Since we are passing a variable to another dofile, we need to declare these paths as global variables
global processed "B:\Research\RAWDATA\MEDLINE\2014\Processed"
global ngramfilepath "B:\Research\RAWDATA\MEDLINE\2014\Parsed\NGrams\dtafiles"
global outpath "B:\Research\Projects\HITS_ArticleLevel\HITS_ArticleLevel2\Data"
global code "B:\Research\Projects\HITS_ArticleLevel\HITS_ArticleLevel2\Code_HITS_ArticleLevel2"
global medlinemesh "B:\Research\RAWDATA\MEDLINE\2014\Parsed\MeSH"
global meshtree "B:\Research\RAWDATA\MeSH\2014\Parsed"

*************************************************************************************
*************************************************************************************
* Construct a set of files that contain each PMID along with a list of all n-grams
*  used in the title or abstract. This files will be used multipel times to construct
*  various article-level metrics. However, they are merely intermediate files, and
*  do not need to be retained after all metrics are computed. They are created in the first
*  place because they take a while and it would be inefficient to recreate them each time
*  we wanted to compute a new metric.

* Create a file that contains information for every n-gram in the MEDLINE corpus.
*  Mainly we want to create a set of files with the ngram replaced with an n-gram ID
*  in order to save space.
cd $processed
use ngrams_id, clear
merge 1:1 ngram using ngrams_mentions
drop _merge
keep ngramid ngram mentions_bt
merge 1:1 ngram using ngrams_vintage
drop _merge
keep ngramid ngram mentions_bt vintage
merge 1:1 ngram using ngrams_top_new
drop _merge
keep ngramid ngram mentions_bt vintage top_*
replace top_001=0 if top_001==.
replace top_0001=0 if top_0001==.
sort ngram
compress
cd $outpath
save ngram_temp, replace

* Create the imported and cleaned files in increments of 50 underlying MEDLINE files.
local initialfiles 1 51 101 151 201 251 301 351 401 451 501 551 601 651 701
local terminalfile=746
local fileinc=49

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
	gen ngram=""
	cd $outpath\ImportandClean
	save importandclean_`startfile'_`endfile', replace

	set more off
	forvalues i=`startfile'/`endfile' {
	
		display in red "--------- File `i' ----------"

		cd $ngramfilepath
		use medline14_`i'_ngrams, clear
		drop if dim=="null"

		keep pmid version ngram source wordcount
		* Eliminate duplicate ngrams in the same title or abstract
		duplicates drop pmid version source ngram, force
	
		compress
		cd $outpath\ImportandClean
		append using importandclean_`startfile'_`endfile'
		save importandclean_`startfile'_`endfile', replace
	}
	
	* Attach date information
	cd $processed
	use medline14_dates_clean if filenum>=`startfile' & filenum<=`endfile', clear
	cd $outpath\ImportandClean
	merge 1:m pmid version using importandclean_`startfile'_`endfile'
	drop if _merge==1
	drop _merge
	keep filenum pmid version ngram source wordcount year
	
	* Attach n-gram level information
	cd $outpath
	merge m:1 ngram using ngram_temp
	drop if _merge==2
	drop _merge

	* Compute the age of each ngram
	gen age=year-vintage
	
	* Replace "abstract" and "title" to "a" and "t" to save space
	replace source="a" if source=="abstract"
	replace source="t" if source=="title"
	
	order filenum pmid version ngramid year source wordcount top_* mentions_bt vintage age
	keep filenum pmid version ngramid year source wordcount top_* mentions_bt vintage age
	sort pmid source vintage ngramid
	compress
	cd $outpath\ImportandClean
	save importandclean_`startfile'_`endfile', replace
}
*********************************************************************************


*************************************************************************************
*************************************************************************************
* Compute article-level mentions metrics. Specifically, compute the number of top concepts
*  each article uses.

clear
gen filenum=.
cd $outpath
save metrics_articlelevel_mentions, replace

local initialfiles 1 51 101 151 201 251 301 351 401 451 501 551 601 651 701
local terminalfile=746
local fileinc=49

clear
set more off
foreach h in `initialfiles' {

	local startfile=`h'
	local endfile=`startfile'+`fileinc'
	if (`endfile'>`terminalfile') {
		local endfile=`terminalfile'
	}
	
	cd $outpath\ImportandClean
	use importandclean_`startfile'_`endfile', clear
	* Compute the age and vintage metrics using the dofile metrics_articlelevel_ngramagevintage.do.
	cd $code
	do metrics_mentions_quick.do
	
	compress
	cd $outpath
	append using metrics_articlelevel_mentions
	sort filenum pmid version
	compress
	save metrics_articlelevel_mentions, replace
}
*************************************************************************************



*************************************************************************************
*************************************************************************************
clear
gen filenum=.
cd $outpath
save metrics_articlelevel_ngramagevintage, replace

local initialfiles 1 51 101 151 201 251 301 351 401 451 501 551 601 651 701
local terminalfile=746
local fileinc=49

clear
set more off
foreach h in `initialfiles' {

	local startfile=`h'
	local endfile=`startfile'+`fileinc'
	if (`endfile'>`terminalfile') {
		local endfile=`terminalfile'
	}
	
	cd $outpath\ImportandClean
	use importandclean_`startfile'_`endfile', clear
	* Compute the age and vintage metrics using the dofile metrics_articlelevel_ngramagevintage.do.
	cd $code
	do metrics_agevintage_quick.do
	
	compress
	cd $outpath
	append using metrics_articlelevel_ngramagevintage
	sort filenum pmid version
	compress
	save metrics_articlelevel_ngramagevintage, replace
}
*************************************************************************************


*************************************************************************************
*************************************************************************************
* Compute the forward dispersion (Herfindahls and MeSH counts) for each top n-gram.
*  This file will serve as an input for article-level dispersion metrics.
cd $code
do topngrams_fowarddispersion.do

cd $outpath
use ngramsmeshterms4digit_forwarddispersion, clear
rename meshcount_4digit meshcount_raw4
rename mesh_4digit_weight meshcount_frac4
by ngramid, sort: egen meshcount_raw_total4=total(meshcount_raw4)
by ngramid, sort: egen meshcount_frac_total4=total(meshcount_frac4)
gen herf_raw4=(meshcount_raw4/meshcount_raw_total4)^2
gen herf_frac4=(meshcount_frac4/meshcount_frac_total4)^2
drop meshcount_raw_total4 meshcount_frac_total4
collapse (sum) herf_* meshcount_*, by(ngramid)
tempfile hold
save `hold', replace

cd $outpath
use ngramsmeshtermsraw_forwarddispersion, clear
rename meshcount meshcount_raw
rename meshweight meshcount_frac
by ngramid, sort: egen meshcount_raw_total=total(meshcount_raw)
by ngramid, sort: egen meshcount_frac_total=total(meshcount_frac)
gen herf_raw=(meshcount_raw/meshcount_raw_total)^2
gen herf_frac=(meshcount_frac/meshcount_frac_total)^2
drop meshcount_raw_total meshcount_frac_total
collapse (sum) herf_* meshcount_*, by(ngramid)
merge 1:1 ngramid using `hold'
drop if _merge==1
drop _merge

sort ngramid
compress
cd $outpath
save ngrams_fowarddispersion, replace


clear
gen filenum=.
cd $outpath
save metrics_articlelevel_forwarddispersion, replace

local initialfiles 1 51 101 151 201 251 301 351 401 451 501 551 601 651 701
local terminalfile=746
local fileinc=49

clear
set more off
foreach h in `initialfiles' {

	local startfile=`h'
	local endfile=`startfile'+`fileinc'
	if (`endfile'>`terminalfile') {
		local endfile=`terminalfile'
	}
	
	cd $outpath\ImportandClean
	use importandclean_`startfile'_`endfile', clear
	
	cd $outpath
	merge m:1 ngramid using ngrams_fowarddispersion
	drop if _merge==2
	drop _merge
	drop herf_raw herf_frac meshcount_raw meshcount_frac

	* Compute the age and vintage metrics using the dofile metrics_articlelevel_ngramagevintage.do.
	cd $code
	do metrics_dispersion_quick.do
	
	compress
	cd $outpath
	append using metrics_articlelevel_forwarddispersion
	sort filenum pmid version
	compress
	save metrics_articlelevel_forwarddispersion, replace
}
*************************************************************************************


cd $outpath
use metrics_articlelevel_ngramagevintage, clear
merge 1:1 filenum pmid version year using metrics_articlelevel_mentions
drop _merge
merge 1:1 filenum pmid version year using metrics_articlelevel_forwarddispersion
drop _merge
sort filenum pmid version
compress
save metrics_articlelevel, replace
export delimited using "metrics_articlelevel", replace








