libname nyc "C:\Users\rdoyen\Desktop\BusinessReportingTools-master\Group_assignment";
run;

/**************************************************************************
* MAKE ALL THE NEGATIVE DELAYS IN THE FLIGHT DATASET AS 0                 *                         
**************************************************************************/  

PROC SQL;
	create table nyc.Flights as
		select year,month,day,dep_time,sched_dep_time, 
          arr_time,sched_arr_time,
		  arr_delay, CASE when arr_delay <=0 then 0 else arr_delay END as arr_delay1,
		  carrier,flight,tailnum,origin,dest,air_time,distance,hour,minute,time_hour,
          dep_delay, CASE when dep_delay <=0 then 0 else dep_delay END as dep_delay1
		 from nyc.Flights ;	
QUIT;

/**************************************************************************
* ALTER FLIGHTS TABLE                                                     *                         
**************************************************************************/  

data nyc.flights(rename=(date=departure_Date));
set nyc.flights;
date= mdy(month,day,year);
format date date10.;
sched_dep_time=input(cats(sched_dep_time,"00"),hhmmss.);
sched_arr_time=input(cats(sched_arr_time,"00"),hhmmss.);
hour=input(cats(hour,"00"),hhmmss.);
format sched_dep_time time5.;
format sched_arr_time time5.;
format hour time5.;
run; 

/**************************************************************************
 *  LEFT JOIN ON FLIGHTS AND AIRLINES                              *                         
**************************************************************************/
/* drop var1 */
proc sql;
alter table nyc.airlines drop VAR1;
run;

proc sql;
Create table nyc.flights as
select *,sum(arr_delay1,dep_delay1) as total_delay from nyc.flights a left join nyc.airlines b
on a.carrier=b.carrier;
run; 

/**************************************************************************
 *  LEFT JOIN ON FLIGHTS AND WEATHER DATASETS                              *                         
 **************************************************************************/

PROC SQL;
   create table nyc.flights_weather AS 
   SELECT * from nyc.Flights a
   left join nyc.weather b ON (a.origin = b.origin) AND (a.time_hour = b.time_hour);                
QUIT;

/**************************************************************************
* ALTER FLIGHTS-WEATHER DATASET                                                   *                         
**************************************************************************/  
/* create a new variable time_of_the_day */
PROC SQL;
   create table nyc.flights_weather as
   select *, 
   (CASE when hour(sched_dep_time) >=  12 and hour(sched_dep_time) <  17 then "Afternoon"
         when hour(sched_dep_time) >=  17 and hour(sched_dep_time) <=  22 then "Evening"
         when hour(sched_dep_time) >= 6 and hour(sched_dep_time) <  12 then "Morning"      
         else "Night"      
    END) as time_of_the_day        
    from nyc.flights_weather ;                      
QUIT;

/* create a new variable season */
PROC SQL;
create table nyc.flights_weather as
select *,
(CASE when month  >= 3 and  month  <= 5 then "Spring"
      when month  >= 6 and  month  <= 8 then "Summer"
      when month  >= 9  and  month  <= 11 then "Autumn"
      else "Winter" 
 END) AS Season             
 from nyc.flights_weather;              
 QUIT;                 
 
/**************************************************************************
* ALTER AIRPORT TABLE                                                    *                         
**************************************************************************/

proc sql;
alter table nyc.airports drop VAR1,alt,tz,dst,tzone;
run;

Data nyc.airports(rename=(name=Airport_Name)
				  keep= faa name lat lon);
set nyc.airports;

/**************************************************************************
 *  LEFT JOIN ON FLIGHTS AND AIRPORT DATSETS                              *                         
 **************************************************************************/

/* left join flights and airport with origin */
proc sql;
create table nyc.flights_airport_origin as
select *
from nyc.flights b left join nyc.airports a
on b.origin=a.faa;
run;

/* left join flights and airport with destination */
proc sql;
create table nyc.flights_airport_destination as
select *
from nyc.flights b
left join nyc.airports a
on b.dest=a.faa;
run;


/*****************************************************************************
 *  UNION FLIGHT_AIRPORTS_ORIGIN AND FLIGHT_AIRPORTS_DESTINATION             *
 *  TO CREATE SPIDER CHART IN TABLEAU                                        *
 *****************************************************************************/
proc sql;
create table nyc.flights_airport_both as
select "origin" as route_identifier,*
from nyc.flights_airport_origin
union all
select "dest",* 
from nyc.flights_airport_destination;
run; 
           
/*****************************************************************************
 *  CREATE A TABLE TO WORK WITH MANUFACTURER AND THE WEATHER
 *                                         *
 *****************************************************************************/       

PROC SQL;
	CREATE TABLE nyc.PlanesOK as
	SELECT tailnum, year as yearConstruction, manufacturer, model, engines, engine
	FROM nyc.planes;quit;

PROC SQL;
CREATE TABLE nyc.FlightPlane AS
	SELECT * 
	FROM nyc.Flights t1, nyc.planesok t2
	where t1.tailnum = t2.tailnum;quit;


 PROC SQL;
	CREATE TABLE nyc.Flight_Weather2 AS
		SELECT *  from nyc.flightplane a
   		LEFT JOIN nyc.weather b ON (a.origin = b.origin) AND (a.time_hour = b.time_hour);quit;

PROC SQL;
	CREATE TABLE nyc.flightpermonth AS
	SELECT count(flight) as Count_Flight, month, origin, AVG(arr_delay1) as AVG_Arr_delay
	FROM nyc.flights
	GROUP BY 2,3;quit;
