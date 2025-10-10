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

-----------------------------------------------------------------------------------------------------------
-- d. Difficult Bonus: Do not attempt until you have solved all other problems! 
--For each specialty, report the percentage of total claims by that specialty which
--are for opioids. Which specialties have a high percentage of opioids?

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
-- "C1 ESTERASE INHIBITOR"	3495.22	115546.00

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
GROUP BY drug_type,
	d.opioid_drug_flag, 
	d.antibiotic_drug_flag	
ORDER BY MONEY DESC;
-----------------------------------------------------------------------------------------------------------
-- 5.	a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information
-- for all states, not just Tennessee. Answer--33

SELECT
	COUNT(*)
FROM cbsa
WHERE cbsaname ILIKE '%TN';
-----------------------------------------------------------------------------------------------------------
-- b. Which cbsa has the largest combined population? Which has the smallest? Report the
-- CBSA name and total population.
--"Yuma, AZ"	"49740"	"largest_population"
--"Abilene, TX"	"10180"	"smallest_population"

SELECT
	cbsaname,
	cbsa,
	CASE 
		WHEN cbsa = (SELECT MAX(cbsa) FROM cbsa) THEN 'largest_population'
		WHEN cbsa = (SELECT MIN(cbsa) FROM cbsa) THEN 'smallest_population'
		END AS population
FROM cbsa
GROUP BY cbsa, cbsaname, population
ORDER BY population
LIMIT 2;

-----------------------------------------------------------------------------------------------------------
-- c. What is the largest (in terms of population) county which is not included in a CBSA? 
--Report the county name and population.

SELECT
	*,
	CASE 
		WHEN cbsa = (SELECT MAX(cbsa) FROM cbsa) THEN 'largest_population'
		WHEN cbsa = (SELECT MIN(cbsa) FROM cbsa) THEN 'smallest_population'
		END AS population
FROM cbsa
GROUP BY cbsa, cbsaname, population, fipscounty
ORDER BY population
LIMIT 2;

-----------------------------------------------------------------------------------------------------------
-- 6.	a. Find all rows in the prescription table where total_claims is at least 3000.
--Report the drug_name and the total_claim_count.

-----------------------------------------------------------------------------------------------------------
-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

-----------------------------------------------------------------------------------------------------------
-- c. Add another column to you answer from the previous part which gives the prescriber 
-- first and last name associated with each row.

-----------------------------------------------------------------------------------------------------------
-- 7.	The goal of this exercise is to generate a full list of all pain management 
-- specialists in Nashville and the number of claims they had for each opioid. 
-- Hint: The results from all 3 parts will have 637 rows.

-----------------------------------------------------------------------------------------------------------
-- a. First, create a list of all npi/drug_name combinations for pain management 
-- specialists --(specialty_description = 'Pain Management) in the city of Nashville 
-- (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y').
-- Warning: Double-check your query before running it. You will only need to use the 
-- prescriber and drug tables since you don't need the claims numbers yet.

-----------------------------------------------------------------------------------------------------------
-- b. Next, report the number of claims per drug per prescriber. Be sure to include all 
-- combinations, whether or not the prescriber had any claims. You should report the npi,
-- the drug name, and the number of claims (total_claim_count).

-----------------------------------------------------------------------------------------------------------
-- c. Finally, if you have not done so already, fill in any missing values for
--total_claim_count with 0. Hint - Google the COALESCE function.

-----------------------------------------------------------------------------------------------------------

