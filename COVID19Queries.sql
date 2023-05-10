-- Examining Data To Use

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeathsNew
WHERE continent is not null
ORDER BY 1,2


-- Examining Total Cases vs Total Deaths

SELECT Location, date, total_cases, CAST(total_deaths as int), (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeathsNew
WHERE location like '%states%'
and continent is not null
ORDER BY 1,2


-- Examining Total Cases compared to Population

SELECT Location, date, population, total_cases, (total_cases/population)*100 as InfectionPercentage
FROM PortfolioProject..CovidDeathsNew
WHERE location like '%states%'
ORDER BY 1,2


-- Examining Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as CountryInfectionPercentage
FROM PortfolioProject..CovidDeathsNew
GROUP BY Location, Population
ORDER BY CountryInfectionPercentage DESC


-- Showing Deaths per Country

SELECT Location, MAX(cast(Total_Deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeathsNew
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC


-- Showing Deaths per Continent

SELECT continent, MAX(CAST(Total_Deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeathsNew
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Global COVID-19 Numbers

SELECT SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths,SUM(cast(new_deaths as int))/SUM(New_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeathsNew
WHERE continent is not null
ORDER BY 1,2


--Examining Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated 
FROM PortfolioProject..CovidDeathsNew dea
JOIN PortfolioProject..CovidVaccinationsNew vac
	ON dea.location = vac.location 
	and dea.date = vac.date
	WHERE dea.continent is not null
ORDER BY 2,3


-- Using a CTE 

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeathsNew dea
JOIN PortfolioProject..CovidVaccinationsNew vac
	ON dea.location = vac.location 
	and dea.date = vac.date
	WHERE dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- Using a Temp Table

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeathsNew dea
JOIN PortfolioProject..CovidVaccinationsNew vac
	ON dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


--Creating Views For Data Visualization

CREATE VIEW PercentPopVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeathsNew dea
JOIN PortfolioProject..CovidVaccinationsNew vac
	ON dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM PercentPopVaccinated


CREATE VIEW DeathsPerContinent as
SELECT continent, MAX(CAST(Total_Deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeathsNew
WHERE continent is not null
GROUP BY continent 
ORDER BY TotalDeathCount DESC OFFSET 0 ROWS

SELECT *
FROM DeathsPerContinent


Create View DeathsPerCountry as
SELECT Location, MAX(cast(Total_Deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeathsNew
WHERE continent is not null
GROUP BY Location
ORDER BY DeathsPerCountry DESC OFFSET 0 ROWS

SELECT *
FROM DeathsPerCountry


--Queries used for Tableau Public 

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeathsNew
where continent is not null 
order by 1,2


SELECT location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeathsNew
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc


SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeathsNew
Group by Location, Population
order by PercentPopulationInfected desc


SELECT Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeathsNew
Group by Location, Population, date
order by PercentPopulationInfected desc

--This query examines Percent of Population Vaccinated. Each booster was counted as a seperate vaccine, so the data is skewed and shows an impossibly inflated Percent of Population Vaccinated. Thus, this query was not used for a visualization.
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeathsNew dea
Join PortfolioProject..CovidVaccinationsNew vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac
