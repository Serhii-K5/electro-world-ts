//+------------------------------------------------------------------+
//|                                              Изменение 2х МА.mq4 |
//|                                                                Я |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Я"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   3
//--- plot MA1
#property indicator_label1  "MA1"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot MA2
#property indicator_label2  "MA2"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot MA2
#property indicator_label3  "C-O"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGreenYellow
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- input parameters
input int      inpMA1=2;
input int      inpMA2=3;
//--- indicator buffers
double         MA1Buffer[];
double         MA2Buffer[];
double         MA3Buffer[];
datetime ТекущийТаймфрейм;
bool старт=true;
double MA1_1, MA1_2;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
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
  
//--- indicator buffers mapping
   SetIndexBuffer(0,MA1Buffer);
   SetIndexBuffer(1,MA2Buffer);
   SetIndexBuffer(2,MA3Buffer);
      
//---
   return(INIT_SUCCEEDED);
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
//---
   if(старт) {
       Старт();
       старт=False;
   }

   if(ТекущийТаймфрейм!=Time[0]){
      int бар=iBarShift(NULL,0,ТекущийТаймфрейм,True);
      for(int bar=бар; bar>0; bar--){   
         MA1_1=iMA(NULL,0,inpMA1,8,MODE_SMMA,PRICE_MEDIAN,bar);
         MA1_2=iMA(NULL,0,inpMA1,8,MODE_SMMA,PRICE_MEDIAN,bar+1);
         MA1Buffer[bar]=MA1_1-MA1_2;
         
         MA1_1=iMA(NULL,0,inpMA2,8,MODE_SMMA,PRICE_MEDIAN,bar);
         MA1_2=iMA(NULL,0,inpMA2,8,MODE_SMMA,PRICE_MEDIAN,bar+1);
         MA2Buffer[bar]=MA1_1-MA1_2;
         
         MA3Buffer[bar]=Close[bar]-Open[bar];
      }
      ТекущийТаймфрейм=Time[0];
   } else{
         MA1_1=iMA(NULL,0,inpMA1,8,MODE_SMMA,PRICE_MEDIAN,0);
         MA1_2=iMA(NULL,0,inpMA1,8,MODE_SMMA,PRICE_MEDIAN,1);
         MA1Buffer[0]=MA1_1-MA1_2;
         
         MA1_1=iMA(NULL,0,inpMA2,8,MODE_SMMA,PRICE_MEDIAN,0);
         MA1_2=iMA(NULL,0,inpMA2,8,MODE_SMMA,PRICE_MEDIAN,1);
         MA2Buffer[0]=MA1_1-MA1_2;
         
         MA3Buffer[0]=Close[0]-Open[0];
   }
      
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Расчёт начальных параметров                                      |
//+------------------------------------------------------------------+
void Старт()
  {
   ArraySetAsSeries(MA1Buffer,True);
   ArraySetAsSeries(MA2Buffer,True);
   ArraySetAsSeries(MA3Buffer,True);

   ТекущийТаймфрейм=Time[Bars-1];
  }
//+------------------------------------------------------------------+
