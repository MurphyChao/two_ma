//+------------------------------------------------------------------+
//|                                              Moving Averages.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2009-2017, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>

#include <price.mqh>
#include <two_ma.mqh>

input double Lots                  = 0.5;
input double max_risk_percentage   = 0.02;
input double DecreaseFactor        = 3;       // Descrease factor
input int    stop_loss_ticks       = 1000;
input int    take_profit_ticks     = 5000;
input int    sma_period_short      = 5;
input int    sma_period_long       = 20;
input int    diff_ticks            = 100;
input int    sma_diff_ticks        = 50;

int    look_back = 3;
bool   ExtHedging = false;

CTrade ExtTrade;
CSymbolInfo ExtSymbol;

TwoMA two_ma;
Price_t book;

double position = 0;

#define MA_MAGIC 20180605


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(void)
{
    //--- prepare trade class to control positions if hedging mode is active
    ExtTrade.SetExpertMagicNumber(MA_MAGIC);
    ExtTrade.SetMarginMode();
    ExtTrade.SetTypeFillingBySymbol(Symbol());
    //--- symbol info
    ExtSymbol.Name(Symbol());
    //--- ok
    
    two_ma.Init(sma_period_short, sma_period_long);
    
    return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(void)
{
    two_ma.Update();
    CheckForClose();
    CheckForOpen();
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}


//+------------------------------------------------------------------+
//| Check for open position conditions                               |
//+------------------------------------------------------------------+
void CheckForOpen()
{
    MqlRates rt[1];
    //--- go trading only for first ticks of new bar
    if (CopyRates(_Symbol, _Period, 0, 1, rt) != 1)
    {
        Print("CopyRates of ", _Symbol, " failed, no history");
        return;
    }
    //if (rt[0].tick_volume > 1)
    //{
    //    return;
    //}

    //--- check signals
    ENUM_ORDER_TYPE signal = WRONG_VALUE;
    
    if (position == 0)
    {
        if (BuyOpenCondition())
        {
            signal = ORDER_TYPE_BUY;  // buy conditions
        }
        else if (SellOpenCondition())
        {
            signal = ORDER_TYPE_SELL;    // sell conditions
        }
    }
    //--- additional checking
    if (signal != WRONG_VALUE)
    {
        if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) &&
            Bars(_Symbol, _Period) > 100)
        {
            double open = GetPrice(signal);
            double tp = GetTP(signal, open);
            double sl = GetSL(signal, open);
            double lot_size = TradeSizeOptimized();
            
            bool r = ExtTrade.PositionOpen(_Symbol, signal, lot_size,
                    open, sl, tp);
                    
            if (r)
            {
                if (signal == ORDER_TYPE_BUY)
                {
                    position += lot_size;
                }
                else
                {
                    position -= lot_size;
                }
            }
        }
    }
}


bool BuyOpenCondition()
{
    if (two_ma.Bull() && book.iLocalMin(PERIOD_M20, _Period))
    {
        return true;
    }
    else
    {
        return false;
    }
}


bool SellOpenCondition()
{
    if (two_ma.Bear() && book.iLocalMax(PERIOD_M20, _Period))
    {
        return true;
    }
    else
    {
        return false;
    }
}


bool BuyCloseCondition()
{
    if (/*book.iLocalMax(PERIOD_M20, _Period) ||*/
        two_ma.Bull())
    {
        return true;
    }
    else
    {
        return false;
    }
}


bool SellCloseCondition()
{
    if (/*book.iLocalMin(PERIOD_M20, _Period) ||*/
        two_ma.Bear())
    {
        return true;
    }
    else
    {
        return false;
    }
}


//+------------------------------------------------------------------+
//| Check for close position conditions                              |
//+------------------------------------------------------------------+
void CheckForClose()
{
    MqlRates rt[1];
    //--- go trading only for first ticks of new bar
    if (CopyRates(_Symbol, _Period, 0, 1, rt) != 1)
    {
        Print("CopyRates of ", _Symbol, " failed, no history");
        return;
    }
    //if (rt[0].tick_volume > 1)
    //{
    //    return;
    //}

    //--- positions already selected before
    bool signal = false;
    if (position != 0)
    {
        ENUM_ORDER_TYPE order_type = WRONG_VALUE;

        if (position < 0)
        {
            if (BuyCloseCondition())
            {
                signal = true;
            }
        }
        else if (position > 0)
        {
            if (SellCloseCondition())
            {
                signal = true;
            }
        }
        //--- additional checking
        if (signal)
        {
            if (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && Bars(_Symbol, _Period) > 100)
            {
                ExtTrade.PositionClose(_Symbol, 3);
                position = 0;
            }
        }
    }
    //---
}


double GetPrice(ENUM_ORDER_TYPE order_type)
{
    return SymbolInfoDouble(_Symbol, order_type == ORDER_TYPE_SELL ? SYMBOL_BID : SYMBOL_ASK);
}


double GetTP(ENUM_ORDER_TYPE order_type, double price)
{
    return (order_type == ORDER_TYPE_SELL) ?
        price - take_profit_ticks * ExtSymbol.TickSize() :
        price + take_profit_ticks * ExtSymbol.TickSize();
}


double GetSL(ENUM_ORDER_TYPE order_type, double price)
{
    return (order_type == ORDER_TYPE_SELL) ?
        price + stop_loss_ticks * ExtSymbol.TickSize() :
        price - stop_loss_ticks * ExtSymbol.TickSize();
}


//+------------------------------------------------------------------+
//| Filter                  |
//+------------------------------------------------------------------+
bool filter()
{
    return true;
}


//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double TradeSizeOptimized(void)
{
    double price = 0.0;
    double margin = 0.0;
    //--- select lot size
    if (!SymbolInfoDouble(_Symbol, SYMBOL_ASK, price))
    {
        return 0;
    }
    if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1.0, price, margin))
    {
        return 0;
    }
    if (margin <= 0.0)
    {
        return 0;
    }

    double lot = NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_FREE) * max_risk_percentage / margin, 2);
    //--- calculate number of losses orders without a break
    if (DecreaseFactor > 0)
    {
        //--- select history for access
        HistorySelect(0, TimeCurrent());
        //---
        int    orders = HistoryDealsTotal();  // total history deals
        int    losses = 0;                    // number of losses orders without a break

        for (int i = orders - 1; i >= 0; --i)
        {
            ulong ticket = HistoryDealGetTicket(i);
            if (ticket == 0)
            {
                Print("HistoryDealGetTicket failed, no trade history");
                break;
            }
            //--- check symbol
            if (HistoryDealGetString(ticket, DEAL_SYMBOL)!=_Symbol)
                continue;
            //--- check Expert Magic number
            if (HistoryDealGetInteger(ticket, DEAL_MAGIC)!=MA_MAGIC)
                continue;
            //--- check profit
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if (profit > 0.0)
                break;
            if (profit < 0.0)
                losses++;
        }
        //---
        if (losses > 1)
            lot = NormalizeDouble(lot-lot*losses/DecreaseFactor, 1);
    }
    //--- normalize and check limits
    double stepvol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    lot = stepvol*NormalizeDouble(lot/stepvol, 0);

    double minvol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    if (lot < minvol)
        lot = minvol;

    double maxvol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    if (lot > maxvol)
        lot = maxvol;
    //--- return trading volume
    return(Lots);
}

