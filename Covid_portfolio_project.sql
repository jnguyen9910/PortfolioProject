--SELECT *
--FROM PortfolioProject..Covid_Deaths cd
--ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..Covid_Vaccinations cv
--ORDER BY 3,4


-- Selecting data that we'll be using
SELECT location
	,date
	,total_cases
	,new_cases
	,total_deaths
	,population
FROM PortfolioProject..Covid_Deaths cd
ORDER BY 1,2


-- Looking at total cases vs total deaths; shows likelihood of death if contracting Covid in your country
SELECT location
	,date
	,total_cases
	,total_deaths
	,(total_deaths/total_cases)*100 AS mortality_rate
FROM PortfolioProject..Covid_Deaths cd
WHERE location like '%states%'
ORDER BY 1,2


-- Looking at total cases vs population; shows percentage of population that contracted Covid
SELECT location
	,date
	,population
	,total_cases
	,(total_cases/population)*100 AS infection_rate
FROM PortfolioProject..Covid_Deaths cd
WHERE location like '%states%'
ORDER BY 1,2


-- Looking at countries with the highest infection rate compared to population
SELECT location
	,population
	,MAX(total_cases) AS max_cases
	,MAX((total_cases/population*100)) AS percent_pop_infected
FROM PortfolioProject..Covid_Deaths cd
GROUP BY location, population
ORDER BY 4 desc


-- Showing the highest death count per country
-- cast was used because data type isn't integer; where clause was used because location in dataset aren't all countries
SELECT location
	,MAX(cast(total_deaths as int)) AS total_deathcount
FROM PortfolioProject..Covid_Deaths cd
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 desc


-- Showing death count per continent
SELECT location
	,MAX(cast(total_deaths as int)) AS total_deathcount
FROM PortfolioProject..Covid_Deaths cd
WHERE location IN ('World','Europe','North America','Asia','South America','European Union','Africa','Oceania')
GROUP BY location
ORDER BY 2 desc


-- Due to how the dataset was put together, this query results in inaccurate numbers, but this allows us to break it down to countries for the visualization
SELECT continent
	,MAX(cast(total_deaths as int)) AS total_deathcount
FROM PortfolioProject..Covid_Deaths cd
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 desc


-- Global numbers per date
SELECT date
	,SUM(new_cases) AS total_cases
	,SUM(cast(new_deaths as int)) AS total_deaths
	,SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS mortality_rate
FROM PortfolioProject..Covid_Deaths cd
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2



-- Joining covid vaccination and covid death tables together
SELECT *
FROM PortfolioProject..Covid_Deaths cd
	,PortfolioProject..Covid_Vaccinations cv
WHERE cv.date = cd.date
	AND cv.location = cd.location


-- Looking at total population vs vaccinations
SELECT cd.continent
	,cd.location
	,cd.date
	,cd.population
	,cv.new_vaccinations
FROM PortfolioProject..Covid_Deaths cd
	,PortfolioProject..Covid_Vaccinations cv
WHERE cv.date = cd.date
	AND cv.location = cd.location
	AND cd.continent IS NOT NULL
ORDER BY 1,2,3


-- Showing new vaccinations vs total vaccinations per country
SELECT cd.continent
	,cd.location
	,cd.date
	,cd.population
	,cv.new_vaccinations
	,SUM(convert(bigint,cv.new_vaccinations)) OVER (partition by cd.location order by cd.location, cd.date) AS rolling_total_vac
FROM PortfolioProject..Covid_Deaths cd
	,PortfolioProject..Covid_Vaccinations cv
WHERE cv.date = cd.date
	AND cv.location = cd.location
	AND cd.continent IS NOT NULL
ORDER BY 2,3


-- CTE; showing percentage of population vaccinated by date
WITH pop_vac (
	continent
	,location
	,date
	,population
	,new_vaccinations
	,rolling_total_vac
	)
	AS (
		SELECT cd.continent
			,cd.location
			,cd.date
			,cd.population
			,cv.new_vaccinations
			,SUM(convert(bigint,cv.new_vaccinations)) OVER (partition by cd.location order by cd.location, cd.date) AS rolling_total_vac
		FROM PortfolioProject..Covid_Deaths cd
			,PortfolioProject..Covid_Vaccinations cv
		WHERE cv.date = cd.date
			AND cv.location = cd.location
			AND cd.continent IS NOT NULL
			)
SELECT *
	,(rolling_total_vac/population)*100 as pop_vaccinated
FROM pop_vac


-- Same as above but with a temp table
--DROP TABLE IF EXISTS #pop_vaccinated
CREATE TABLE #pop_vaccinated
	(
	continent nvarchar(255)
	,location nvarchar(255)
	,date datetime
	,population numeric
	,new_vaccinations numeric
	,rolling_total_vac numeric
	)

INSERT INTO #pop_vaccinated
SELECT cd.continent
	,cd.location
	,cd.date
	,cd.population
	,cv.new_vaccinations
	,SUM(convert(bigint,cv.new_vaccinations)) OVER (partition by cd.location order by cd.location, cd.date) AS rolling_total_vac
FROM PortfolioProject..Covid_Deaths cd
	,PortfolioProject..Covid_Vaccinations cv
WHERE cv.date = cd.date
	AND cv.location = cd.location
--	AND cd.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
	,(rolling_total_vac/population)*100 as pop_vaccinated
FROM #pop_vaccinated


-- Creating view to store data for visualizations later
Use PortfolioProject
Go

CREATE VIEW percentPop_vaccinated AS
SELECT cd.continent
	,cd.location
	,cd.date
	,cd.population
	,cv.new_vaccinations
	,SUM(convert(bigint,cv.new_vaccinations)) OVER (partition by cd.location order by cd.location, cd.date) AS rolling_total_vac
FROM PortfolioProject..Covid_Deaths cd
	,PortfolioProject..Covid_Vaccinations cv
WHERE cv.date = cd.date
	AND cv.location = cd.location
	AND cd.continent IS NOT NULL