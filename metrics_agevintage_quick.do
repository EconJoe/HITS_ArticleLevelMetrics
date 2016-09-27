
gen top_all=1
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
		keep filenum pmid version year ngramid vintage age top_*
		duplicates drop
		* These assignments ensure that the source and elim variables never match which means that the 
		*  hold variables (see below) will not be marked 0. This means that we will use concepts from both titles and abstracts.
		gen source="1"
		local elim="0"
	}
		
	local metrics `" "age" "vintage" "'
	foreach metric in `metrics' {
	
		local percentiles `" "all" "001" "0001" "'
		foreach percentile in `percentiles' {

			* By setting the hold variable equal to empty (hold==.), the empty variables will not be included
			*   in the egen calculations.
			gen hold=`metric'
			* Set the hold varaible to MISSING if it is in the wrong source OR in the wrong percentile group.
			* Missing values are not included in the egen computations--this is what we want.
			replace hold=. if source=="`elim'" | top_`percentile'==0
			local moments `" "mean" "'
			foreach moment in `moments' {
				* Compute the moment of the distribution of the age/vintage of concepts within an article (conditional on source and percentile).
				by pmid, sort: egen `metric'_`source'_`percentile'_`moment'=`moment'(hold)
			}
			drop hold
		}
	}
}

keep filenum pmid version year age_* vintage_*
duplicates drop
