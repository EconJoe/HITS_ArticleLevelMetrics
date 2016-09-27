
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
		keep filenum pmid version year ngramid vintage age top_*
		duplicates drop
		* These assignments ensure that the source and elim variables nevery match which means that the 
		*  hold variables (see below) will not be marked 0.
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
			* Set the hold varaible to missing if it is in the wrong source OR in the wrong percentile group.
			* Missing values are not included in the egen computations--this is what we want.
			replace hold=. if source=="`elim'" | top_`percentile'==0
			local moments `" "mean" "'
			foreach moment in `moments' {
				by pmid, sort: egen `metric'_`source'_`percentile'_`moment'=`moment'(hold)
			}
			drop hold
		}
	}
}

keep filenum pmid version year age_* vintage_*
duplicates drop
