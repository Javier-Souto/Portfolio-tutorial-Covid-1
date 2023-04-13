-- First of all I will take off the NULL data --

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float)) AS PercentageDeaths
FROM CovidDeaths
WHERE total_cases != '' AND total_deaths != '' and continent is not null

-- Now I will convert the numbers in decimals --

SELECT location, date, total_cases, total_deaths, 
       CAST(total_deaths AS decimal)/CAST(total_cases AS decimal)*100 AS PercentageDeaths
FROM CovidDeaths
WHERE total_cases != '' AND total_deaths != '' 

-- Now we are checking the possibily of dying in USA --

SELECT location, date, total_cases, total_deaths, 
       CAST(total_deaths AS decimal)/CAST(total_cases AS decimal)*100 AS PercentageDeaths
FROM CovidDeaths
WHERE total_cases != '' AND total_deaths != '' and location like '%states%'

-- Looking at total cases vs population
-- Show what percentage of population got covid

SELECT location, date, population, total_cases, 
       CAST(total_cases AS decimal)/CAST(population AS decimal)*100 AS PercentageCases
FROM CovidDeaths
WHERE total_cases != '' AND population != '' and location like '%states%'

-- Now we want to see which country has a higher infection rate

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
       Max(CAST(total_cases AS decimal)/CAST(population AS decimal))*100 AS PercentageCases
FROM CovidDeaths
WHERE total_cases != '' AND population != ''
group by population, location
order by PercentageCases DESC

-- Showing Countries with highest death count per population

SELECT location, MAX(cast(total_deaths as float)) AS HighestDeathCount 
from CovidDeaths
WHERE continent is not null
group by location
order by HighestDeathCount DESC

-- Let's break things down by continent

SELECT continent, MAX(cast(total_deaths as float)) AS HighestDeathCount 
from CovidDeaths
WHERE continent is not null
group by continent
order by HighestDeathCount DESC

-- Global numbers --
SELECT  sum(cast(new_cases as float)) as total_cases, SUM(cast(new_deaths as float)) as total_deaths,
       SUM(CAST(new_cases as float))/SUM(CAST(New_cases as float))*100 AS PercentageDeaths
FROM CovidDeaths
WHERE total_cases != '' AND total_deaths != '' and continent is not null
order by 1, 2


-- Looking at total population vs new deaths

select dea.continent, dea.location, dea.date, dea.population, dea.new_deaths
, SUM(cast(dea.new_deaths as float)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleDeaths
, -- 
from [Portfolio Project 1].dbo.CovidDeaths dea
join [Portfolio Project 1].dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
order by  2,3

-- USE CTE

with PopvsDeat (continent, location, date, population, new_deaths, RollingPeopleDeaths)
as
(
select dea.continent, dea.location, dea.date, dea.population, dea.new_deaths
, SUM(cast(dea.new_deaths as float)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleDeaths
 --, (RollingPeopleDeath/population)*100
from [Portfolio Project 1].dbo.CovidDeaths dea
join [Portfolio Project 1].dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
Select *, (RollingPeopleDeaths/population)*100 as Death_per_Population
from PopvsDeat

-- Temp Table

drop table if exists #PercentPopulationDeath
Create Table #PercentPopulationDeath
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
PopulationDeath numeric,
RollingPeopleDeath numeric
)

Insert into #PercentPopulationDeath
select dea.continent, dea.location, dea.date, dea.population, dea.new_deaths,
       SUM(cast(case when isnumeric(dea.new_deaths) = 1 then dea.new_deaths else null end as float))
           over (partition by dea.location order by dea.location, dea.date) as RollingPeopleDeaths
from [Portfolio Project 1].dbo.CovidDeaths dea
join [Portfolio Project 1].dbo.CovidVaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null and isnumeric(dea.new_deaths) = 1

Select *, (RollingPeopleDeath/population)*100 as Death_per_Population
from #PercentPopulationDeath

-- Creating view to store data for later visualization

Create view  PercentPopulationDeath as
select dea.continent, dea.location, dea.date, dea.population, dea.new_deaths,
       SUM(cast(case when isnumeric(dea.new_deaths) = 1 then dea.new_deaths else null end as float))
           over (partition by dea.location order by dea.location, dea.date) as RollingPeopleDeaths
from [Portfolio Project 1].dbo.CovidDeaths dea
join [Portfolio Project 1].dbo.CovidVaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null and isnumeric(dea.new_deaths) = 1


Select *
from PercentPopulationDeath
