Select *
From PortfolioProjects..CovidDeaths
order by 3,4

-- Comment this out to use the second table later.
--Select *
--From PortfolioProjects..CovidVaccinations
--order by 3,4

-- First select the data we want to explore.

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProjects..CovidDeaths
order by 1,2

-- Let's look at the percentage of Covid cases which were fatal in the United States.

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProjects..CovidDeaths
Where location like '%states%'
order by 1,2

-- Now let's look at the percentage of the total US population which caught Covid.

Select Location, date, total_cases, population, (total_cases/population)*100 as CaughtPercentage
From PortfolioProjects..CovidDeaths
Where location like '%states%'
order by 1,2

-- Let's look at the countries with the highest infected percentage.

Select Location, Population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProjects..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

-- Let's look at which countries have the highest quantity of fatalities.

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProjects..CovidDeaths
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- I'm interested in Japan's statistics.

Select *
From PortfolioProjects..CovidDeaths
Where location like '%japan%'
order by date

-- Filtering columns to see only the columns that match my friend's paper.

Select Location, date, population, total_deaths, (total_cases/population)*100 as CaughtPercentage, new_deaths
From PortfolioProjects..CovidDeaths
Where location like '%japan%'
order by date

-- Here we'll look at the same info (highest quantity of fatalities) by continent instead of country.
-- This dataset includes income levels as locations, so we will filter them out using the common term 'income'.

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProjects..CovidDeaths
Where continent is null and location not like '%income%'
Group by Location
order by TotalDeathCount desc

-- Let's look on a global scale. Below will show the global percentage of cases which were fatal each day.

-- Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
-- From PortfolioProjects..CovidDeaths
-- Where continent is not null
--Group by date
-- order by 1,2

-- Now we'll add the CovidVaccinations table to get some insights on vaccination data.

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProjects..CovidDeaths dea
Join PortfolioProjects..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to get a rolling count of people vaccinated each day, and percent of total pop vaccinated.

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProjects..CovidDeaths dea
Join PortfolioProjects..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using a Temp Table to calculate the above.

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProjects..CovidDeaths dea
Join PortfolioProjects..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 as RollingPercentVaccinated
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProjects..CovidDeaths dea
Join PortfolioProjects..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *
From PercentPopulationVaccinated