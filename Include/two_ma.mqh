//+------------------------------------------------------------------+
//|                                                       two_ma.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"


class TwoMA
{
public:
    TwoMA();
    ~TwoMA();
    void Init(int period_short, int period_long);
    void Update();
    
    bool Bull();
    bool Bear();
    bool GoldenCross();
    bool DeathCross();

private:
    int sma_short_handle;
    int sma_long_handle;
    
    double sma_short[3];
    double sma_long[3];
};


TwoMA::TwoMA()
{
}


TwoMA::~TwoMA()
{
}


void TwoMA::Init(int period_short, int period_long)
{
    //--- Moving Average indicator
    sma_short_handle = iMA(_Symbol, _Period, period_short, 0, MODE_SMA, PRICE_CLOSE);
    sma_long_handle = iMA(_Symbol, _Period, period_long, 0, MODE_SMA, PRICE_CLOSE);
    if (sma_long_handle == INVALID_HANDLE)
    {
        printf("Error creating MA indicator");
    }
    if (sma_short_handle == INVALID_HANDLE)
    {
        printf("Error creating MA indicator");
    }
}


void TwoMA::Update()
{
    if (CopyBuffer(sma_short_handle, 0, 0, 3, sma_short) != 3)
    {
        Print("CopyBuffer from iMA failed, no data");
        return;
    }
    if (CopyBuffer(sma_long_handle, 0, 0, 3, sma_long) != 3)
    {
        Print("CopyBuffer from iMA failed, no data");
        return;
    }
}


bool TwoMA::Bull()
{
    bool r = false;
    
    if (sma_short[1] > sma_long[1])
    {
        r = true;
    }
    else
    {
        r = false;
    }
    
    return r;
}


bool TwoMA::Bear()
{
    bool r = false;
    
    if (sma_short[1] < sma_long[1])
    {
        r = true;
    }
    else
    {
        r = false;
    }
    
    return r;
}


bool TwoMA::GoldenCross()
{
    bool r = false;
    
    if (sma_short[0] < sma_long[0] && sma_short[1] > sma_long[1])
    {
        r = true;
    }
    else
    {
        r = false;
    }
    
    return r;
}


bool TwoMA::DeathCross()
{
    bool r = false;
        
    if (sma_short[0] > sma_long[0] && sma_short[1] < sma_long[1])
    {
        r = true;
    }
    else
    {
        r = false;
    }
    
    return r;
}



