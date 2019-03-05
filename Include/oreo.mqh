//+------------------------------------------------------------------+
//|                                                       murphy.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"


class Oreo
{
public:
    Oreo();
    ~Oreo();
    
    bool IsBullCandle(ENUM_TIMEFRAMES tf, int index);
    bool IsBearCandle(ENUM_TIMEFRAMES tf, int index);
    bool Bull(ENUM_TIMEFRAMES tf);
    bool Bear(ENUM_TIMEFRAMES tf);
    double GetTP(ENUM_ORDER_TYPE side, double open_price);
    double GetSL(ENUM_ORDER_TYPE side);
};


Oreo::Oreo()
{
}


Oreo::~Oreo()
{
}


bool Oreo::IsBullCandle(ENUM_TIMEFRAMES tf, int index)
{
    if (iClose(_Symbol, tf, index) > iOpen(_Symbol, tf, index))
    {
        return true;
    }
    else
    {
        return false;
    }
}


bool Oreo::IsBearCandle(ENUM_TIMEFRAMES tf, int index)
{
    if (iClose(_Symbol, tf, index) < iOpen(_Symbol, tf, index))
    {
        return true;
    }
    else
    {
        return false;
    }
}


bool Oreo::Bull(ENUM_TIMEFRAMES tf)
{
    MqlTick last_price;
    SymbolInfoTick(Symbol(), last_price);
    if (IsBullCandle(tf, 3) && IsBullCandle(tf, 2) &&
        IsBearCandle(tf, 1) && iClose(_Symbol, tf, 1) > iOpen(_Symbol, tf, 2) &&
        last_price.bid > iOpen(_Symbol, tf, 1))
    {
        printf("Found Bull oreo");
        return true;
    }
    else
    {
        return false;
    }
}


bool Oreo::Bear(ENUM_TIMEFRAMES tf)
{
    MqlTick last_price;
    SymbolInfoTick(_Symbol, last_price);
    if (IsBearCandle(tf, 3) && IsBearCandle(tf, 2) &&
        IsBullCandle(tf, 1) && iClose(_Symbol, tf, 1) < iOpen(_Symbol, tf, 2) &&
        last_price.ask < iOpen(_Symbol, tf, 1))
    {
        printf("Found Bear oreo");
        return true;
    }
    else
    {
        return false;
    }
}


double Oreo::GetTP(ENUM_ORDER_TYPE side, double open_price)
{
    double range = iHigh(_Symbol, _Period, 1) - iLow(_Symbol, _Period, 1);
    if (side == ORDER_TYPE_BUY)
    {
        return open_price + range;
    }
    else
    {
        return open_price - range;
    }
}


double Oreo::GetSL(ENUM_ORDER_TYPE side)
{
    if (side == ORDER_TYPE_BUY)
    {
        return iLow(_Symbol, _Period, 1);
    }
    else
    {
        return iHigh(_Symbol, _Period, 1);
    }
}


