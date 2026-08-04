# 📈 Cryptocurrency Financial Risk & Trend Alignment Analysis (SQL)

**Author:** Damian Sobolewski  
**Tools:** MySQL Workbench, Advanced SQL (CTEs, Window Functions, Pearson Correlation)  
**Domain:** Financial Analytics, Volatility & Portfolio Risk  

---

## 📌 Executive Summary
This project delivers a deep-dive financial performance and risk analysis of **five major cryptocurrencies**: **Bitcoin (BTC), Ethereum (ETH), Solana (SOL), Avalanche (AVAX), and Polkadot (DOT)**. 

Using raw daily transaction logs, the analysis evaluates temporal stabilities, volatility, Sharpe Ratios, asset directional alignment with Bitcoin, and custom-calculated **Pearson Correlation Coefficients** directly in SQL.

---

## 🛠️ Applied SQL Engineering & Statistical Methods
- **Advanced Temporal Windowing:** Utilized `LAG()` and `ROW_NUMBER()` over partitioned partitions to construct daily, monthly, and seasonal returns.
- **Directional Trend Alignment:** Engineed Boolean math flags (`CASE WHEN ret_A * ret_B > 0`) to track directional daily coin tracking against Bitcoin.
- **Manual Pearson Correlation:** Built a multi-stage CTE pipeline calculating Covariance over Standard Deviations directly in MySQL.
- **Risk-Adjusted Performance:** Calculated **Annualized Sharpe Ratios** ($\frac{\text{Mean Daily Return}}{\text{Volatility}} \times \sqrt{252}$) to isolate true risk-adjusted performance.

---

## 🔍 Key Findings & Financial Insights

1. **Risk-Adjusted Efficiency (Sharpe Ratio):**
   - **Bitcoin (BTC)** maintained the highest baseline stability, absorbing market shocks with lower overall daily volatility.
   - Altcoins like **Solana (SOL)** showed significantly larger daily price spikes ($>10\%$), offering higher returns but at elevated volatility penalties.
2. **Directional Co-Movement (BTC Tracking):**
   - **Ethereum (ETH)** tracks Bitcoin's daily market directional trajectory most consistently ($>80\%$ of days moving in the exact same direction).
   - **Polkadot (DOT)** and **Avalanche (AVAX)** exhibit higher divergence rates, offering better potential for portfolio diversification.
3. **Volatility Spikes:**
   - Single-day movements exceeding $\pm10\%$ occur with notably higher frequency in lower-cap assets compared to BTC and ETH.

---

## 💻 Featured SQL Code Snippet

### 1. Daily Trend Directional Tracking (BTC vs Altcoins)
*Extracts how often altcoins follow Bitcoin's daily trend on the same trading day:*

```sql
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
SELECT 'ETH' AS coin, ROUND(AVG(same_btc_eth) * 100, 2) AS pct_same_dir, COUNT(same_btc_eth) AS n_days FROM flags
UNION ALL
SELECT 'AVAX', ROUND(AVG(same_btc_avax) * 100, 2), COUNT(same_btc_avax) FROM flags
UNION ALL
SELECT 'DOT',  ROUND(AVG(same_btc_dot) * 100, 2),  COUNT(same_btc_dot)  FROM flags
UNION ALL
SELECT 'SOL',  ROUND(AVG(same_btc_sol) * 100, 2),  COUNT(same_btc_sol)  FROM flags
ORDER BY coin;
```

---

## 📬 Contact
- **Author:** Damian Sobolewski
- **LinkedIn:** [Damian Sobolewski Profile](https://www.linkedin.com/in/damian-sobolewski-43257a260/)
