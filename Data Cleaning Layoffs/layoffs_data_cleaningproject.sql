-- SQL Data Cleaning Project 

SELECT *
FROM layoffs;

-- 1. Remove Duplicates: 
-- 2. Standardize the Data
-- 3. Null Values or Blank Values 
-- 4. Remove Any Columns 

-- First Step: Create a Staging Table, so we won't work on the raw data

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- Now we can begin our data cleaning process 

-- 1. Remove Duplicates

-- Checking for Duplicates, any row_num > 1 confirms duplicates

WITH duplicate_cte AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)

SELECT  * 
FROM duplicate_cte 
WHERE row_num > 1;

-- let's look at one of the duplicate entries just to make sure
SELECT *
FROM layoffs_staging 
WHERE company = 'Hibob';

-- it's confirmed that all the duplicates are legitimate and should be removed. However, we have to ensure that we don't delete everything, just the the duplicates 

-- Since MYSQL doesn't allow for CTEs to used for DELETE operations, we can advance our stage into stage 2. 

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ;


-- Inserting Data into Stage 2 
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Checking Table Creation and filtering
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Removing Duplicates

DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

-- Checking Results
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- 2. Standardize the Data

-- Trim Leading Spaces From Data
UPDATE layoffs_staging2 
SET company = TRIM(company);

-- Checking Results:

SELECT DISTINCT(company)
FROM layoffs_staging2;

-- Checking Industry 

SELECT industry
FROM layoffs_staging2;

-- Checking we found Crypto and Crypto Currency are the same industry, we should Group them and convert Crpyto Currency to just Crypto
-- Grouping to Normalize Data

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Let's check our Data

SELECT * 
FROM layoffs_staging2 

-- If we we look at Countries United State is duplicated with United States. Let's standardize it by updating the column to remove the '.'

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'

-- Double Checking 

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- The Date is set to str, let's update this field 

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); 

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- If we look at industry it looks like we have some null and empty rows

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- Verify if Rows Contain Missing Data

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';
-- looks good

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'airbnb%';

-- Airbnb is travel, but one of the rows isn't populated, other rows may have similar issues 
-- Update industry with a query that if there is another row with the same company, it will update it to the non-null values 

-- Set Blanks to Null 

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''; 

-- Checking if conversion worked

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- Populating Nulls if possible 

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Checking Results: 

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- Bailey is confirmed the only one without a populated row 

-- 3. Looking at Null values 

-- The null values in total_laid_off, percentage_laid_off, and funds_raised_millions appear as expected. 
-- I prefer to keep them null since it simplifies calculations during the EDA phase. 
-- Therefore, no changes are needed for the null values


-- 4. Remove any columns and rows unneccssary

SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND 
percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL AND 
percentage_laid_off IS NULL;

-- Dropping row_num from previous Step 1 

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final Table:

SELECT *
FROM layoffs_staging2;








