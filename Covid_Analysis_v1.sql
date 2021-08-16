-- 1. Create Database
DROP DATABASE IF EXISTS covid_project;

CREATE DATABASE covid_project;

USE covid_project;

-- 2. Create tables and insert data into table
-- 2.1 Table: covid_vaccination
DROP TABLE IF EXISTS covid_vaccination;

CREATE TABLE covid_vaccination
	(iso_code VARCHAR(255) NOT NULL,
    continent VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    date DATE NOT NULL, 
    new_tests INT,
    total_tests	INT,
    total_tests_per_thousand FLOAT,
	new_tests_per_thousand FLOAT,
	new_tests_smoothed INT,
    new_tests_smoothed_per_thousand	FLOAT,
    positive_rate FLOAT,
    tests_per_case FLOAT,
    tests_units VARCHAR(255),
	total_vaccinations INT,
    people_vaccinated INT,
    people_fully_vaccinated	INT,
    new_vaccinations INT,
    new_vaccinations_smoothed INT,
    total_vaccinations_per_hundred FLOAT,
    people_vaccinated_per_hundred FLOAT,
    people_fully_vaccinated_per_hundred	FLOAT,
    new_vaccinations_smoothed_per_million FLOAT,
    stringency_index FLOAT,
    population_density FLOAT,
    median_age FLOAT,
    aged_65_older FLOAT,
    aged_70_older FLOAT,
    gdp_per_capita FLOAT,
    extreme_poverty FLOAT,
    cardiovasc_death_rate FLOAT,
    diabetes_prevalence FLOAT,
    female_smokers FLOAT,
    male_smokers FLOAT,
    handwashing_facilities FLOAT,
    hospital_beds_per_thousand FLOAT,
    life_expectancy FLOAT,
    human_development_index FLOAT,
    excess_mortality FLOAT
    );
    
LOAD DATA INFILE 'D:/Project/CovidVaccination.csv'
INTO TABLE covid_vaccination
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 2.2 Table: covid_deaths
DROP TABLE IF EXISTS covid_deaths;
CREATE TABLE covid_deaths
	(iso_code VARCHAR(255) NOT NULL,
    continent VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    date DATE NOT NULL , 
	population INT, 
    total_cases	INT,
    new_cases INT,
    new_cases_smoothed FLOAT,	
    total_deaths INT,	
    new_deaths INT,
    new_deaths_smoothed FLOAT,	
    total_cases_per_million	FLOAT,
    new_cases_per_million FLOAT,
    new_cases_smoothed_per_million FLOAT,	
    total_deaths_per_million FLOAT,
    new_deaths_per_million FLOAT,
    new_deaths_smoothed_per_million FLOAT,	
    reproduction_rate FLOAT,
    icu_patients INT,
    icu_patients_per_million FLOAT,	
    hosp_patients INT,
    hosp_patients_per_million FLOAT,
    weekly_icu_admissions INT,
    weekly_icu_admissions_per_million FLOAT,	
    weekly_hosp_admissions INT,
    weekly_hosp_admissions_per_million FLOAT
);
    
LOAD DATA INFILE 'D:/Project/CovidDeaths.csv'
INTO TABLE covid_deaths
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 2.3 Double-check 2 tables
SELECT * FROM covid_deaths;
SELECT * FROM covid_vaccination;
-- 3. Query to find the insights
-- 3.1 Looking at Total Cases vs Total Deaths 
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE continent NOT LIKE "" 
ORDER BY 1,2;

-- 3.2 Looking at Total Cases vs Population
SELECT location, date, total_cases, population, (total_cases / population )*100 AS InfectionPercentage
FROM covid_deaths
WHERE continent NOT LIKE "" 
ORDER BY 1,3;
  
-- 3.3 Looking at Countries with Highest Infection Rate compared to Population  
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases / population )*100 AS PercentPopulationInfected
FROM covid_deaths
WHERE continent NOT LIKE ""
GROUP BY location, population
ORDER BY HighestInfectionCount DESC;

-- 3.4 Looking at countries with Highest Death Count per Population
SELECT location, population,  MAX(CAST(total_deaths AS UNSIGNED)) AS HighestDeathCount, MAX(total_cases) AS total_cases, (MAX(total_deaths) / MAX(total_cases))*100 AS PercentPopulationDeath
FROM covid_deaths
WHERE continent NOT LIKE ""
GROUP BY location, population
ORDER BY HighestDeathCount DESC;

-- 3.5 Looking at continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS UNSIGNED)) AS HighestDeathCount, MAX(total_cases) AS total_cases, (MAX(total_deaths) / MAX(total_cases))*100 AS PercentPopulationDeath
FROM covid_deaths
WHERE continent NOT LIKE ""
GROUP BY continent
ORDER BY HighestDeathCount DESC;

-- 3.6 Global numbers 
SELECT date, SUM(new_cases) AS DailyNewCase, SUM(new_deaths) AS DailyNewDeath FROM covid_deaths
WHERE continent NOT LIKE ""
GROUP BY date;

-- 3.7 Looking at Population and Vaccination Information
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations AS DailyNewVaccine,
SUM(cv.new_vaccinations) OVER (partition by location ORDER BY cd.location, cd.date) AS TotalVaccineProvided
FROM covid_deaths AS cd
JOIN covid_vaccination AS cv 
	ON cd.location = cv.location
    and cd.date = cv.date
WHERE cd.continent NOT LIKE ""
GROUP BY cd.continent, cd.location, cd.population, cd.date;

-- 3.8 USE CTE to find Percentage of vaccinated people

With PopVsVac 
AS 
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations AS DailyNewVaccine,
SUM(cv.new_vaccinations) OVER (partition by location ORDER BY cd.location, cd.date) AS TotalVaccineProvided
FROM covid_deaths AS cd
JOIN covid_vaccination AS cv 
	ON cd.location = cv.location
    and cd.date = cv.date
WHERE cd.continent NOT LIKE ""
GROUP BY cd.continent, cd.location, cd.population, cd.date
ORDER by cd.Location, cd.date
)
SELECT *, (TotalVaccineProvided/Population)*100 AS PercentVaccineProvided
FROM PopVsVac AS PV;

-- 3.9 Looking at number of vaccinated people vs number of provided vaccines 
Select date,location, cv.people_vaccinated, cv.people_fully_vaccinated, total_vaccinations 
FROM covid_vaccination AS cv
ORDER BY location,date;

-- 4. Creating view
CREATE VIEW PercentPopVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations AS DailyNewVaccine,
SUM(cv.new_vaccinations) OVER (partition by location ORDER BY cd.location, cd.date) AS TotalVaccineProvided
FROM covid_deaths AS cd
JOIN covid_vaccination AS cv 
	ON cd.location = cv.location
    and cd.date = cv.date
WHERE cd.continent NOT LIKE ""
GROUP BY cd.continent, cd.location, cd.population, cd.date
ORDER by cd.Location, cd.date;
