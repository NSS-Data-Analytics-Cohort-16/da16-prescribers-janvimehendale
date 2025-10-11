-- 1.	a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
--Report the npi and the total number of claims.
--1881634483	99707
SELECT
	p1.npi,
	SUM(p2.total_claim_count) AS total_claim
FROM prescriber AS p1
LEFT JOIN prescription AS p2
USING (npi)
WHERE p2.drug_name IS NOT NULL
	OR p2.total_claim_count IS NOT NULL
GROUP BY p1.npi 
ORDER BY total_claim DESC
LIMIT 1;

--OR

SELECT
	npi,
	SUM(total_claim_count) 
FROM prescription
GROUP BY npi 
ORDER BY SUM(total_claim_count) DESC
LIMIT 5;
-----------------------------------------------------------------------------------------------------------
-- b. Repeat the above, but this time report the nppes_provider_first_name,
--nppes_provider_last_org_name, specialty_description, and the total number of claims.
--1881634483	"BRUCE"	"PENDLEY"	"Family Practice"	99707

SELECT
	p1.npi,
	p1.nppes_provider_first_name AS first_name,
	p1.nppes_provider_last_org_name AS last_name,
	p1.specialty_description AS speciality,
	SUM(p2.total_claim_count) AS total_claim
FROM prescriber AS p1
LEFT JOIN prescription AS p2
USING (npi)
WHERE p2.drug_name IS NOT NULL
	OR p2.total_claim_count IS NOT NULL
GROUP BY p1.npi,first_name, last_name, speciality
ORDER BY total_claim DESC
LIMIT 1;

-----------------------------------------------------------------------------------------------------------
-- 2.	a. Which specialty had the most total number of claims (totaled over all drugs)?
--"Family Practice"	9752347

SELECT
	p1.specialty_description AS speciality,
	SUM(p2.total_claim_count) AS total_claim
FROM prescriber AS p1
LEFT JOIN prescription AS p2
USING (npi)
WHERE p2.drug_name IS NOT NULL
	OR p2.total_claim_count IS NOT NULL
GROUP BY speciality
ORDER BY total_claim DESC
LIMIT 5; 

-----------------------------------------------------------------------------------------------------------
-- b. Which specialty had the most total number of claims for opioids?
-- "Nurse Practitioner"	900845

SELECT
	p1.specialty_description AS speciality,
	SUM(p2.total_claim_count) AS total_claim
FROM prescriber AS p1
LEFT JOIN prescription AS p2
USING (npi)
INNER JOIN drug d
ON d.drug_name = p2.drug_name
WHERE 
	d.opioid_drug_flag = 'Y'
GROUP BY speciality 
ORDER BY total_claim DESC
LIMIT 5;
----------------------------------------------------------------------------------------------------------
-- c. Challenge Question: Are there any specialties that appear in the prescriber table 
--that have no associated prescriptions in the prescription table?

SELECT
	p.specialty_description AS specialty_count,
	COUNT(npi),
	p1.drug_name
FROM prescriber p
LEFT JOIN prescription p1
USING (npi)
WHERE p1.npi IS NULL
GROUP BY p1.drug_name, p.specialty_description;
-----------------------------------------------------------------------------------------------------------
-- d. Difficult Bonus: Do not attempt until you have solved all other problems! 
--For each specialty, report the percentage of total claims by that specialty which
--are for opioids. Which specialties have a high percentage of opioids?
SELECT
	p.specialty_description AS specialty,
	(SELECT (total_claim_count FROM prerscription WHERE d.opioid_drug_flag = 'Y' *100/  ),2) AS percentage
	FROM prescriber p
LEFT JOIN prescription p1
USING (npi)
LEFT JOIN drug d
ON d.drug_name = p1.drug_name
WHERE d.opioid_drug_flag = 'Y'
GROUP BY specialty;
-----------------------------------------------------------------------------------------------------------
-- 3.	a. Which drug (generic_name) had the highest total drug cost?
--"INSULIN GLARGINE,HUM.REC.ANLOG"	104264066.35
SELECT
	d.generic_name,
	SUM(p.total_drug_cost) AS drug_cost
FROM prescription p
INNER JOIN drug d
USING (drug_name)
WHERE p.total_drug_cost IS NOT NULL
GROUP BY d.generic_name
ORDER BY drug_cost DESC
LIMIT 1;

-----------------------------------------------------------------------------------------------------------
-- b. Which drug (generic_name) has the hightest total cost per day?
--Bonus: Round your cost per day column to 2 decimal places. 
--Google ROUND to see how this works.
-- "C1 ESTERASE INHIBITOR"	3495.22	

SELECT
	d.generic_name,
	ROUND(SUM(p.total_drug_cost)/ SUM(p.total_day_supply),2) AS daily_cost
FROM drug d
INNER JOIN prescription p
	USING (drug_name)
GROUP BY d.generic_name
ORDER BY daily_cost DESC
LIMIT 5;

-----------------------------------------------------------------------------------------------------------
-- 4.	a. For each drug in the drug table, return the drug name and then a column named
--'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 
--'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither'
--for all other drugs. 
--Hint: You may want to use a CASE expression for this. 
--See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT 
	drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		  WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		  ELSE 'neither'
		  END AS drug_type
FROM drug;
-----------------------------------------------------------------------------------------------------------
-- b. Building off of the query you wrote for part a, determine whether more was spent
--(total_drug_cost) on opioids or on antibiotics. 
--Hint: Format the total costs as MONEY for easier comparision.
--"opioid"	105080626.37
SELECT 
	CASE WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither'
		 END AS drug_type,
	SUM(p.total_drug_cost) AS MONEY
FROM drug d
INNER JOIN prescription p
USING (drug_name)
WHERE d.opioid_drug_flag = 'Y'
OR d.antibiotic_drug_flag = 'Y'
GROUP BY drug_type,
	d.opioid_drug_flag, 
	d.antibiotic_drug_flag	
ORDER BY MONEY DESC;
-----------------------------------------------------------------------------------------------------------
-- 5.	a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information
-- for all states, not just Tennessee. Answer--33

SELECT
	COUNT(cbsa)
FROM cbsa
WHERE cbsaname ILIKE '%TN';
-----------------------------------------------------------------------------------------------------------
-- b. Which cbsa has the largest combined population? Which has the smallest? Report the
-- CBSA name and total population.
--""Nashville-Davidson--Murfreesboro--Franklin, TN"	1830410	"largest population"
--"Morristown, TN"	116352	"smallest population"

WITH combined_population AS(
	SELECT
		c.cbsaname AS cbsa_name,
		SUM(p.population) AS total_population
		FROM population p
		LEFT JOIN cbsa c
		USING (fipscounty)
		GROUP BY cbsa_name
)

SELECT 
	cbsa_name,
	total_population,
	CASE
		WHEN total_population = (SELECT MAX(total_population) FROM combined_population) 
			THEN 'largest population'
		WHEN total_population = (SELECT MIN(total_population) FROM combined_population) 
			THEN 'smallest population'
		ELSE 'other'
		END AS cbsa_population 
FROM combined_population
--WHERE cbsa_population IN ('largest population', 'smallest population')
ORDER BY total_population DESC
;

-----------------------------------------------------------------------------------------------------------
-- c. What is the largest (in terms of population) county which is not included in a CBSA? 
--Report the county name and population. Answer - "SEVIER"	95523

SELECT -- to check all the county names in the different tables
p.fipscounty,
f.county,
c.cbsaname,
p.population
FROM population p
LEFT JOIN cbsa c 
	USING (fipscounty)
LEFT JOIN fips_county f 
	USING (fipscounty)

SELECT
	f.fipscounty,
	f.county AS county_name,
	SUM(p.population) AS population
FROM population p
LEFT JOIN fips_county f
USING(fipscounty)
LEFT JOIN cbsa c
USING(fipscounty)
WHERE c.fipscounty IS NULL
GROUP BY f.county, f.fipscounty
ORDER BY population DESC;

-----------------------------------------------------------------------------------------------------------
-- 6.	a. Find all rows in the prescription table where total_claims is at least 3000.
--Report the drug_name and the total_claim_count.

SELECT 
	drug_name,
	total_claim_count
FROM prescription
WHERE total_claim_count >= '3000'
ORDER BY total_claim_count;

-----------------------------------------------------------------------------------------------------------
-- b. For each instance that you found in part a, add a column that indicates
--whether the drug is an opioid.

SELECT 
	p.drug_name,
	p.total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not opioid'
		END AS drug_type
FROM prescription p 
LEFT JOIN drug d
USING (drug_name)
WHERE total_claim_count >= '3000'
ORDER BY total_claim_count;

-----------------------------------------------------------------------------------------------------------
-- c. Add another column to you answer from the previous part which gives the prescriber 
-- first and last name associated with each row.
SELECT 
	p.drug_name,
	p.total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not opioid'
		END AS drug_type,
	CONCAT(prescriber.nppes_provider_first_name,' ', prescriber.nppes_provider_last_org_name) AS provider_name
FROM prescription p 
LEFT JOIN drug d
USING (drug_name)
LEFT JOIN prescriber
ON prescriber.npi = p.npi
WHERE total_claim_count >= '3000'
ORDER BY total_claim_count;
-----------------------------------------------------------------------------------------------------------

-- 7.	The goal of this exercise is to generate a full list of all pain management 
-- specialists in Nashville and the number of claims they had for each opioid. 
-- Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management 
-- specialists --(specialty_description = 'Pain Management) in the city of Nashville 
-- (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y').
-- Warning: Double-check your query before running it. You will only need to use the 
-- prescriber and drug tables since you don't need the claims numbers yet.

SELECT 
	p.npi,
	CONCAT(p.nppes_provider_first_name,' ', p.nppes_provider_last_org_name) AS specialist,
	d.drug_name,
	p.specialty_description
FROM prescriber p
CROSS JOIN drug d
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city ILIKE 'Nashville'
AND d.opioid_drug_flag = 'Y'

-----------------------------------------------------------------------------------------------------------

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all 
-- combinations, whether or not the prescriber had any claims. You should report the npi,
-- the drug name, and the number of claims (total_claim_count).
SELECT 
	p.npi,
	CONCAT(p.nppes_provider_first_name,' ', p.nppes_provider_last_org_name) AS specialist,
	d.drug_name,
	p1.total_claim_count
FROM prescriber p
CROSS JOIN drug d
LEFT JOIN prescription p1
ON p1.npi = p.npi
AND p1.drug_name = d.drug_name
WHERE p.specialty_description = 'Pain Management'
AND p.nppes_provider_city ILIKE 'Nashville'
AND d.opioid_drug_flag = 'Y'

-----------------------------------------------------------------------------------------------------------
-- c. Finally, if you have not done so already, fill in any missing values for
--total_claim_count with 0. Hint - Google the COALESCE function.
SELECT 
	p.npi,
	CONCAT(p.nppes_provider_first_name,' ', p.nppes_provider_last_org_name) AS specialist,
	d.drug_name,
	COALESCE (p1.total_claim_count,0)
FROM prescriber p
CROSS JOIN drug d
LEFT JOIN prescription p1
ON p1.npi = p.npi
AND p1.drug_name = d.drug_name
WHERE p.specialty_description = 'Pain Management'
AND p.nppes_provider_city ILIKE 'Nashville'
AND d.opioid_drug_flag = 'Y'

-----------------------------------------------------------------------------------------------------------

