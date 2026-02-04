# Projekt z SQL Engeto

## Datová příprava (Primary Table)

Základem celé analýzy je tabulka `t_vladimir_radek_project_SQL_primary_final`. Při jejím vytváření jsem kladl důraz na čistotu dat a eliminaci duplicit.

### Logika tvorby tabulky:
1.  **Mzdy (`cpay`):** Filtroval jsem data na průměrné mzdy (kód 5958) a seskupil je podle let a odvětví. Použil jsem funkci `AVG()`, aby byla zajištěna unikátnost záznamů pro každé odvětví v daném roce.
2.  **Ceny potravin (`cpri`):** Agregoval jsem ceny jednotlivých kategorií potravin na roční průměry pomocí funkce `date_part` a následného seskupení.
3.  **Spojení (JOIN):** Obě sady jsem propojil přes rok, čímž vznikl robustní dataset pro srovnání kupní síly.

### SQL definice primární tabulky:
```sql
CREATE TABLE IF NOT EXISTS t_vladimir_radek_project_SQL_primary_final AS
SELECT 
    cpay.payroll_year, 
    cpay."name" AS branch_name, 
    cpay.avg_salary AS avg_salary,
    cpri.name AS prod_cat_name, 
    cpri.avg_prod_cat_value AS avg_prod_cat_price,
    cpri.price_value,
    cpri.price_unit 
FROM (
    -- Subquery pro mzdy
    SELECT
        cpa.payroll_year,
        cpa.industry_branch_code,
        AVG(cpa.value) AS AVG_salary,
        cpib."name" 
    FROM czechia_payroll cpa
    JOIN czechia_payroll_industry_branch cpib ON cpa.industry_branch_code = cpib.code 
    WHERE cpa.value_type_code = 5958
    GROUP BY cpa.payroll_year, cpa.industry_branch_code, cpib."name" 
) cpay
JOIN (
    -- Subquery pro ceny potravin
    SELECT 
        cpr.category_code,
        AVG(cpr.value) AS avg_prod_cat_value,
        cpc."name",
        date_part('year', cpr.date_from) AS year,
        cpc.price_value,
        cpc.price_unit
    FROM czechia_price cpr
    JOIN czechia_price_category cpc ON cpr.category_code = cpc.code
    GROUP BY cpr.category_code, cpc."name", "year", cpc.price_value, cpc.price_unit 
) cpri ON cpay.payroll_year = cpri."year";
```


## Sekundární data (Secondary Table)

Pro kontextuální analýzu v rámci celé Evropy jsem vytvořil tabulku `t_vladimir_radek_project_SQL_secondary_final`. Tato data slouží k porovnání ekonomické situace ČR s ostatními evropskými státy a k analýze vlivu makroekonomických ukazatelů.

### Logika tvorby tabulky:
1.  **Dynamický rozsah let:** Pomocí CTE `selected_years` jsem zjistil průnik let, pro která máme data o mzdách i cenách v ČR (2006–2018). Tento rozsah se automaticky aplikuje na filtraci ekonomických dat.
2.  **Geografické omezení:** Data byla filtrována pouze na evropský kontinent (`continent = 'Europe'`).
3.  **Ekonomické ukazatele:** Tabulka zahrnuje HDP, populaci, Giniho koeficient (příjmová nerovnost) a daně.

### SQL definice sekundární tabulky:
```sql
CREATE TABLE IF NOT EXISTS t_vladimir_radek_project_SQL_secondary_final AS
WITH selected_years AS (
    -- Sjednocení časového rámce s primární tabulkou
    SELECT 
        MAX(cp.payroll_year) AS max_year,
        MIN(cp.payroll_year) AS min_year
    FROM czechia_payroll cp
    WHERE cp.payroll_year IN (
        SELECT date_part('year', date_from) FROM czechia_price
    )
)
SELECT 
    DISTINCT e."year",
    e.country,
    e.gdp,
    e.population,
    e.gini,
    e.taxes 
FROM (
    SELECT * FROM countries WHERE continent = 'Europe' 
) c
JOIN economies e ON c.country = e.country
WHERE e.year BETWEEN (SELECT min_year FROM selected_years)
             AND (SELECT max_year FROM selected_years)
ORDER BY e.country, e."year";
```

# 📊 Analýza životní úrovně: Dostupnost potravin a vývoj mezd v ČR

Tento projekt byl vypracován jako podklad pro tiskové oddělení nezávislé společnosti zabývající se životní úrovní občanů. Cílem je poskytnout robustní datové podklady pro konferenci zaměřenou na ekonomický vývoj ČR, se zaměřením na kupní sílu a makroekonomické souvislosti v období let **2006–2018**.

---

## 📂 Struktura projektu
Repozitář obsahuje následující klíčové soubory:
* `t_vladimir_radek_project_SQL_primary_final.sql`: Skript generující sjednocená data mezd a cen potravin za ČR.
* `t_vladimir_radek_project_SQL_secondary_final.sql`: Skript s dodatečnými daty o evropských státech (HDP, GINI, populace).
* `1_dotaz.sql` až `5_dotaz.sql`: SQL skripty odpovídající na výzkumné otázky.

---

## 🛠️ Metodika a zpracování dat
Při zpracování bylo postupováno dle zadání s důrazem na integritu primárních tabulek. Veškeré transformace proběhly v nově vytvořených tabulkách a pohledech.

### Klíčové výpočty:
Pro sledování trendů byl využit vzorec procentuální změny:
$$\text{percentuální změna} = \frac{a - b}{b} \times 100$$
*kde **a** je hodnota v aktuálním roce a **b** hodnota v roce předchozím.*

---

## 🔍 Výzkumné otázky a jejich zodpovězení

### 1. Vývoj mezd v odvětvích
*Otázka: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?*
**Závěr:**
Většinu sledovaného období mzdy rostly, avšak analýza identifikovala několik let, kdy došlo k poklesu. Nejkritičtějším byl rok **2013**, kdy průměrná mzda meziročně klesla ve **12 odvětvích**. 

**Stálice českého trhu práce:**
Existují však čtyři odvětví, která byla jako **jediná imunní vůči poklesům** a jejich průměrná mzda rostla (nebo stagnovala) v každém roce celého sledovaného období (2006–2018):
* **Zpracovatelský průmysl** (klíčový pilíř české ekonomiky),
* **Zdravotní a sociální péče**,
* **Doprava a skladování**,
* **Ostatní činnosti**.

**Klíčová zjištění o poklesech:**
* **Nejvýraznější propad:** Odvětví *Peněžnictví a pojišťovnictví* zaznamenalo v roce 2013 pokles o více než 4 400 Kč.
* **Sektorová nestabilita:** Odvětví *Těžba a dobývání* vykazovalo poklesy nejčastěji (celkem 4x během sledovaného období).
* **SQL podklad:** Viz soubor `1_dotaz.sql` a `1_query_additional.sql`.

### 2. Kupní síla: Chléb a mléko
*Otázka: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období?*
* **Srovnání (2006 vs. 2018):**
    * **Chléb (1 kg):** Za průměrnou mzdu v roce 2006 bylo možné koupit **1287,16 kg**, v roce 2018 pak **1342,32 kg**.
    * **Mléko (1 l):** Za průměrnou mzdu v roce 2006 bylo možné koupit **1437,46 l**, v roce 2018 pak **1641,77 l**.
* **Závěr:** Z dat vyplývá pozitivní trend pro spotřebitele. Ačkoliv nominální ceny potravin v průběhu let rostou, průměrná mzda rostla rychlejším tempem. Díky tomu si průměrný občan mohl v roce 2018 koupit o **55 kg chleba** a o **204 litrů mléka** více než na počátku sledovaného období. Životní úroveň v kontextu těchto základních potravin se tedy prokazatelně zvýšila.
* **SQL podklad:** Viz soubor `2_dotaz.sql`.

### 3. Nejpomaleji zdražující potravina
*Otázka: Která kategorie potravin zdražuje nejpomaleji (nejnižší procentuální meziroční nárůst)?*
* **Metodická poznámka:** Pro účely této analýzy byly brány v úvahu pouze kategorie vykazující **meziroční nárůst** (kladnou hodnotu). Kategorie, které v daném období zlevňovaly (záporný nárůst), byly vynechány, aby bylo možné identifikovat položku, jejíž cena sice stoupá, ale nejpomalejším tempem.
* **Závěr:** Při započtení pouze kladných meziročních nárůstů byla identifikována jako nejpomaleji zdražující kategorie **Banány žluté** s průměrným meziročním růstem **0.81 %**.
* **SQL podklad:** Viz soubor `3_dotaz.sql`.

### 4. Meziroční nárůst cen vs. růst mezd
*Otázka: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?*
* **Závěr:** Na základě analýzy nebyl zjiště žádný rok, který by vykazoval zdražení potravin o více než 10 % oproti růstu mezd. Při detailnější analýze jsem ale došel k závěru, že v téměř každém zkoumaném roce nejsou výjimkou dramatické nárůsty cen u jednotlivých kategorií.
* Příkladem mohou být následující kategorie
    * **Papriky (2007):** Absolutním rekordmanem v meziročním zdražení se staly papriky v roce 2007. Jejich cena vyskočila o 94,8 %, což v porovnání s tehdejším 6,8% růstem mezd představovalo téměř čtrnáctinásobně rychlejší tempo růstu.**. 
    * **Brambory (2013):** Nárůst ceny o **60,3 %** při současném poklesu mezd o **1,5 %**.
    * **Vejce (2012):** Nárůst o **54,8 %** při růstu mezd o pouhá **3 %**.
    * **Máslo (2017):** Skokové zdražení o **33,3 %**, které výrazně předstihlo mzdový růst (6,3 %). 
* **SQL podklad:** Viz soubor `4_dotaz.sql` a `4_query_additional.sql`.

### 5. Vliv HDP na mzdy a ceny
*Otázka: Má výška HDP vliv na změny ve mzdách a cenách potravin?*
* **Klíčová zjištění:**
    * **Mzdová setrvačnost:** Výrazný růst HDP v roce 2015 (+5,39 %) se plně projevil na akceleraci mzdového růstu až v letech 2017–2018 (nárůst mezd přes 6–7 %).
    * **Odezva na recesi:** Ekonomický propad z let 2009 a 2012 se s mírným zpožděním odrazil v mzdové stagnaci a poklesech v roce 2013.
    * **Ceny potravin:** U cen potravin nebyla potvrzena přímá závislost na HDP. Ceny potravin kolísají výrazněji a pravděpodobně podléhají jiným vlivům (např. sezónnost, exportní politika) než celkovému výkonu ekonomiky.
* **Závěr:** HDP má na ekonomiku zásadní vliv, ale projevuje se s určitým **časovým odstupem**. 
* **SQL podklad:** Viz soubor `5_dotaz.sql`.

---

## 📈 Technické detaily výstupu
Pro tvorbu reportu byly vytvořeny dvě hlavní tabulky:

1. **Primární tabulka:** `t_vladimir_radek_project_SQL_primary_final`
    - Sjednocuje data o mzdách (`czechia_payroll`) a cenách (`czechia_price`).
    - Filtrováno na společná období a relevantní typy kalkulací (fyzické osoby, průměrné mzdy).

2. **Sekundární tabulka:** `t_vladimir_radek_project_SQL_secondary_final`
    - Propojuje data o zemích (`countries`) a jejich ekonomikách (`economies`).
    - Zaměřeno na evropské státy a časový rámec odpovídající primární tabulce.

---

## Datová omezení a poznámky
* **Časová dostupnost potravin:** U kategorie **Jakostní víno bílé** jsou data dostupná až od roku 2015, což bylo zohledněno při interpretaci dlouhodobých trendů.
* **Agregace mezd:** Data pracují s průměry za celá odvětví, nikoliv za konkrétní pozice. Analýza tedy nepostihuje rozdíly mezi konkrétními profesemi uvnitř jednoho sektoru (např. rozdíl mezi mzdou programátora a operátora technické podpory v rámci IT).
* **Roční agregace:** Ceny potravin i mzdy jsou v analýze průměrovány za celý kalendářní rok. Tato agregace poskytuje jasný pohled na dlouhodobé trendy, ale přirozeně "vyhlazuje" krátkodobé sezónní výkyvy (např. dočasné skoky cen zeleniny během neúrody nebo vánoční bonusy u mezd).
* **Sekundární dataset:** Tabulka `secondary_final` obsahuje kompletní ekonomická data (HDP, populace). U doplňkových ukazatelů (GINI, daně) jsou u některých zemí dostupné záznamy až v novějších letech.