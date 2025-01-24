SELECT *
FROM layoffs;

-- Creating staging tables to not mess up raw data 

CREATE TABLE layoffs_stage1
LIKE layoffs;

INSERT layoffs_stage1
SELECT * 
FROM layoffs;

-- Remove duplicates

WITH dupe_cte AS(
SELECT *,
ROW_NUMBER()OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_nums
FROM layoffs_stage1
)

DELETE 
FROM dupe_cte
WHERE row_nums>1;

CREATE TABLE `layoffs_stage2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` float DEFAULT NULL,
  `row_nums` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_stage2
SELECT *,
ROW_NUMBER()OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_nums
FROM layoffs_stage1;

DELETE
FROM layoffs_stage2
WHERE row_nums>1;

SELECT *
FROM layoffs_stage2
WHERE row_nums>1;

-- Standerdize/fix data 
UPDATE layoffs_stage2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_stage2
MODIFY COLUMN `date` DATE;

UPDATE layoffs_stage2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_stage2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

UPDATE layoffs_stage2
SET company = TRIM(company);

-- NULL value handling 

UPDATE layoffs_stage2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_stage2 AS t1
JOIN layoffs_stage2 AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL )
AND t2.industry IS NOT NULL;


UPDATE layoffs_stage2 AS t1
JOIN layoffs_stage2 AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL)
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_stage2 AS t1
JOIN layoffs_stage2 AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.stage LIKE 'Unknown' )
AND t2.stage NOT LIKE 'Unknown';

SELECT COUNT(*)
FROM layoffs_stage2
WHERE stage LIKE 'Unknown';


UPDATE layoffs_stage2 AS t1
JOIN layoffs_stage2 AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.stage = t2.stage
WHERE (t1.stage LIKE 'Unknown' )
AND t2.stage NOT LIKE 'Unknown';

SELECT COUNT(*)
FROM layoffs_stage2
WHERE stage LIKE 'Unknown';

ALTER TABLE layoffs_stage2
DROP COLUMN row_nums;




