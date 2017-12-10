![](https://img.shields.io/github/license/philiparvidsson/Crypto-Wallet.svg)

# What is this?

When I started actively investing/speculating in cryptocurrencies, I wanted a simple tool to keep track of the values of my investments. I came up with a script that downloads the latest ticker data from [CoinMarketCap](https://coinmarketcap.com/) and prints my cryptocurrency investments neatly in a simple table.

**NOTE: This is NOT an actual wallet—it does not manage your investments, it cannot transfer money and it has no access to your private keys. It only gives you an overview of your current investments!**

## Running the script

### Prerequisites
* [Julia](https://julialang.org/) — *A high-level dynamic programming language designed to address the needs of high-performance numerical analysis and computational science*

### Installation

The script depends on the [Requests](https://github.com/JuliaWeb/Requests.jl) package to function properly, so it must be installed first:

`julia> Pkg.add("Requests")`

### Instructions

#### Adding coins to your wallet

Invoke the script with the *buy* command to add coins to your wallet. For example, if you own 0.5 Bitcoin, add it to your wallet by typing `julia cw.jl buy 0.5 bitcoin`. The script will add 0.5 bitcoin to your wallet, save it and display your wallet contents:

![](img/cw-buy.png)
