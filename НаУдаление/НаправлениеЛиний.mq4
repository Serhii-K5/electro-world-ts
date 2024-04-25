//+------------------------------------------------------------------+
//|                                             НаправлениеЛиний.mq4 |
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
//--- plot Направление
#property indicator_label1  "Направление"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMediumSeaGreen   // clrWheat
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- indicator buffers
double   НаправлениеBuffer[];
double   ИндBuffer[];

string         Символ;              //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
input int     КолБаров = 2;        //Кол-во баров в эспирации //1
input int     КолЭспираций = 1;    //Кол-во проверяемых эспираций //1

struct структураЛинии {
   datetime точка1;
   datetime точка2;
   double точка1Знач;
   double точка2Знач;  
};
структураЛинии верхнийКанал, нижнийКанал, maxИнд, minИнд;

double   ind1, ind2, ind3;      //Значения индикатора(ind1 - 1-й бар, ind2 - 2-й бар, ...)


bool     старт;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,НаправлениеBuffer);

//--- indicator buffers mapping
 //  short_name=WindowExpertName()+"("+string(КолБаров)+"/"+string(КолЭспираций)+"))";
   //IndicatorShortName(short_name);
   
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
/*      {if(Symbol()!=Символ || Period()!=Период)
         {OnInit(); 
          return(0);
         }
*/       
       Старт();
//       if(wind_ex<0)
  //       return(rates_total);
       старт=False;
   }

   if(prev_calculated>0){
      for(int bar=rates_total-prev_calculated; bar>0; bar--){   
         // Расчёт индикатора
         if(bar<Bars-КолБаров*(КолЭспираций+1)-1){
            if(ArraySize(ИндBuffer)<Bars)
               ArrayResize(ИндBuffer,Bars);
               
            ИндBuffer[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(bar+КолБаров,КолБаров*КолЭспираций))*(Close[bar]-Close[bar+КолБаров]*(1+1/КолЭспираций)+Close[bar+КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);
            
            if(ПроверкаИнд_НаЭкстримумы(bar+2))
               НаправлениеBuffer[bar]=ПоискРазницыКоэфициентов(bar);
            else
               НаправлениеBuffer[bar]=НаправлениеBuffer[bar+1];
         }
      }
   }
//   } else 
 //     ИндBuffer[0]=NormalizeDouble((СредняяVolume(0,КолБаров)-СредняяVolume(КолБаров,КолБаров*КолЭспираций))*(Close[0]-Close[КолБаров]*(1+1/КолЭспираций)+Close[КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
  
//+------------------------------------------------------------------+
//| Расчёт начальных параметров                                      |
//+------------------------------------------------------------------+
bool Старт()
  { 
/*   wind_ex=WindowFind(short_name);
//----
   if(wind_ex<0)
      return false;
*/      
//---Начальное заполнение массивов
   ArraySetAsSeries(ИндBuffer,True);
   ArraySetAsSeries(НаправлениеBuffer,True);
   
   maxИнд.точка1=Time[Bars-1];
   maxИнд.точка2=Time[Bars-1];
   maxИнд.точка1Знач=0.0;
   maxИнд.точка2Знач=0.0;
   
   minИнд=maxИнд;
   
   for(int bar=Bars-4; bar>0; bar--){      
      // Расчёт индикатора
      if(bar<Bars-КолБаров*(КолЭспираций+1)){
         if(ArraySize(ИндBuffer)<Bars)
            ArrayResize(ИндBuffer,Bars);

         ИндBuffer[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(bar+КолБаров,КолБаров*КолЭспираций))*(Close[bar]-Close[bar+КолБаров]*(1+1/КолЭспираций)+Close[bar+КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);
         
         if(ПроверкаИнд_НаЭкстримумы(bar+2))
            НаправлениеBuffer[bar]=ПоискРазницыКоэфициентов(bar);
         else 
            НаправлениеBuffer[bar]=НаправлениеBuffer[bar+1];
      }
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
//| Проверка экстримумов для Инд                                     |
//+------------------------------------------------------------------+
bool ПроверкаИнд_НаЭкстримумы(int ПроверяемыйБар)
  {
   bool rez=false;
   ind1 = ИндBuffer[ПроверяемыйБар-1];
   ind2 = ИндBuffer[ПроверяемыйБар];
   ind3 = ИндBuffer[ПроверяемыйБар+1];
   
   int bb=ПроверяемыйБар+1;
      
   for(int i1=ПроверяемыйБар+3;i1<Bars-2-КолБаров*(КолЭспираций+1) && ind2==ind3;i1++)
      if(ind3 != ИндBuffer[i1]){
          ind3 = ИндBuffer[i1];
          break;
      }
   
   if(bb>Bars-3-КолБаров*(КолЭспираций+1))
      return false;
      
   if(ind2>ind1 && ind2>ind3){ // максимум по 3-м барам
      maxИнд.точка1=maxИнд.точка2;
      maxИнд.точка2=Time[ПроверяемыйБар];
      maxИнд.точка1Знач=maxИнд.точка2Знач;
      maxИнд.точка2Знач=NormalizeDouble(ind2,Digits);
      rez=true;
   }          
   if(ind2<ind1 && ind2<ind3){ // минимум по 3-м барам
      minИнд.точка1=minИнд.точка2;
      minИнд.точка2=Time[ПроверяемыйБар];
      minИнд.точка1Знач=minИнд.точка2Знач;
      minИнд.точка2Знач=NormalizeDouble(ind2,Digits);
      rez=true;
   }
   
   if(maxИнд.точка1==Time[Bars-1] || minИнд.точка1==Time[Bars-1])
       rez=false;
        
//---  
   return rez;  
  }
   

//+------------------------------------------------------------------+
//| Поиск разницы коэфициентов                                       |
//+------------------------------------------------------------------+
double ПоискРазницыКоэфициентов(int проверяемыйБар)
  {
   структураЛинии проверяемаяЛиния1, проверяемаяЛиния2;

   проверяемаяЛиния1=maxИнд;
   проверяемаяЛиния2=minИнд;
   
   int A1x=iBarShift(NULL,0,проверяемаяЛиния1.точка1,false)-проверяемыйБар;
   int B1x=iBarShift(NULL,0,проверяемаяЛиния1.точка2,false)-проверяемыйБар;
   double A1y=NormalizeDouble(проверяемаяЛиния1.точка1Знач,Digits);
   double B1y=NormalizeDouble(проверяемаяЛиния1.точка2Знач,Digits);

   int A2x=iBarShift(NULL,0,проверяемаяЛиния2.точка1,false)-проверяемыйБар;
   int B2x=iBarShift(NULL,0,проверяемаяЛиния2.точка2,false)-проверяемыйБар;
   double A2y=NormalizeDouble(проверяемаяЛиния2.точка1Знач,Digits);
   double B2y=NormalizeDouble(проверяемаяЛиния2.точка2Знач,Digits);
      
   double m=NormalizeDouble((B1y-A1y)/(B1x-A1x),8);
   double n=NormalizeDouble((B2y-A2y)/(B2x-A2x),8);
   
   return NormalizeDouble(m-n,5);
   
  } 

//+------------------------------------------------------------------+
