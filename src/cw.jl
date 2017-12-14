#---------------------------------------
# Imports
#---------------------------------------

import JSON
import Requests

#---------------------------------------
# Constants
#---------------------------------------

COINMARKETCAP_API_URL = "https://api.coinmarketcap.com"

# Indentation (in number of spaces) to use when writing the json wallet file.
JSON_INDENT = 2

# Name of the wallet file.
WALLET_FILENAME = "wallet.json"

#---------------------------------------
# Types
#---------------------------------------

mutable struct ApiCoin
  name::AbstractString
  ticker::AbstractString
  priceusd::Float64
  pricesek::Float64
  percentchange24h::Float64
end

struct WalletCoin
  name::AbstractString
  amount::Float64
end

struct Wallet
  coins::Array{WalletCoin}
end

mutable struct Model
  coindata::Dict{AbstractString, ApiCoin}
  wallet::Wallet
end

struct BuyCmd
  coinname::AbstractString
  amount::Float64
end

struct SellCmd
  coinname::AbstractString
  amount::Float64
end

struct HelpCmd
end

struct NoOpCmd
end

struct DisplayWalletCmd
end

struct SpeculateCmd
  coinname::AbstractString
  priceusd::Float64
end

struct FilterWalletCmd
  coinnames::Array{String}
end

struct TableCell
  text::AbstractString
  align::Symbol
  minsize::Int
  padding::Int
end

struct TableRow
  cells::Array{TableCell}
end

struct Table
  titleleft::AbstractString
  titlecenter::AbstractString
  titleright::AbstractString
  header::TableRow
  rows::Array{TableRow}
  footer::TableRow
end

#---------------------------------------
# Functions
#---------------------------------------

function coinmarketcap(endpoint; params=nothing, version="v1")
  url = "$COINMARKETCAP_API_URL/$version/$endpoint"

  if params != nothing
    url *= "?" * join(["$(p.first)=$(p.second)" for p in params], "&")
  end

  resp = Requests.get(url)
  JSON.parse(IOBuffer(resp.data))
end

function getcoindata(name)
  const FIELD_MAP = Dict([
    :name             => "name"
    :percentchange24h => "percent_change_24h"
    :priceusd         => "price_usd"
    :pricesek         => "price_sek"
    :ticker           => "id"
  ])

  data = coinmarketcap("ticker/$name", params=Dict("convert" => "SEK"))[1]

  values = []
  for (s, t) in zip(fieldnames(ApiCoin), ApiCoin.types)
    value = data[FIELD_MAP[s]]
    if t != AbstractString
      value = parse(t, data[FIELD_MAP[s]])
    end

    push!(values, value)
  end

  ApiCoin(values...)
end

function coinexists(name)
  data = coinmarketcap("ticker/$name")
  !(isa(data, Dict) && haskey(data, "error"))
end

function loadwallet(filename)
  # See https://github.com/JuliaIO/JSON.jl/issues/155 regarding use_mmap=false.
  walletdata = JSON.parsefile(filename, use_mmap=false)

  fields  = fieldnames(WalletCoin) .|> string
  tocoin = t -> WalletCoin([t[s] for s in fields]...)
  coins  = walletdata["coins"] .|> tocoin

  Wallet(coins)
end

function savewallet(wallet, filename)
  open(filename, "w") do f
    JSON.print(f, wallet, JSON_INDENT)
  end
end

function printtable(table)
  cellsize = cell -> max(length(cell.text), cell.minsize) + 2cell.padding
  colwidths = table.header.cells .|> cellsize

  for row in table.rows
    @assert length(row.cells) == length(colwidths)

    for i in 1:length(row.cells)
      cell = row.cells[i]
      colwidths[i] = max(colwidths[i], cell |> cellsize)
    end
  end

  @assert length(table.footer.cells) == length(colwidths)
  for i in 1:length(table.footer.cells)
    cell = table.footer.cells[i]
    colwidths[i] = max(colwidths[i], cell |> cellsize)
  end

  printedge = n -> (print("+"); print("-" ^ n); println("+"))
  printdelim = (n, c="-") -> (print("| "); print(c ^ (n - 2)); println(" |"))

  function printtitle(n, l, c, r)
    n -= length(l) + length(c) + length(r)
    print("|")
    print(l)
    print(" " ^ floor(Int, 0.5n))
    print(c)
    print(" " ^ ceil(Int, 0.5n))
    print(r)
    println("|")
   end

  function printaligned(n, s, a)
    print("|")
    n = max(n - length(s), 0)
    if a == :left
      print(s)
      print(" " ^ n)
    elseif a == :right
      print(" " ^ n)
      print(s)
    else
      print(" " ^ floor(Int, 0.5n))
      print(s)
      print(" " ^ ceil(Int, 0.5n))
    end
  end

  function printrow(row)
    for i in 1:length(row.cells)
      cell = row.cells[i]
      text = (" " ^ cell.padding) * cell.text * (" " ^ cell.padding)
      printaligned(colwidths[i], text, cell.align)
    end

    println("|")
  end

  tablewidth = sum(colwidths) + length(table.header.cells) - 1

  indent = () -> print("  ")

  indent(); printedge(tablewidth)
  indent(); printtitle(tablewidth, table.titleleft, table.titlecenter, table.titleright)
  indent(); printedge(tablewidth)
  indent(); printrow(table.header)
  indent(); printdelim(tablewidth)
  for row in table.rows
    indent(); printrow(row)
  end
  indent(); printdelim(tablewidth, "=")
  indent(); printrow(table.footer)
  indent(); printedge(tablewidth)
end

function parseargs(args)
  s = length(args) >= 1 && args[1] |> lowercase

  if s == false
    DisplayWalletCmd()
  elseif s == "-h" || s == "--help"
    HelpCmd()
  elseif s == "buy" && length(args) == 3 # <amount> <coin>
    try
      amount = args[2] |> a -> parse(Float64, a)
      coin   = args[3] |> lowercase

      BuyCmd(coin, amount)
    catch
      HelpCmd()
    end
  elseif s == "sell" && length(args) == 3 # <amount> <coin>
    try
      amount = args[2] |> a -> parse(Float64, a)
      coin   = args[3] |> lowercase

      SellCmd(coin, amount)
    catch
      HelpCmd()
    end
  elseif s == "speculate"
    try
      coin     = args[2] |> lowercase
      priceusd = args[3] |> a -> parse(Float64, a)

      SpeculateCmd(coin, priceusd)
    catch
      HelpCmd()
    end
  elseif s == "only"
    try
      coins = args[2:end] .|> lowercase

      FilterWalletCmd(coins)
    catch
      HelpCmd()
    end
  elseif s == "wallet"
    DisplayWalletCmd()
  else
    HelpCmd()
  end
end

function updatecoindata!(model)
  for coin in model.wallet.coins
    if !haskey(model.coindata, coin.name)
      model.coindata[coin.name] = ApiCoin(coin.name, "", -1.0, 0.0, 0.0)
    end
  end

  function updatecoin!(coindata)
    if coindata.priceusd < 0.0
      tmp = getcoindata(coindata.name)

      coindata.name             = tmp.name
      coindata.ticker           = tmp.ticker
      coindata.priceusd         = tmp.priceusd
      coindata.pricesek         = tmp.pricesek
      coindata.percentchange24h = tmp.percentchange24h
    end
  end

  @sync begin
    for entry in model.coindata
      @async updatecoin!(entry.second)
    end
  end
end

function execute!(buy::BuyCmd, model)
  !coinexists(buy.coinname) && fail("No such coin exists: '$(buy.coinname)'")

  coins = WalletCoin[]

  isnew = true
  for coin in model.wallet.coins
    if coin.name == buy.coinname
      isnew = false
      coin = WalletCoin(coin.name, coin.amount + buy.amount)
    end

    push!(coins, coin)
  end

  if isnew
    coin = WalletCoin(buy.coinname, buy.amount)
    push!(coins, coin)
  end

  model.wallet = Wallet(coins)
  savewallet(model.wallet, WALLET_FILENAME)

  execute!(DisplayWalletCmd(), model)
end

function execute!(sell::SellCmd, model)
  coins = WalletCoin[]

  for coin in model.wallet.coins
    if coin.name == sell.coinname
      coin = WalletCoin(coin.name, coin.amount - sell.amount)
    end

    if coin.amount > 0.0
      push!(coins, coin)
    end
  end

  model.wallet = Wallet(coins)
  savewallet(model.wallet, WALLET_FILENAME)

  execute!(DisplayWalletCmd(), model)
end

function execute!(speculate::SpeculateCmd, model)
  coindata = getcoindata(speculate.coinname)


  op = coindata.priceusd
  np = speculate.priceusd
  ch = coindata.percentchange24h
  coindata.name *= "*"
  coindata.percentchange24h = 100.0(np / ((1.0 - 0.01ch) * op) - 1.0)
  coindata.pricesek = (coindata.pricesek / coindata.priceusd) * speculate.priceusd
  coindata.priceusd = speculate.priceusd

  model.coindata[speculate.coinname] = coindata

  execute!(DisplayWalletCmd(), model)
end

function execute!(filter::FilterWalletCmd, model)
  model.wallet = Wallet([coin for coin in model.wallet.coins
                         if contains((y, x) -> x.name == y, filter.coinnames, coin)])

  execute!(DisplayWalletCmd(), model)
end

function execute!(::HelpCmd, model)
  s = basename(Base.source_path())
  println("Crypto Wallet v1.0")
  println()
  println("Usage:")
  println("  $s")
  println("  $s -h | --help")
  println()
  println("Options:")
  println("  <none>                     Display wallet conents.")
  println("  buy <amount> <coin>        Add investment to wallet.")
  println("  sell <amount> <coin>       Remove investment from wallet.")
  println("  speculate <coin> <price>   Assign speculative price and display wallet.")
  println("  only <coin>[, <coin> ...]  Only display specified coins.")
end

function execute!(::NoOpCmd, model)
  println("nothing to do")
end

function execute!(::DisplayWalletCmd, model)
  titleleft = ""
  titlecenter = "         W A L L E T  D A T A"
  titleright = Dates.format(now(), "d u yyyy HH:MM ")

  header = TableRow([
    TableCell("Altcoin"     , :left , 0, 1)
    TableCell("Price (USD)" , :right, 0, 1)
    #TableCell("Price (SEK)" , :right, 0, 1)
    TableCell("Change (24h)", :right, 0, 1)
    TableCell("Owned"       , :right, 0, 1)
    TableCell("USD"         , :right, 0, 1)
    TableCell("SEK"         , :right, 0, 1)
    TableCell("%"           , :right, 0, 1)
  ])

  insertsep = s -> length(s) < 3 ? s : insertsep(s[1:end-3]) * " " * s[end-2:end]
  fc  = f -> strip(insertsep(string(floor(Int, f))) * "." * @sprintf("%02d", floor(100(f - floor(f)))))
  fp1 = f -> (f < 0.0 ? "-" : "+") * @sprintf("%10.2f%%", abs(f))
  fp2 = f -> @sprintf("%.2f%%", f)

  usdtotal = 0.0
  sektotal = 0.0

  updatecoindata!(model)

  for coin in model.wallet.coins
    coindata = model.coindata[coin.name]

    usdvalue = coin.amount * coindata.priceusd
    sekvalue = coin.amount * coindata.pricesek

    usdtotal += usdvalue
    sektotal += sekvalue
  end

  rows = []
  for coin in sort(model.wallet.coins, by=coin -> coin.name)
    coindata = model.coindata[coin.name]

    usdvalue = coin.amount * coindata.priceusd
    sekvalue = coin.amount * coindata.pricesek

    row = TableRow([
      TableCell(coindata.name |> lowercase    , :left , 0, 1)
      TableCell(fc(coindata.priceusd)         , :right, 0, 1)
      #TableCell(fc(coindata.pricesek)         , :right, 0, 1)
      TableCell(fp1(coindata.percentchange24h), :right, 0, 1)
      TableCell(fc(coin.amount)               , :right, 0, 1)
      TableCell(fc(usdvalue)                  , :right, 0, 1)
      TableCell(fc(sekvalue)                  , :right, 0, 1)
      TableCell(fp2(100usdvalue/usdtotal)     , :right, 0, 1)
    ])

    push!(rows, row)
  end

  footer = TableRow([
    TableCell("Total"     , :left , 0, 1)
    TableCell("-"         , :right, 0, 1)
    #TableCell("-"         , :right, 0, 1)
    TableCell("-"         , :right, 0, 1)
    TableCell("-"         , :right, 0, 1)
    TableCell(fc(usdtotal), :right, 0, 1)
    TableCell(fc(sektotal), :right, 0, 1)
    TableCell("100.00%"   , :right, 0, 1)
  ])

  printtable(Table(titleleft, titlecenter, titleright, header, rows, footer))
end

function fail(reason, exitcode=1)
  println("[ERROR] " * reason)
  exit(exitcode)
end

function main()
  cd(dirname(Base.source_path()))

  cmd = parseargs(ARGS)

  wallet = Wallet([])
  if isfile(WALLET_FILENAME)
    wallet = loadwallet(WALLET_FILENAME)
  end

  model = Model(Dict(), wallet)

  execute!(cmd, model)
end

#---------------------------------------
# Entry Point
#---------------------------------------

!isinteractive() && main()
