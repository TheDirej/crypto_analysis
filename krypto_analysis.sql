##### Legend / Commenting Structure #####

#### – Interesting findings / unexpected observations
### – Project name or main title
##  – Major step or milestone (e.g., Data Cleaning, Data Analysis)
#   – Minor step or specific task (e.g., Filtering data, Calculating averages)
--   – Inline comments, explanations, or temporarily disabled code


### Krypto BTC-ETH-SOL-AVAX-DOT comparison

-- [NOTE] Changne column name containing crypto coin name
ALTER TABLE krypto.btc_eth_sol_avax_dot
CHANGE `MyUnknownColumn` coin TEXT; 

-- [NOTE] Creating 'date' column and place it as 1 column
ALTER TABLE krypto.btc_eth_sol_avax_dot
ADD COLUMN `Date` DATE;

UPDATE krypto.btc_eth_sol_avax_dot
SET `Date` = CAST(CONCAT(year,'-',month,'-',day) AS DATE);

ALTER TABLE krypto.btc_eth_sol_avax_dot
MODIFY COLUMN `Date` DATE FIRST;

SELECT *
FROM krypto.btc_eth_sol_avax_dot;


## Basic Data Exploration


# 0.9 View on first and last day of coin existency 
SELECT DISTINCT coin,
	MAX(date) AS last_day,
    MIN(date) AS first_day
FROM krypto.btc_eth_sol_avax_dot
GROUP BY coin;

# 1.0 How many records are in the table for each cryptocurrency
SELECT COUNT(*), coin
FROM krypto.btc_eth_sol_avax_dot
GROUP BY coin;

# 1.1 Average closing price monthly 
SELECT coin, year, month, AVG(price) AS avg_price_monthly
FROM krypto.btc_eth_sol_avax_dot
GROUP BY year, month, coin
;

SELECT year, month,
	ROUND(AVG(CASE WHEN coin = 'Bitcoin' THEN price END),2) AS BTC_AVG_price,
    ROUND(AVG(CASE WHEN coin = 'ETH' THEN price END),2) AS ETH_AVG_price,
    ROUND(AVG(CASE WHEN coin = 'Solana' THEN price END),2) AS SOL_AVG_price,
    ROUND(AVG(CASE WHEN coin = 'AVAX' THEN price END),2) AS AVAX_AVG_price,
    ROUND(AVG(CASE WHEN coin = 'PolkaDot' THEN price END),2) AS DOT_AVG_price
FROM krypto.btc_eth_sol_avax_dot
GROUP BY year, month
ORDER BY year, month
;

# 1.2 Average volume monthly
SELECT year, month,
	ROUND(AVG(CASE WHEN coin = 'Bitcoin' THEN Total_volume END),2) AS BTC_AVG_volume,
    ROUND(AVG(CASE WHEN coin = 'ETH' THEN Total_volume END),2) AS ETH_AVG_volume,
    ROUND(AVG(CASE WHEN coin = 'Solana' THEN Total_volume END),2) AS SOL_AVG_volume,
    ROUND(AVG(CASE WHEN coin = 'AVAX' THEN Total_volume END),2) AS AVAX_AVG_volume,
    ROUND(AVG(CASE WHEN coin = 'PolkaDot' THEN Total_volume END),2) AS DOT_AVG_volume
FROM krypto.btc_eth_sol_avax_dot
GROUP BY year, month
ORDER BY year, month
;


## Returns


# 1.0 Calculate the daily returns
SELECT date, coin, price,
	LAG(price, 1) OVER (PARTITION BY coin ORDER BY date) AS prev_price,
    price - LAG(price, 1) OVER (PARTITION BY coin ORDER BY date) AS price_change,
    ROUND((price - LAG(price, 1) OVER (PARTITION BY coin ORDER BY date))/(LAG(price, 1) OVER (PARTITION BY coin ORDER BY date))*100,3) AS diff_percentage
FROM krypto.btc_eth_sol_avax_dot;


# 1.1 Calculate the AVG_daily return for each coin 
WITH returns AS (
SELECT date, coin, price,
	(price - LAG(price, 1) OVER (PARTITION BY coin ORDER BY date))/(LAG(price, 1) OVER (PARTITION BY coin ORDER BY date)) AS daily_return
FROM krypto.btc_eth_sol_avax_dot
)
SELECT coin,
	AVG(daily_return) AS AVG_daily_return
FROM returns
WHERE daily_return IS NOT NULL
GROUP BY coin
;

# 1.2 Calculate the Monthly return
SELECT *
FROM (
SELECT date, year, month, day, price, coin,
	ROW_NUMBER() OVER (PARTITION BY year, month, coin ORDER BY day DESC) AS rn
FROM krypto.btc_eth_sol_avax_dot
) AS sub
WHERE rn = 1
;

WITH returns AS (
SELECT *
FROM (
SELECT date, year, month, day, price, coin,
	ROW_NUMBER() OVER (PARTITION BY year, month, coin ORDER BY day DESC) AS rn
FROM krypto.btc_eth_sol_avax_dot
) AS sub
WHERE rn = 1
)
SELECT coin, date,
	price AS month_end_price,
	LAG(price) OVER (PARTITION BY coin ORDER BY year, month) AS prev_price,
		ROUND((price / LAG(price) OVER (PARTITION BY coin ORDER BY year, month) - 1) * 100, 2) AS monthly_return_percent
FROM returns
ORDER BY coin, year, month
;


# 1.3 Calculate the AVG_monthly returns for each coin
WITH returns AS (
SELECT *
FROM (
SELECT date, year, month, day, price, coin,
	ROW_NUMBER() OVER (PARTITION BY year, month, coin ORDER BY day DESC) AS rn
FROM krypto.btc_eth_sol_avax_dot
) AS sub
WHERE rn = 1
)
SELECT coin,  
	ROUND(AVG(monthly_return_percent), 2) AS avg_monthly_return_percent
FROM (
SELECT coin, date,
	price AS month_end_price,
	LAG(price) OVER (PARTITION BY coin ORDER BY year, month) AS prev_price,
		ROUND((price / LAG(price) OVER (PARTITION BY coin ORDER BY year, month) - 1) * 100, 2) AS monthly_return_percent
FROM returns
-- ORDER BY coin, year, month 
) AS sub
GROUP BY coin
ORDER BY 2 DESC
;

# 1.4 Witch month was the best and worst for each coin and each year
WITH returns AS (
	SELECT *
	FROM (
		SELECT date, year, month, day, price, coin,
			ROW_NUMBER() OVER (PARTITION BY year, month, coin ORDER BY day DESC) AS rn
		FROM krypto.btc_eth_sol_avax_dot
	) AS sub
	WHERE rn = 1
), 
monthly_returns AS (
	SELECT *
    FROM (
		SELECT coin, year, month,
			price AS month_end_price,
			LAG(price) OVER(PARTITION BY coin ORDER BY year, month) AS prev_price,
			ROUND((price / LAG(price) OVER(PARTITION BY coin ORDER BY year, month) - 1) * 100, 2) AS 	monthly_return_percent
		FROM returns ) AS sub
	WHERE prev_price IS NOT NULL
),
ranked_best AS (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY coin, year ORDER BY monthly_return_percent DESC) AS rn_best,
		ROW_NUMBER() OVER(PARTITION BY coin, year ORDER BY monthly_return_percent ASC) AS rn_worst
	FROM monthly_returns
)
SELECT coin, year,
	MAX(CASE WHEN rn_best = 1 THEN month END) AS best_month,
    MAX(CASE WHEN rn_best = 1 THEN monthly_return_percent END) AS best_month_in_percent,
    MAX(CASE WHEN rn_worst = 1 THEN month END) AS worst_month,
    MAX(CASE WHEN rn_worst = 1 THEN monthly_return_percent END) AS worst_month_in_percent
FROM ranked_best
GROUP BY coin, year
ORDER BY coin, year
;


## Volatility


# 1.0 Calculating standard deviation of daily returns for each coin
WITH returns AS (
SELECT date, coin, price,
	(price - LAG(price, 1) OVER (PARTITION BY coin ORDER BY date))/(LAG(price, 1) OVER (PARTITION BY coin ORDER BY date)) AS daily_return
FROM krypto.btc_eth_sol_avax_dot
)
SELECT coin,
	COUNT(daily_return) AS n_days,
	AVG(daily_return) AS avg_daily_return,
    STDDEV(daily_return) AS daily_volatility
FROM returns
WHERE daily_return IS NOT NULL
GROUP BY coin
;

# 1.1 Which coin is the most volatile and which is the least
WITH returns AS (
SELECT date, coin, price,
	(price - LAG(price, 1) OVER (PARTITION BY coin ORDER BY date))/(LAG(price, 1) OVER (PARTITION BY coin ORDER BY date)) AS daily_return
FROM krypto.btc_eth_sol_avax_dot
),
cte AS (
SELECT coin,
	COUNT(daily_return) AS n_days,
	AVG(daily_return) AS avg_daily_return,
    STDDEV(daily_return) AS daily_volatility
FROM returns
WHERE daily_return IS NOT NULL
GROUP BY coin
)
SELECT coin, daily_volatility 
FROM cte
WHERE daily_volatility = (SELECT MAX(daily_volatility) FROM cte) -- most_volatility

UNION ALL

SELECT coin, daily_volatility 
FROM cte
WHERE daily_volatility = (SELECT MIN(daily_volatility) FROM cte) -- least_volatility
;


## Correlations


# 1.0 Calculating Pearson corolation between BTC and ETH
WITH returns AS (
SELECT date, coin, price,
	(price - LAG(price, 1) OVER (PARTITION BY coin ORDER BY date))/(LAG(price, 1) OVER (PARTITION BY coin ORDER BY date)) AS daily_return
FROM krypto.btc_eth_sol_avax_dot
WHERE coin IN ('Bitcoin', 'ETH')
),
vol1 AS (
SELECT r1.date, 
	r1.daily_return AS btc_return,
    r2.daily_return AS eth_return
FROM returns AS r1
JOIN returns AS r2
	ON r1.date = r2.date
WHERE r1.coin = 'Bitcoin'
	AND	r2.coin = 'ETH'
    AND r1.daily_return IS NOT NULL
    AND r2.daily_return IS NOT NULL
),
vol2 AS (
SELECT 
	AVG(btc_return) AS avg_btc_return,
    AVG(eth_return) AS avg_eth_return,
    STDDEV(btc_return) AS std_btc,
    STDDEV(eth_return) AS std_eth
FROM vol1
),
vol3 AS (
SELECT AVG((btc_return - avg_btc_return) * (eth_return - avg_eth_return)) AS cov_xy
FROM vol1 v1
CROSS JOIN vol2 v2
)
SELECT cov_xy / (std_btc * std_eth) AS p_btc_eth
FROM vol2 AS v2
CROSS JOIN vol3 AS v3
;

# 1.1 Calculating Pearson corolation between BTC with DOT, AVAX, SOL
WITH returns AS (
SELECT date, coin, year, month, price,
	LAG(price, 1) OVER(PARTITION BY coin ORDER BY date) AS prev_price,
    ((price / LAG(price, 1) OVER(PARTITION BY coin ORDER BY date)) - 1) AS daily_return
FROM krypto.btc_eth_sol_avax_dot
WHERE coin IN ('Bitcoin', 'AVAX', 'PolkaDot', 'Solana')
),
vol1 AS (
SELECT date,
	MAX(CASE WHEN coin = 'Bitcoin' THEN daily_return END) AS btc_daily_return,
    MAX(CASE WHEN coin = 'AVAX' THEN daily_return END) AS avax_daily_return,
    MAX(CASE WHEN coin = 'PolkaDot' THEN daily_return END) AS dot_daily_return,
    MAX(CASE WHEN coin = 'Solana' THEN daily_return END) AS sol_daily_return
FROM returns
GROUP BY date
ORDER BY date
),
vol2 AS (
SELECT 
	AVG(btc_daily_return) AS avg_btc_return,
    AVG(avax_daily_return) AS avg_avax_return,
    AVG(dot_daily_return) AS avg_dot_return,
    AVG(sol_daily_return) AS avg_sol_return,
    STDDEV(btc_daily_return) AS std_btc,
    STDDEV(avax_daily_return) AS std_avax,
    STDDEV(dot_daily_return) AS std_dot,
    STDDEV(sol_daily_return) AS std_sol
FROM vol1
),
vol3 AS (
SELECT 
	AVG((btc_daily_return - avg_btc_return) * (avax_daily_return - avg_avax_return)) AS cov_btc_avax,
    AVG((btc_daily_return - avg_btc_return) * (dot_daily_return - avg_dot_return)) AS cov_btc_dot,
    AVG((btc_daily_return - avg_btc_return) * (sol_daily_return - avg_sol_return)) AS cov_btc_sol
FROM vol2
CROSS JOIN vol1
)
SELECT 
	cov_btc_avax / (std_btc * std_avax) AS p_btc_avax,
    cov_btc_dot / (std_btc * std_dot) AS p_btc_dot,
    cov_btc_sol / (std_btc * std_sol) AS p_btc_sol
FROM vol3
CROSS JOIN vol2
;

# 1.2 Calculating Pearson corolation between BTC with ETH, DOT, AVAX, SOL
WITH returns AS (
SELECT date, coin, year, month, price,
	LAG(price, 1) OVER(PARTITION BY coin ORDER BY date) AS prev_price,
    ((price / LAG(price, 1) OVER(PARTITION BY coin ORDER BY date)) - 1) AS daily_return
FROM krypto.btc_eth_sol_avax_dot
-- WHERE coin IN ('Bitcoin', 'AVAX', 'PolkaDot', 'Solana')
),
vol1 AS (
SELECT date,
	MAX(CASE WHEN coin = 'Bitcoin' THEN daily_return END) AS btc_daily_return,
    MAX(CASE WHEN coin = 'ETH' THEN daily_return END) AS eth_daily_return,
    MAX(CASE WHEN coin = 'AVAX' THEN daily_return END) AS avax_daily_return,
    MAX(CASE WHEN coin = 'PolkaDot' THEN daily_return END) AS dot_daily_return,
    MAX(CASE WHEN coin = 'Solana' THEN daily_return END) AS sol_daily_return
FROM returns
GROUP BY date
ORDER BY date
),
vol2 AS (
SELECT 
	AVG(btc_daily_return) AS avg_btc_return,
    AVG(eth_daily_return) AS avg_eth_return,
    AVG(avax_daily_return) AS avg_avax_return,
    AVG(dot_daily_return) AS avg_dot_return,
    AVG(sol_daily_return) AS avg_sol_return,
    STDDEV(btc_daily_return) AS std_btc,
    STDDEV(eth_daily_return) AS std_eth,
    STDDEV(avax_daily_return) AS std_avax,
    STDDEV(dot_daily_return) AS std_dot,
    STDDEV(sol_daily_return) AS std_sol
FROM vol1
),
vol3 AS (
SELECT 
	AVG((btc_daily_return - avg_btc_return) * (eth_daily_return - avg_eth_return)) AS cov_btc_eth,
	AVG((btc_daily_return - avg_btc_return) * (avax_daily_return - avg_avax_return)) AS cov_btc_avax,
    AVG((btc_daily_return - avg_btc_return) * (dot_daily_return - avg_dot_return)) AS cov_btc_dot,
    AVG((btc_daily_return - avg_btc_return) * (sol_daily_return - avg_sol_return)) AS cov_btc_sol
FROM vol2
CROSS JOIN vol1
)
SELECT 
	cov_btc_eth / (std_btc * std_eth) AS p_btc_eth,
	cov_btc_avax / (std_btc * std_avax) AS p_btc_avax,
    cov_btc_dot / (std_btc * std_dot) AS p_btc_dot,
    cov_btc_sol / (std_btc * std_sol) AS p_btc_sol
FROM vol3
CROSS JOIN vol2
;


## Biggest Price Movements


# 1.0 Checking te largest one-day increases fo coins
WITH vol1 AS (
SELECT date, coin, price,
	LAG(price, 1) OVER(PARTITION BY coin ORDER BY date) AS prev_price,
    ROUND(((price / LAG(price, 1) OVER(PARTITION BY coin ORDER BY date)) - 1) * 100, 2) AS daily_return_perc
FROM krypto.btc_eth_sol_avax_dot
),
vol2 AS (
SELECT date, coin, daily_return_perc,
	ROW_NUMBER() OVER(PARTITION BY coin ORDER BY daily_return_perc DESC) AS row_num
FROM vol1
)
SELECT date, coin, daily_return_perc
FROM vol2
WHERE row_num = 1
;

# 1.1 Checking te largest one-day drop fo coins
WITH vol1 AS (
SELECT date, coin, price,
	LAG(price, 1) OVER(PARTITION BY coin ORDER BY date) AS prev_price,
    ROUND(((price / LAG(price, 1) OVER(PARTITION BY coin ORDER BY date)) - 1) * 100, 2) AS daily_return_perc
FROM krypto.btc_eth_sol_avax_dot
),
vol2 AS (
SELECT date, coin, daily_return_perc,
	ROW_NUMBER() OVER(PARTITION BY coin ORDER BY daily_return_perc ASC) AS row_num
FROM vol1
)
SELECT date, coin, daily_return_perc
FROM vol2
WHERE row_num = 2
;

# 1.2 How many times in each year did coin had return more than 10%?
WITH vol1 AS (
SELECT date, coin, price, year,
	LAG(price, 1) OVER(PARTITION BY coin ORDER BY date) AS prev_price,
    ROUND(((price / LAG(price, 1) OVER(PARTITION BY coin ORDER BY date)) - 1) * 100, 2) AS daily_return_perc
FROM krypto.btc_eth_sol_avax_dot
)
SELECT coin, year, COUNT(*) AS num_days_over_10perc
FROM vol1
WHERE daily_return_perc > 10 OR daily_return_perc < -10
GROUP BY coin, year
ORDER BY coin, year;


## Additional Analysis


# 1.0 Every coin average trading volume in each year
SELECT coin, year,
	ROUND(AVG(total_volume), 2) AS avg_volume
FROM krypto.btc_eth_sol_avax_dot
GROUP BY coin, year
ORDER BY coin, year
;

# 1.1 Which coin more often follow trend of BTC (on the same day)
WITH returns AS (
    SELECT 
        date, coin, price,
        LAG(price, 1) OVER(PARTITION BY coin ORDER BY date) AS prev_price,
        (price / LAG(price, 1) OVER(PARTITION BY coin ORDER BY date) - 1) AS daily_return
    FROM krypto.btc_eth_sol_avax_dot
),
vol1 AS (
    SELECT 
        date,
        MAX(CASE WHEN coin = 'Bitcoin'  THEN daily_return END) AS btc_ret,
        MAX(CASE WHEN coin = 'ETH'      THEN daily_return END) AS eth_ret,
        MAX(CASE WHEN coin = 'AVAX'     THEN daily_return END) AS avax_ret,
        MAX(CASE WHEN coin = 'PolkaDot' THEN daily_return END) AS dot_ret,
        MAX(CASE WHEN coin = 'Solana'   THEN daily_return END) AS sol_ret
    FROM returns
    GROUP BY date
),
flags AS (
    SELECT
        date,
        CASE WHEN btc_ret IS NULL OR eth_ret IS NULL  OR btc_ret = 0 OR eth_ret = 0  THEN NULL
             WHEN btc_ret * eth_ret  > 0 THEN 1 ELSE 0 END AS same_btc_eth,
        CASE WHEN btc_ret IS NULL OR avax_ret IS NULL OR btc_ret = 0 OR avax_ret = 0 THEN NULL
             WHEN btc_ret * avax_ret > 0 THEN 1 ELSE 0 END AS same_btc_avax,
        CASE WHEN btc_ret IS NULL OR dot_ret IS NULL  OR btc_ret = 0 OR dot_ret = 0  THEN NULL
             WHEN btc_ret * dot_ret  > 0 THEN 1 ELSE 0 END AS same_btc_dot,
        CASE WHEN btc_ret IS NULL OR sol_ret IS NULL  OR btc_ret = 0 OR sol_ret = 0  THEN NULL
             WHEN btc_ret * sol_ret  > 0 THEN 1 ELSE 0 END AS same_btc_sol
    FROM vol1
)
SELECT
    'ETH'  AS coin, ROUND(AVG(same_btc_eth) * 100, 2)  AS pct_same_dir,
    COUNT(same_btc_eth) AS n_days
FROM flags
UNION ALL
SELECT
    'AVAX', ROUND(AVG(same_btc_avax) * 100, 2), COUNT(same_btc_avax)
FROM flags
UNION ALL
SELECT
    'DOT',  ROUND(AVG(same_btc_dot) * 100, 2),  COUNT(same_btc_dot)
FROM flags
UNION ALL
SELECT
    'SOL',  ROUND(AVG(same_btc_sol) * 100, 2),  COUNT(same_btc_sol)
FROM flags
ORDER BY coin;

# 1.2 Sharp ratio
WITH returns AS (
SELECT date, coin, price,
	(price - LAG(price, 1) OVER (PARTITION BY coin ORDER BY date))/(LAG(price, 1) OVER (PARTITION BY coin ORDER BY date)) AS daily_return
FROM krypto.btc_eth_sol_avax_dot
),
sharp_ratio AS (
SELECT coin,
	COUNT(daily_return) AS n_days,
	AVG(daily_return) AS avg_daily_return,
    STDDEV(daily_return) AS daily_volatility
FROM returns
WHERE daily_return IS NOT NULL
GROUP BY coin
)
SELECT coin, n_days,
	(avg_daily_return - 0) / daily_volatility AS daily_sharp_ratio,
    (avg_daily_return - 0) / daily_volatility * SQRT(252) AS annual_sharpe_ratio
FROM sharp_ratio
;
    
 





