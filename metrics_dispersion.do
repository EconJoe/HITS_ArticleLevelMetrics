
* This renaming is just to get around variable name length restrictions.
replace source="abs" if source=="abstract"
local sources `" "title" "abs" "both" "'
foreach source in `sources' {

	if ("`source'"=="title") { 
		local elim="abstract" 
	}
	if ("`source'"=="abstract") { 
		local elim="title" 
	}
	if ("`source'"=="both") {
		keep filenum pmid version year ngramid vintage age top_* herf_* meshcount_*
		duplicates drop
		* These assignments ensure that the source and elim variables nevery match which means that the 
		*  hold variables (see below) will not be marked 0.
		gen source="1"
		local elim="0"
	}
		
	local metrics `" "herf" "meshcount" "'
	foreach metric in `metrics' {
	
		local percentiles `" "001" "0001" "'
		foreach percentile in `percentiles' {
		
			local vals 0 3 5 10 20
			foreach val in `vals' {

				* By setting the hold variable equal to empty (hold==.), the empty variables will not be included
				*   in the egen calculations.
				gen hold=`metric'_`val'
				replace hold=. if source=="`elim'" | top_`percentile'==0
				local moments `" "min" "max" "mean" "median" "'
				foreach moment in `moments' {
					by pmid version, sort: egen `metric'_`val'_`source'_`percentile'_`moment'=`moment'(hold)
				}
				drop hold
			}
		}
	}
}

keep filenum pmid version year herf_* meshcount_*
drop herf_0 herf_3 herf_5 herf_10 herf_20 meshcount_0 meshcount_3 meshcount_5 meshcount_10 meshcount_20
duplicates drop
