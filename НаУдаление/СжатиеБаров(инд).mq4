//+------------------------------------------------------------------+
//|                                             СжатиеБаров(инд).mq4 |
//|                                                                Я |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Я"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot СилаСжатия
#property indicator_label1  "СилаСжатия"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWheat
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

extern int     КолБаров = 2;        //Кол-во баров в эспирации //1

//--- indicator buffers
double         СилаСжатияBuffer[];
bool     старт;
datetime текущийТаймфрейм=0;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,СилаСжатияBuffer);
   
//---Настройка графика   
   long handle=ChartID();
   if(handle>0){ // если получилось, дополнительно настроим
      IndicatorDigits(Digits);
/*     
      //--- Установка периода графика
      if(!ChartSetSymbolPeriod(0,Символ,Период))
         ChartSetSymbolPeriod(0,NULL,Период);
*/
      //--- сброс значения ошибки
      ResetLastError();
      //--- установка значения приближеня/отдаления графика (дальше(0)-ближе(5))
      ChartSetInteger(handle,CHART_SCALE,0,5);

      //--- сброс значения ошибки
      ResetLastError();
      //--- отображение в виде свечей
      ChartSetInteger(handle,CHART_MODE,CHART_CANDLES);

      //--- отключим автопрокрутку
      ChartSetInteger(handle,CHART_AUTOSCROLL,false);
      //---сдвинем график к 0-му бару
      ChartNavigate(ChartID(),CHART_END,0);
   }

   старт=true;
   
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

   if(текущийТаймфрейм!=Time[0]){
      int бар=iBarShift(NULL,0,текущийТаймфрейм,True);
      for(int bar=бар; bar>0; bar--){   
         //СилаСжатияBuffer[bar]=NormalizeDouble((СуммаVolume(bar,КолБаров)-СуммаVolume(bar+КолБаров,КолБаров))*(Close[bar]-Close[bar+КолБаров]*2+Close[bar+КолБаров*2])/КолБаров,Digits);
//         СилаСжатияBuffer[bar]=NormalizeDouble(СуммаVolume(bar,КолБаров)/(Close[bar]-Close[bar+КолБаров]),Digits);
         СилаСжатияBuffer[bar]=NormalizeDouble((Close[bar]-Close[bar+КолБаров])/СуммаVolume(bar,КолБаров)*100,Digits);
      }
      
      текущийТаймфрейм=Time[0];
   } else
         //СилаСжатияBuffer[0]=NormalizeDouble((СуммаVolume(0,КолБаров)-СуммаVolume(КолБаров,КолБаров))*(Close[0]-Close[КолБаров]*2+Close[КолБаров*2])/КолБаров,Digits);
         СилаСжатияBuffer[0]=NormalizeDouble(Close[0]-Close[КолБаров]/(СуммаVolume(0,КолБаров)*100),Digits);
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Расчёт начальных параметров                                      |
//+------------------------------------------------------------------+
void Старт()
  {
   ArraySetAsSeries(СилаСжатияBuffer,True);

   текущийТаймфрейм=Time[Bars-1-КолБаров*2];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int СуммаVolume(int bar, int Кол_во )
  {
   int сумма=0;
   for(int i=0;i<Кол_во;i++)
      сумма+=int(Volume[bar+i]);
   
   return int(NormalizeDouble(сумма,0));
  }

//+------------------------------------------------------------------+
