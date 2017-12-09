![](https://img.shields.io/github/license/philiparvidsson/Crypto-Wallet.svg)

# What is this?

When I started actively investing/speculating in cryptocurrencies, I wanted a simple tool to keep track of the values of my investments. I came up with a script that downloads the latest ticker data from [CoinMarketCap](https://coinmarketcap.com/) and prints my cryptocurrency investments neatly in a simple table.

**NOTE: This is NOT an actual wallet—it does not manage your investments, it cannot transfer money and it has no access to your private keys. It only gives you an overview of your current investments!**

## Running the script

### Prerequisites
* [Julia](https://julialang.org/) — *A high-level dynamic programming language designed to address the needs of high-performance numerical analysis and computational science*

### Instructions

Begin by addning your investments: Invoke the script with the `buy` command: `julia cw.jl buy 1.0 bitcoin`. The script will now add 1 Bitcoin to the wallet and display your wallet contents.
