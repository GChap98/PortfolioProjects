Select *
FROM Covid_portfolio_project..covid_deaths$
Where continent is not null
order by 3, 4;

-- To check that the table was read in properly
--SELECT *
--FROM Covid_portfolio_project..covid_cvaccinations$
--ORDER BY 3,4;

-- Select data that we will be using
Select location, date, total_cases, new_cases, total_deaths, population
FROM Covid_portfolio_project..covid_deaths$
Where continent is not null
ORDER BY 1,2;

-- Looking at the total cases vs. total deaths
-- Shows the likelihood of dying from contracting covid in your country
Select location, date, total_cases, total_deaths, (Total_deaths/total_cases)*100 AS DeathPercentage 
FROM Covid_portfolio_project..covid_deaths$
WHERE location like '%states%'
ORDER BY 1,2;

-- Looking at the total cases vs Population
-- Shows percentage of population that got covid
Select location, date, total_cases, population, (total_cases/population)*100 AS PercentInfected
FROM Covid_portfolio_project..covid_deaths$
--WHERE location like '%Canada%'
ORDER BY 1,2;

-- What countries have the highest infection rates compared to population?
Select location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 AS PercentInfected
FROM Covid_portfolio_project..covid_deaths$
--WHERE location like '%Canada%'
GROUP BY location, population
ORDER BY PercentInfected DESC;

-- Showing the countries with the highest death count per population
Select location, MAX(CAST(total_deaths as int)) as TotalDeathCount, population, MAX((total_deaths/population))*100 AS PercentDied
FROM Covid_portfolio_project..covid_deaths$
--WHERE location like '%Canada%'
Where continent is not null
GROUP BY location, population
ORDER BY TotalDeathCount DESC, PercentDied DESC;


-- Breaking the data down by continent
-- Showing the countries with the highest death count per population
Select continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM Covid_portfolio_project..covid_deaths$
--WHERE location like '%Canada%'
Where continent is not null --AND location NOT IN ('Upper Middle Income' , 'High Income', 'Lower Middle Income' , 'European Union', 'Low Income', 'International')
GROUP BY continent
ORDER BY TotalDeathCount DESC;



-- Showing the continents with the highest death count
Select continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM Covid_portfolio_project..covid_deaths$
--WHERE location like '%Canada%'
Where continent is not null --AND location NOT IN ('Upper Middle Income' , 'High Income', 'Lower Middle Income' , 'European Union', 'Low Income', 'International')
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS

-- New cases and new deaths by date
Select date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths as INT)) AS TotalDeaths, NullIf(Sum(cast(new_deaths as INT)),0)/Nullif(SUM(new_cases),0) *100 as DeathPercentage
FROM Covid_portfolio_project..covid_deaths$
--WHERE location like '%Canada%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2;


-- Joining the two tables together
Select * 
FROM Covid_portfolio_project..covid_deaths$ dea
Join Covid_portfolio_project..covid_cvaccinations$ vac
	ON dea.location =vac.location 
	AND dea.date = vac.date;

-- Looking at total population vs. Vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (partition by dea.location Order By dea.location, dea.date) As RollingVaccinationCount
FROM Covid_portfolio_project..covid_deaths$ dea
Join Covid_portfolio_project..covid_cvaccinations$ vac
	ON dea.location =vac.location 
	AND dea.date = vac.date
Where dea.continent is not null
ORDER BY 2,3;

-- Creating a CTE
with PopvsVac (Continent, location, date, population, new_vaccinations, RollingVaccinationCount)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (partition by dea.location Order By dea.location, dea.date) As RollingVaccinationCount
FROM Covid_portfolio_project..covid_deaths$ dea
Join Covid_portfolio_project..covid_cvaccinations$ vac
	ON dea.location =vac.location 
	AND dea.date = vac.date
Where dea.continent is not null
--ORDER BY 2,3
)

Select *, (RollingVaccinationCount/population)*100 AS PercentPopVaccinated
From PopvsVac


--- TEMP TABLE

Drop Table if exists #PercentPopulationVaccinated

Create table #PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar (255),
date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeoplevaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (partition by dea.location Order By dea.location, dea.date) As RollingVaccinationCount
FROM Covid_portfolio_project..covid_deaths$ dea
Join Covid_portfolio_project..covid_cvaccinations$ vac
	ON dea.location =vac.location 
	AND dea.date = vac.date
Where dea.continent is not null
--ORDER BY 2,3

Select *
FROM #PercentPopulationVaccinated


--- Creating a view to store data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (partition by dea.location Order By dea.location, dea.date) As RollingVaccinationCount
FROM Covid_portfolio_project..covid_deaths$ dea
Join Covid_portfolio_project..covid_cvaccinations$ vac
	ON dea.location =vac.location 
	AND dea.date = vac.date
Where dea.continent is not null
--ORDER BY 2,3

Select *
From dbo.PercentPopulationVaccinated