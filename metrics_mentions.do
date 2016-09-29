
local sources `" "title" "abstract" "both" "'
foreach source in `sources' {

	if ("`source'"=="title") { 
		local elim="abstract" 		
	}
	if ("`source'"=="abstract") { 
		local elim="title" 
	}
	if ("`source'"=="both") {
		keep filenum pmid ngram year version vintage ment_* wordcount_* top_*
		duplicates drop
		* These assignments ensure that the source and elim variables nevery match which means that the 
		*  hold variables (see below) will not be marked 0.
		gen source="1"
		local elim="0"
	}
	
	local percentiles `" "001" "0001" "'
	foreach percentile in `percentiles' {
			
		* Compute mentions within *`i'* years of the vintage
		local vals 0 3 5 10
		foreach j in `vals' {
			gen hold=top_`percentile'
			* Mark the hold variable as missing if the article is beyond `j' years past vintage OR it is in the wrong source.
			replace hold=0 if pubyear>vintage+`j' | source=="`elim'"
			by pmid version, sort: egen ment_`j'_`source'_`percentile'=total(hold)
			drop hold
		}
		*************
		* Compute mentions from *all* vintages
		gen hold=top_`percentile'
		replace hold=0 if source=="`elim'"
		by pmid version, sort: egen ment_all_`source'_`percentile'=total(hold)
		drop hold
		*************
	}
	
	* Compute word counts.
	* Note that the tempfiles have been constructed so that each observation is uniquely identified by a PMID, NGRAMID, and source.
	gen hold=1
	* Mark the hold variable as missing if the article is in the wrong source.
	replace hold=0 if source=="`elim'"
	by pmid version, sort: egen wordcount_`source'=total(hold)
	drop hold
}

keep filenum pmid year version ment_* wordcount_*
duplicates drop
