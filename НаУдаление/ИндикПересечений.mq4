//+------------------------------------------------------------------+
//|                                             ИндикПересечений.mq4 |
//|                                                                Я |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Я"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot ПересечКаналов
#property indicator_label1  "ПересечКаналов"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot ПересечИнд
#property indicator_label2  "ПересечИнд"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- indicator buffers
//extern string  Символ = "EURUSDb";    //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
string         Символ;              //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
extern int     КолБаров = 2;        //Кол-во баров в эспирации //1
extern int     КолЭспираций = 1;    //Кол-во проверяемых эспираций //1
//int            Период;              //Время исполнения

double         ПересечКаналовBuffer[], ПересечКаналов[];
double         ПересечИндBuffer[], ПересечИнд[];
double         ИндBuffer[];

bool     старт;
datetime ТекущийТаймфрейм=0;

struct структураЛинии {
   datetime точка1;
   datetime точка2;
   double точка1Знач;
   double точка2Знач;  
};
структураЛинии верхнийКанал, нижнийКанал, maxИнд, minИнд;

double   ind1, ind2, ind3;      //Значения индикатора(ind1 - 1-й бар, ind2 - 2-й бар, ...)
string   short_name, Отчёт;
int      wind_ex;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ПересечКаналовBuffer);
   SetIndexBuffer(1,ПересечИндBuffer);
   
   SetIndexShift(0,10); 
   SetIndexShift(1,10); 
   
   short_name=WindowExpertName()+"("+string(КолБаров)+"/"+string(КолЭспираций)+"))";
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
/*   if(Symbol()!=Символ || Period()!=Период)
      {Символ=Symbol();
       Период=Period(); 
       OnInit(); 
       return(0);
      }
*/   
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
   
   if(Bars<КолБаров*(КолЭспираций+1)+2)
      return(rates_total);
      
   if(prev_calculated>0){
      for(int bar=rates_total-prev_calculated; bar>0; bar--){   
         // Расчёт индикатора
         if(bar<Bars-КолБаров*(КолЭспираций+1)-1){
            ИндBuffer[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(bar+КолБаров,КолБаров*КолЭспираций))*(Close[bar]-Close[bar+КолБаров]*(1+1/КолЭспираций)+Close[bar+КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);
         
            if(ПроверкаИнд_НаЭкстримумы(bar+2)){
               int точкаПересеч=ПоискПересеченийЛиний(bar,"");
               if(точкаПересеч<=0){
                  // точка пересечения (точкаПересеч) правее или на тек. баре (bar)
                  if(ArraySize(ПересечИнд)<Bars-bar-точкаПересеч+1)
                     ArrayResize(ПересечИнд,Bars-bar-точкаПересеч+1);
                  
                  ПересечИнд[Bars-1-bar-точкаПересеч]--;
               }
            }
         }
         // Расчёт каналов
         if(ПроверкаКаналовНаЭкстремумы(bar+2)){
            int точкаПересеч=ПоискПересеченийЛиний(bar,"канал");
            if(точкаПересеч<=0){
               // точка пересечения (точкаПересеч) правее или на тек. баре (bar)
               if(ArraySize(ПересечКаналов)<Bars-bar-точкаПересеч+1)
                  ArrayResize(ПересечКаналов,Bars-bar-точкаПересеч+1);
            
               ПересечКаналов[Bars-1-bar-точкаПересеч]++;            
            }
         }
         
         if(ArraySize(ПересечИнд)>Bars-bar+10)
            ПересечИндBuffer[bar]=ПересечИнд[Bars-bar+10];  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе 
         else 
            ПересечИндBuffer[bar]=0.0;
         
         if(ArraySize(ПересечКаналов)>Bars-bar+10)
            ПересечКаналовBuffer[bar]=ПересечКаналов[Bars-bar+10];  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе 
         else 
            ПересечКаналовBuffer[bar]=0.0;
      }
   } else 
      ИндBuffer[0]=NormalizeDouble((СредняяVolume(0,КолБаров)-СредняяVolume(КолБаров,КолБаров*КолЭспираций))*(Close[0]-Close[КолБаров]*(1+1/КолЭспираций)+Close[КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);
            
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
   ArraySetAsSeries(ПересечКаналовBuffer,True);
   ArraySetAsSeries(ПересечИндBuffer,True);   
   ArraySetAsSeries(ИндBuffer,True);
   
   верхнийКанал.точка1=Time[Bars-1];
   верхнийКанал.точка2=Time[Bars-1];
   верхнийКанал.точка1Знач=0.0;
   верхнийКанал.точка2Знач=0.0;
   
   нижнийКанал=верхнийКанал;
   maxИнд=верхнийКанал;
   minИнд=верхнийКанал;
   
   for(int bar=Bars-4; bar>0; bar--){      
      // Расчёт индикатора
      if(bar<Bars-КолБаров*(КолЭспираций+1)){
         if(ArraySize(ИндBuffer)<Bars)
            ArrayResize(ИндBuffer,Bars);

         ИндBuffer[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(bar+КолБаров,КолБаров*КолЭспираций))*(Close[bar]-Close[bar+КолБаров]*(1+1/КолЭспираций)+Close[bar+КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);
         
         if(ПроверкаИнд_НаЭкстримумы(bar+2)){
            int точкаПересеч=ПоискПересеченийЛиний(bar,"");
            if(точкаПересеч<=0){
               // точка пересечения (точкаПересеч) правее или на тек. баре (bar)
               if(ArraySize(ПересечИнд)<Bars-bar-точкаПересеч+1)
                  ArrayResize(ПересечИнд,Bars-bar-точкаПересеч+1);
               
               ПересечИнд[Bars-1-bar-точкаПересеч]--;
               //Print("Индик (",Time[bar],"; ",точкаПересеч,")");
            }
         }
      }
      // Расчёт каналов
      if(ПроверкаКаналовНаЭкстремумы(bar+2)){
         int точкаПересеч=ПоискПересеченийЛиний(bar,"канал");
         if(точкаПересеч<=0){
            // точка пересечения (точкаПересеч) правее или на тек. баре (bar)
            if(ArraySize(ПересечКаналов)<Bars-bar-точкаПересеч+1)
               ArrayResize(ПересечКаналов,Bars-bar-точкаПересеч+1);
         
            ПересечКаналов[Bars-1-bar-точкаПересеч]++;            
            //Print("Каналы (",Time[bar],"; ",точкаПересеч,")");
         }         
      }
   }   
   
   for(int i=0;i<Bars;i++){ 
      if(i<ArraySize(ПересечКаналов)+10)
         ПересечКаналовBuffer[i]=ПересечКаналов[Bars-1-i+10];  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
      else
         ПересечКаналовBuffer[i]=0;  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
      
      if(i<ArraySize(ПересечИнд)+10)
         ПересечИндBuffer[i]=ПересечИнд[Bars-1-i+10];  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
      else   
         ПересечИндBuffer[i]=0;  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
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
   
   for(int i1=ПроверяемыйБар+3;i1<Bars-2-КолБаров*(КолЭспираций+1) && ind2==ind3;i1++)
      if(ind3 != ИндBuffer[i1]){
          ind3 = ИндBuffer[i1];
          break;
      }
   
   if(ПроверяемыйБар>Bars-4-КолБаров*(КолЭспираций+1))
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
//| Проверка каналов на экстремумы                                   |
//+------------------------------------------------------------------+
bool ПроверкаКаналовНаЭкстремумы(int проверяемыйБар)
  {
   bool rez=false;
   if(ПроверкаНаMax(проверяемыйБар)){
      верхнийКанал.точка1=верхнийКанал.точка2;
      верхнийКанал.точка2=Time[проверяемыйБар];
      верхнийКанал.точка1Знач=верхнийКанал.точка2Знач;
      верхнийКанал.точка2Знач=NormalizeDouble(ind2,Digits);
      rez=true;
   }
   if(ПроверкаНаMin(проверяемыйБар)){
      нижнийКанал.точка1=нижнийКанал.точка2;
      нижнийКанал.точка2=Time[проверяемыйБар];
      нижнийКанал.точка1Знач=нижнийКанал.точка2Знач;
      нижнийКанал.точка2Знач=NormalizeDouble(ind2,Digits);
      rez=true;
   }
   
   if(верхнийКанал.точка1==Time[Bars-1] || нижнийКанал.точка1==Time[Bars-1])
      rez=false;
      
   return rez;
  }
    
//+------------------------------------------------------------------+
//| Проверка на максимум                                             |
//+------------------------------------------------------------------+
bool ПроверкаНаMax(int ПроверяемыйБар)
  {
   ind1 = High[ПроверяемыйБар-1];
   ind2 = High[ПроверяемыйБар];
   ind3 = High[ПроверяемыйБар+1];
      
   for(int i1=ПроверяемыйБар+3;i1<Bars-2 && ind2==ind3;i1++)
      if(ind3 != High[i1]){
          ind3 = High[i1];
          break;
      }
   
   if(ind2>ind1 && ind2>ind3) 
      return(true);
   
   return(false);  
  }

//+------------------------------------------------------------------+
//| Проверка на минимум                                              |
//+------------------------------------------------------------------+
bool ПроверкаНаMin(int ПроверяемыйБар)
  {
   ind1 = Low[ПроверяемыйБар-1];
   ind2 = Low[ПроверяемыйБар];
   ind3 = Low[ПроверяемыйБар+1];
      
   for(int i1=ПроверяемыйБар+3;i1<Bars-2 && ind2==ind3;i1++)
      if(ind3 != Low[i1]){
          ind3 = Low[i1];
          break;
      }
   
   if(ind2<ind1 && ind2<ind3) 
      return(true);
   
   return(false); 
  }

//+------------------------------------------------------------------+
//| Поиск пересечений каналов                                        |
//+------------------------------------------------------------------+
//void ПоискПересеченийЛиний(int проверяемыйБар, datetime проверяемыйМассивДат, double проверяемыйМассивЗначение, string тип)
int ПоискПересеченийЛиний(int проверяемыйБар, string тип)
  {
   int      точкаПересеч=Bars;
   структураЛинии проверяемаяЛиния1, проверяемаяЛиния2;
   if(тип=="канал"){
      проверяемаяЛиния1=верхнийКанал;
      проверяемаяЛиния2=нижнийКанал;
   } else{
      проверяемаяЛиния1=maxИнд;
      проверяемаяЛиния2=minИнд;
   }
   
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
   
   if(m==n) return точкаПересеч;
   
   double C1=NormalizeDouble(A1y-A1x*m,8);
   double C2=NormalizeDouble(A2y-A2x*n,8);
   
   double Mx=(C2-C1)/(m-n);   //Координата Х в точке пересеч.  
   
   if(Mx<1)
      точкаПересеч=StrToInteger(DoubleToStr(MathFloor(Mx)));
   else if(тип=="канал") {
      C1=NormalizeDouble(B2y-B2x*m,8);
      C2=NormalizeDouble(B1y-B1x*n,8);
      Mx=(C2-C1)/(m-n);   //Координата Х в точке пересеч.
   
      //if(MathAbs(Mx)>1000) return точкаПересеч;
      if(Mx<1)
         точкаПересеч=StrToInteger(DoubleToStr(MathFloor(Mx)));
   }
   
   return точкаПересеч;
  } 

//+------------------------------------------------------------------+
