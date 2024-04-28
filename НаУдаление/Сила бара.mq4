//+------------------------------------------------------------------+
//|                                                      Имрульс.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot СилаБара
#property indicator_label1  "СилаБара"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWheat
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//string         Символ;              //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
extern int     КолБаров = 2;        //Кол-во баров в эспирации //1

//--- indicator buffers
double         СилаБараBuffer[];

bool     старт;
string   short_name;
int      wind_ex;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,СилаБараBuffer);

   short_name=WindowExpertName()+"("+string(КолБаров)+"))";
   IndicatorShortName(short_name);
   
   long handle=ChartID();
   if(handle>0) // если получилось, дополнительно настроим
     {IndicatorDigits(Digits);
      //--- Установка периода графика
      //ChartSetSymbolPeriod(0,NULL,Период);
//      if (!ChartSetSymbolPeriod(0,Символ,Период)) 
  //       ChartSetSymbolPeriod(0,NULL,Период);
      
      //--- сброс значения ошибки
      ResetLastError();
      //--- установка значения приближеня/отдаления графика (дальше(0)-ближе(5))
      ChartSetInteger(handle,CHART_SCALE,0,5);

      //--- сброс значения ошибки
      ResetLastError();
      //--- отображение в виде свечей
      ChartSetInteger(handle,CHART_MODE,CHART_CANDLES);
     }
   
   старт=true;   
   
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   wind_ex=WindowFind(short_name);
   if(wind_ex>0)
      ObjectsDeleteAll(wind_ex);
  }
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(старт) {
/*      {if(Symbol()!=Символ || Period()!=Период)
         {OnInit(); 
          return(0);
         }
*/       
       Старт();
       if(wind_ex<0)
         return(rates_total);
       старт=False;
   }
   
   if(Bars<КолБаров)
      return(rates_total);
      
   if(prev_calculated>0){
      for(int bar=rates_total-prev_calculated; bar>0; bar--)   
         // Расчёт индикатора
         //СилаБараBuffer[bar]=NormalizeDouble(СредняяVolume(bar,КолБаров)*(HighMax(bar,КолБаров)-LowMin(bar,КолБаров)+Close[bar]-Open[bar+КолБаров-1])/Period(),Digits);
//         if(СилаБараBuffer[bar+1]==0.0)
  //          СилаБараBuffer[bar]=1;
    //     else
            СилаБараBuffer[bar]=NormalizeDouble(СредняяVolume(bar,КолБаров)*(HighMax(bar,КолБаров)-LowMin(bar,КолБаров)+Close[bar]-Open[bar+КолБаров-1])/Period(),Digits);
   } else 
      //СилаБараBuffer[0]=NormalizeDouble(СредняяVolume(0,КолБаров)*(HighMax(0,КолБаров)-LowMin(0,КолБаров)+Close[0]-Open[КолБаров-1])/Period(),Digits);
//      if(СилаБараBuffer[1]==0.0)
  //       СилаБараBuffer[0]=1;
    //  else
         СилаБараBuffer[0]=NormalizeDouble(СредняяVolume(0,КолБаров)*(HighMax(0,КолБаров)-LowMin(0,КолБаров)+Close[0]-Open[КолБаров-1])/Period(),Digits);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
  
//+------------------------------------------------------------------+
//| Расчёт начальных параметров                                      |
//+------------------------------------------------------------------+
bool Старт()
  { 
   wind_ex=WindowFind(short_name);
//----
   if(wind_ex<0)
      return false;
      
//---Начальное заполнение массивов
   ArraySetAsSeries(СилаБараBuffer,True);
   
   for(int bar=Bars-1; bar>Bars-КолБаров; bar--){
      СилаБараBuffer[bar]=0.0;
   }
   //for(int bar=Bars-КолБаров-1; bar>0; bar--)
   for(int bar=Bars-КолБаров; bar>0; bar--){
      // Расчёт индикатора
//      if(СилаБараBuffer[bar+1]==0.0)
  //       СилаБараBuffer[bar]=1;
    //  else
 //        double d=СилаБараBuffer[bar+1];
   //      double d1=NormalizeDouble(СредняяVolume(bar,КолБаров)*(HighMax(bar,КолБаров)-LowMin(bar,КолБаров)+MathAbs(Close[bar]-Open[bar+КолБаров-1]))/Period(),Digits);
         СилаБараBuffer[bar]=NormalizeDouble(СредняяVolume(bar,КолБаров)*(HighMax(bar,КолБаров)-LowMin(bar,КолБаров)+MathAbs(Close[bar]-Open[bar+КолБаров-1]))/Period(),Digits);
   }
//--- перерисуем график    
   ChartRedraw();
   
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double СредняяVolume(int bar, int Кол_во )
  {
   int сумма=0;
   for(int i=0;i<Кол_во;i++)
      сумма+=int(Volume[bar+i]);
   
   return NormalizeDouble(сумма/Кол_во,0);
  } 

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double HighMax(int bar, int Кол_во )
  {
   double max=High[bar];
   for(int i=bar+1;i<Кол_во;i++)
      if(max<High[i]) max=High[i];
   
   return max;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LowMin(int bar, int Кол_во )
  {
   double min=Low[bar];
   for(int i=bar+1;i<Кол_во;i++)
      if(min<Low[i]) min=Low[i];
   
   return min;
  }


//+------------------------------------------------------------------+
