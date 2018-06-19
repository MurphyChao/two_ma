//+------------------------------------------------------------------+
//|                                                       murphy.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"


class Price_t
{
public:
    Price_t();
    ~Price_t();
    
    double iClose(string symbol, ENUM_TIMEFRAMES tf, int index);
    bool iLocalMin(ENUM_TIMEFRAMES tf_short, ENUM_TIMEFRAMES tf_long);
    bool iLocalMax(ENUM_TIMEFRAMES tf_short, ENUM_TIMEFRAMES tf_long);
};


Price_t::Price_t()
{
}


Price_t::~Price_t()
{
}


double Price_t::iClose(string symbol, ENUM_TIMEFRAMES tf, int index)
{
    if (index < 0)
    {
        return(-1);
    }
    double Arr[];
    if (CopyClose(symbol, tf, index, 1, Arr) > 0)
    {
        return(Arr[0]);
    }
    else
    {
        return(-1);
    }
}


bool Price_t::iLocalMin(ENUM_TIMEFRAMES tf_short, ENUM_TIMEFRAMES tf_long)
{
    if (iClose(_Symbol, tf_short, 2) > iClose(_Symbol, tf_long, 1) &&
        iClose(_Symbol, tf_short, 1) < iClose(_Symbol, tf_long, 1))
    {
        return true;
    }
    else
    {
        return false;
    }
}


bool Price_t::iLocalMax(ENUM_TIMEFRAMES tf_short, ENUM_TIMEFRAMES tf_long)
{
    if (iClose(_Symbol, tf_short, 2) < iClose(_Symbol, tf_long, 1) &&
        iClose(_Symbol, tf_short, 1) > iClose(_Symbol, tf_long, 1))
    {
        return true;
    }
    else
    {
        return false;
    }
}

