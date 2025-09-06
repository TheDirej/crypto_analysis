# Cryptocurrency Data Analysis Project

## Project Overview
This project analyses historical data for **five major cryptocurrencies**: **Bitcoin (BTC), Ethereum (ETH), Solana (SOL), Avalanche (AVAX), and Polkadot (DOT)**.  
The goal of the project is to compare their performance and risk metrics through a structured SQL workflow including **data cleaning, descriptive statistics, volatility analysis, correlations, and biggest price movements**.

The dataset was standardized to ensure consistent column formats (e.g., unified `Date` field, renamed columns).  
The project is designed to simulate **real-world financial analysis** that can later be visualized in tools like Power BI or Tableau.

## Repository Structure
- `krypto_analysis.sql` — SQL script containing the full workflow (data cleaning, returns, volatility, correlations, and price movement analysis).  
- `README.md` — this file, summarizing the project, data source, and usage instructions.

## Data Source
The data was collected from **[CoinMarketCap](https://coinmarketcap.com/)**, a publicly available and widely used cryptocurrency data provider.  
It contains daily prices, trading volumes, and other key metrics for the selected cryptocurrencies.

## How to Use
1. Import the dataset into your SQL environment (e.g., MySQL Workbench).  
2. Run the `krypto_analysis.sql` script step by step.  
   - Sections are marked with comments (`## Step Title`, `# Task`).  
   - Queries cover both **exploratory** and **advanced financial metrics**.  
3. (Optional) Export results for visualization in BI tools such as Tableau or Power BI.  

## Key Insights
- Bitcoin had the highest average trading volume, while smaller coins like Avalanche and Polkadot showed more extreme daily returns.  
- Volatility analysis showed **Solana** as one of the most volatile assets, while **Bitcoin** remained relatively stable.  
- Correlation analysis revealed that **Ethereum tracks Bitcoin’s trend most closely**, while Polkadot and Avalanche often diverge.  
- Extreme price movements (±10% daily returns) occur more frequently in smaller-cap cryptocurrencies than in Bitcoin.  
- Sharpe ratio comparison indicates which coins historically provided a better **risk-adjusted return**.  

## Contact
For questions, feedback, or collaboration ideas, feel free to reach out.
