--SELECT *
--FROM PortfolioProject..CovidDeaths
--ORDER BY 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--Order By 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order By 1,2

-- Looking at the total cases and deaths --

Alter Table PortfolioProject.dbo.CovidDeaths
Alter Column total_deaths int;

Alter Table PortfolioProject.dbo.CovidDeaths
Alter Column total_cases int;

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
Order By 1,2

-- Look at the total population vs total cases
Select Location, date, total_cases, population, (total_cases/population)*100 as CasePercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
Order By 1,2

-- look at countries with highest infection rate cpmpared to population

Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as CasePercentage
From PortfolioProject..CovidDeaths
Group By location, population
Order By CasePercentage DESC

-- showing the countries with highest death count per population

Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not NULL
Group By location
Order By TotalDeathCount DESC

-- and we break things down by continent
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not NULL
Group By continent
Order By TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT date, location, new_cases, new_deaths
From PortfolioProject..CovidDeaths
Where new_cases <> 0 AND location = 'United States'
Order By date

SELECT
	date,
	SUM(new_cases) as tc,
	SUM(new_deaths) as td,
	SUM(new_deaths)/SUM(new_cases) as DeathRate
From PortfolioProject..CovidDeaths
Where new_cases <> 0 AND location = 'United States' /* or use: Having tc <> 0*/
Group By date

-- Join the two tables --

Alter Table PortfolioProject..CovidVaccinations
Alter Column new_vaccinations bigint;

Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) over (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVacinated
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	ON dea.date = vac.date
Where dea.continent is not Null
Order By 2,3

-- use CTE

With popvsvac (
	continent, 
	location,
	date,
	population,
	new_vacinnations,
	RollingPeopleVaccinated)
AS
(
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) over (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	ON dea.date = vac.date
Where dea.continent is not Null
)

Select *, (RollingPeopleVaccinated/population)*100 as VaccinationRate
From popvsvac
Order By location, date

-- Temp table
Drop Table if exists #VacRate
Create Table #VacRate
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #VacRate
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) over (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	ON dea.date = vac.date
Where dea.continent is not Null

Select *, (RollingPeopleVaccinated/population)*100 as VaccinationRate
From #VacRate
Order By location, date

-- create views to store data for visualization

Create View VacRate as
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) over (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths as dea
Join PortfolioProject..CovidVaccinations as vac
	ON dea.date = vac.date
Where dea.continent is not Null

Select *
From VacRate