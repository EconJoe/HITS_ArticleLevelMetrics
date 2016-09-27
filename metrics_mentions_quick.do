
local sources `" "both" "'
foreach source in `sources' {

	if ("`source'"=="title") { 
		local elim="abstract" 		
	}
	if ("`source'"=="abstract") { 
		local elim="title" 
	}
	if ("`source'"=="both") {
		keep filenum pmid version ngram year vintage top_*
		duplicates drop
		* These assignments ensure that the source and elim variables never match which means that the 
		*  hold variables (see below) will not be marked 0. This means that we will use concepts from both titles and abstracts.
		gen source="1"
		local elim="0"
	}
	
	local percentiles `" "001" "0001" "'
	foreach percentile in `percentiles' {
			
		* Compute mentions within *`i'* years of the vintage
		local vals 5
		foreach j in `vals' {
			gen hold=top_`percentile'
			* Mark the hold variable as missing if the article is beyond `j' years past vintage OR it is in the wrong source.
			replace hold=0 if year>vintage+`j' | source=="`elim'"
			by pmid version, sort: egen ment_`j'_`source'_`percentile'=total(hold)
			drop hold
		}
	}
}


keep filenum pmid version year ment_*
duplicates drop
