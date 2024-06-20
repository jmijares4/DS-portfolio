Select * From PortfolioDs..coviddeaths
Where continent is not null AND continent not like '' --In some cases continents appeared as countries, was because in some cases continent was null.
order by 3, 4										  --In some cases continents are just empty space.

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioDs..coviddeaths
Order by location, convert(date, date, 103) --Style 103 means dd/mm/yy
--

--Looking total cases vs total deaths
--Shows the likelihood to die if you got covid in Mexico.
Select location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/CONVERT(float, total_cases))*100 AS DeathPercentage
From PortfolioDs..coviddeaths
Where total_cases > 0 AND location like '%Mexico%' AND continent is not null AND continent not like ''
Order by convert(date, date, 103)
--

--Total cases vs population.
--Shows what percentage of population got Covid in Mexico.
Select location, date, total_cases, population, (total_cases/CONVERT(float, population))*100 AS InfectionPercentage
From PortfolioDs..coviddeaths
Where location like '%Mexico%' AND continent is not null AND continent not like ''
Order by convert(date, date, 103)
--

-- Looking at countries with highest infection rates cmopared to population.
Select location, population, MAX(total_cases) AS highestinfectioncount, MAX((CONVERT(float, total_cases)/CONVERT(float, population))*100) AS InfectionPercentage
From PortfolioDs..coviddeaths
--Where location like '%Mexico%'
Where continent is not null AND continent not like ''
--Order by convert(date, date, 103)
Group by location, population
Order by InfectionPercentage DESC
--

--Showing countries with highest death counts per population.
Select location, MAX(cast(total_deaths as int)) AS totaldeathcount
From PortfolioDs..coviddeaths
Where continent is not null AND continent not like ''
Group by location
Order by totaldeathcount DESC
--

--Breaking things out by continent.
--Continents with higher death counts by population.
Select continent, MAX(cast(total_deaths as int)) AS totaldeathcount
From PortfolioDs..coviddeaths
Where continent is not null and continent not like ''
Group by continent
Order by totaldeathcount DESC
--

--Global numbers:
--Lets make the percenage look better and easier to read.
Select sum(cast(new_cases as int)) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
cast(round(sum(CONVERT(float, new_deaths))/sum(CONVERT(float, new_cases))*100, 3) as varchar) + '%' AS total_DeathPercentage
From PortfolioDs..coviddeaths
--Where total_cases > 1 AND location like '%Mexico%'
Where continent is not null AND continent not like '' and new_cases > 0
--

--Looking the other table.
Select * from PortfolioDs..covidvacc

--Joining tables
Select *
from PortfolioDs..coviddeaths dea
join PortfolioDs..covidvacc vac
on dea.location = vac.location
and dea.date = vac.date
--

--Looking at total population vs vaccination
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, convert(date, dea.date, 103)) as total_vaccinations_by_date
--total vaccs by location added each time there is a vaccination. 
from PortfolioDs..coviddeaths as dea
full outer join PortfolioDs..covidvacc as vac --includes all rows
on dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null AND dea.continent not like ''
order by dea.location, convert(date, dea.date, 103)
--

--Using CTE
With PopvsVac (continent, location, date, population, new_vaccinations, total_vaccinations_by_date)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, convert(date, dea.date, 103)) as total_vaccinations_by_date
--total vaccs by location added each time there is a vaccination. 
from PortfolioDs..coviddeaths as dea
full outer join PortfolioDs..covidvacc as vac --includes all rows
on dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null AND dea.continent not like ''
--order by dea.location, convert(date, dea.date, 103)
)
Select *, cast((total_vaccinations_by_date/population)*100 as varchar) + ' %' AS VaccinationPercentage
From PopvsVac
--

--Creating a table
Drop table if exists #PercentPopulationVaccinated
--If we make mistakes, a table can be dropped then recreated, or if we are working with a temptable instead of CTE.
Create Table #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
total_vaccinations_by_date numeric)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, convert(date, dea.date, 103) as date, convert(int,dea.population) as population, convert(int, vac.new_vaccinations) as new_vaccinations,
sum(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, convert(date, dea.date, 103)) as total_vaccinations_by_date
--total vaccs by location added each time there is a vaccination. 
from PortfolioDs..coviddeaths as dea
full outer join PortfolioDs..covidvacc as vac --includes all rows
on dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null AND dea.continent not like ''

Select * from #PercentPopulationVaccinated
order by location, date


--Creating view to store data for later visualizations
Create view PercentPopulationVaccinated as (
Select dea.continent, dea.location, convert(date, dea.date, 103) as date, convert(int,dea.population) as population, convert(int, vac.new_vaccinations) as new_vaccinations,
sum(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, convert(date, dea.date, 103)) as total_vaccinations_by_date
--total vaccs by location added each time there is a vaccination. 
from PortfolioDs..coviddeaths as dea
full outer join PortfolioDs..covidvacc as vac --includes all rows
on dea.location = vac.location
and dea.date = vac.date
Where dea.continent is not null AND dea.continent not like '')

--This view can be used as a form of a more permanent table to work with
--Also can be used to conect to a BI software like Tableu or PowerBI
Select * from PercentPopulationVaccinated
