*set working directory
cd \\tsclient\val\Documents\Stata\hpi

*create log file
log using hpi.log, replace

*set manual scrolling off
set more off

*import csv file and generate dta file
import delimited hpi, clear
save hpi.dta, replace

*inspect dataset
sum

*organize the dataset
sort countrycode time
order countrycode, first

*1. Generate logarithms for each of the three series of the file:
*define varlist as all variables starting with hpi
*loop over varlist and compute the logarithms for each variable
ds hpi*
foreach var of varlist `r(varlist)' {
    gen ln_`var' = ln(`var')
}

*2. Generate 5-year period averages for each of the three series in the file:
*generate variable for 5-year periods
bysort countrycode (time) : gen period = ceil(_n/5)

*define varlist as all variables starting with hpi
*loop over varlist and compute averages for every period for hpi
ds hpi*
foreach var of varlist `r(varlist)' {
	bysort countrycode period: egen `var'_mean = mean(`var')
}
 
*3. Generate the average annual growth rate for the whole period under scrutiny for each of the three series in the file:
* generate variable to indicate the position of the observation
bysort countrycode (time) : gen time_order = (_n)
 
*define varlist as all variables starting with ln_hpi
*loop over varlist, sort by country and time and compute the avg annual growth rate for each variable.
*define the first and last occurrence
*calculate growth rate if there are more than the average (>10) number of observations.
ds ln_hpi*
foreach var of varlist `r(varlist)'  {
by countrycode, sort: egen `var'_firstnonmissing = min(cond(!missing( `var' ), time_order, .))
by countrycode, sort: egen `var'_lastnonmissing = max(cond(!missing( `var' ),  time_order, .))
by countrycode : gen `var'_n_periods = `var'_lastnonmissing - `var'_firstnonmissing
by countrycode : gen `var'_g_rate = (`var'[ `var'_lastnonmissing] - `var'[ `var'_firstnonmissing])/ `var'_n_periods if `var'_n_periods > 10 
}

*4. Generate the average annual growth rate for every 5-year period for each of the three series of the file:
*define varlist as all variables starting with ln_hpi
*loop over varlist, sort by country and period and compute the avg period growth rate for each variable.
* define the first and last occurrence for each period
* calculate growth rate if there are more than the average (>2) number of observations.
ds ln_hpi?
foreach var of varlist `r(varlist)'  {
by countrycode period, sort: egen `var'_firstp = min(cond(!missing( `var' ), time_order, .))
by countrycode period, sort: egen `var'_lastp = max(cond(!missing( `var' ),  time_order, .))
by countrycode period : gen `var'_n_periodsp = `var'_lastp - `var'_firstp
by countrycode (period) : gen `var'_g_ratep = (`var'[ `var'_lastp] - `var'[ `var'_firstp])/ `var'_n_periodsp if `var'_n_periodsp > 2 
}
*drop any irrelevant variables generated for computation
keep time country* period hpi* ln_hpi1-ln_hpi3 *g_rate*

*order final dataset
order time period countryname countrycode, first
order hpi1_mean hpi2_mean hpi3_mean, after(hpi3)

*inspect final dataset
sum

*save 
save hpi_new.dta, replace
