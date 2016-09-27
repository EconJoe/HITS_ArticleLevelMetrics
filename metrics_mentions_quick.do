
local sources `" "both" "'
foreach source in `sources' {

	if ("`source'"=="title") { 
		local elim="abstract" 		
	}
	if ("`source'"=="abstract") { 
		local elim="title" 
	}
	if ("`source'"=="both") {
		* Eliminate duplicates when the same n-gram is used in BOTH the title and the abstract. We we want unique n-grams used in EITHER the title or abstract.
		* Acheive this by eliminating the variable "source" and dropping duplicates within an aritcle.
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
			* Set the hold variable to 0 if the article is beyond `j' years past vintage OR it is in the wrong source.
			replace hold=0 if year>vintage+`j' | source=="`elim'"
			* Total the number of top n-grams within the article (conditional on years since vintage, source, and percentile).
			by pmid version, sort: egen ment_`j'_`source'_`percentile'=total(hold)
			drop hold
		}
	}
}

keep filenum pmid version year ment_*
duplicates drop
