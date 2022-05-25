--COVID Project related to two tables: one being covid deaths and the other one covid vaccinations

USE PortfolioProjectCovid

-- Taking a look at data
SELECT TOP 10 *
FROM PortfolioProjectCovid..covid_deaths
ORDER BY 3,4

SELECT TOP 10 *
FROM PortfolioProjectCovid..covid_vaccinations
ORDER BY 3, 4


/*Selecting data: Local, data, total cases, total new cases, 
	total deaths and population
*/

SELECT location, date, population, new_cases, total_cases, total_deaths
FROM PortfolioProjectCovid..covid_deaths
ORDER BY 1,2

--Total of cases x total of deaths
--Shows the death rate in percentage of X country. X being the location in the where clause
SELECT location, date, total_cases, total_deaths, CAST(total_deaths / total_cases AS float(1)) * 100 as "death_percentage"
FROM PortfolioProjectCovid..covid_deaths
WHERE location LIKE 'Brazil'
ORDER BY 2

--Total of cases x population
--Percentage of population that had covid in X country. X being the location in the where clause
SELECT location, date, population, total_cases, (total_cases / population) * 100 as "cases_percentage"
FROM PortfolioProjectCovid..covid_deaths
WHERE location LIKE 'Brazil'
ORDER BY 2

--Countries with the highest infection count per population
SELECT location, population, MAX(total_cases)"highest_infection_count", MAX((total_cases / population)) * 100 as "infections_percentage"
FROM PortfolioProjectCovid..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 3 DESC

--Countries with the highest death count per population

SELECT continent, location, population, MAX(CAST(total_deaths as int)) as "highest_death_count", MAX((total_deaths / population)) * 100 as "deaths_percentage"
FROM PortfolioProjectCovid..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY 4 DESC

--Continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths as int)) as "highest_death_count"
FROM PortfolioProjectCovid..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS INT)) as "new_deaths", SUM(CAST(new_deaths AS INT)) / SUM(new_cases) as "death_percentage"
FROM PortfolioProjectCovid..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date ASC


------------------------------------------------------------------------------------
--Looking at total population x vaccinations

SELECT  dea.continent, dea.location, dea.date, vac.new_vaccinations,
			SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
			OVER (PARTITION BY dea.location 
			ORDER BY dea.location, dea.date
			ROWS UNBOUNDED PRECEDING)
--ROWS UNBOUNDED PRECENDING is used because the sum function wouldn't work without it because of a 900 byte limit of the window
FROM PortfolioProjectCovid..covid_vaccinations vac
JOIN PortfolioProjectCovid..covid_deaths dea
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date


--CTE

WITH PopxVac(continent, location, date, population, new_vaccinations, people_vaccinated)
AS
(
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
			OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS people_vaccinated
FROM PortfolioProjectCovid..covid_vaccinations vac
JOIN PortfolioProjectCovid..covid_deaths dea
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (people_vaccinated / population) * 100
FROM PopxVac

--TEMP TABLE
--CHECKING THE TEMP TABLE'S ID
SELECT OBJECT_ID('tempdb..#PercentagePeopleVaccinated')
--IN CASE THE TABLE ALREADY EXISTS WE USE THIS IF STATEMENT TO DELETE IT
IF OBJECT_ID('tempdb..#PercentagePeopleVaccinated') IS NOT NULL
    DROP TABLE dbo.#PercentagePeopleVaccinated;
GO

CREATE TABLE #PercentagePeopleVaccinated
(
	Continent NVARCHAR(255),
	Location NVARCHAR(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	people_vaccinated numeric
)

INSERT INTO #PercentagePeopleVaccinated
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
			OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS people_vaccinated
FROM PortfolioProjectCovid..covid_vaccinations vac
JOIN PortfolioProjectCovid..covid_deaths dea
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL

SELECT *, (people_vaccinated / population) * 100
FROM #PercentagePeopleVaccinated


CREATE VIEW PercentagePeopleVaccinated 
AS
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
			OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS 'people_vaccinated'
FROM PortfolioProjectCovid..covid_vaccinations vac
JOIN PortfolioProjectCovid..covid_deaths dea
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL

SELECT * FROM PercentagePeopleVaccinated
