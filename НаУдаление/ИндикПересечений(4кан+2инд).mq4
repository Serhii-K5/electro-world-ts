//+------------------------------------------------------------------+
//|                                           ИндикПересечений++.mq4 |
//|                                                                Я |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Я"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   6
//--- plot ПересечОснКаналовВ
#property indicator_label1  "ПересечОснКаналовВ"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot ПересечДопКаналовВ
#property indicator_label2  "ПересечДопКаналовВ"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot ПересечОснКаналовН
#property indicator_label3  "ПересечОснКаналовН"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color3  clrBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
//--- plot ПересечДопКаналовН
#property indicator_label4  "ПересечДопКаналовН"
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_color4  clrCyan
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2
//--- plot ПересечИндВ
#property indicator_label5  "ПересечИндВ"
#property indicator_type5   DRAW_HISTOGRAM
#property indicator_color5  clrGreen
#property indicator_style5  STYLE_SOLID
#property indicator_width5  2
//--- plot ПересечИндН
#property indicator_label6  "ПересечИндН"
#property indicator_type6   DRAW_HISTOGRAM
#property indicator_color6  clrLightGreen
#property indicator_style6  STYLE_SOLID
#property indicator_width6  2

//--- indicator buffers
//extern string  Символ = "EURUSDb";    //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
//string         Символ;              //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
extern int     колБаров = 2;        //Кол-во баров в эспирации //1
extern int     колЭспираций = 1;    //Кол-во проверяемых эспираций //1
extern char    баровПроверки = 3;   //Кол-во проверяемых баров для макс/мин //5
//int            Период;              //Время исполнения

double         ПересечОснКаналовВBuffer[], ПересечОснКаналовВ[];
double         ПересечДопКаналовВBuffer[], ПересечДопКаналовВ[];
double         ПересечОснКаналовНBuffer[], ПересечОснКаналовН[];
double         ПересечДопКаналовНBuffer[], ПересечДопКаналовН[];
double         ПересечИндВBuffer[], ПересечИндВ[];
double         ПересечИндНBuffer[], ПересечИндН[];
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

string   short_name, Отчёт, типПересечКаналов="О";
int      wind_ex;
bool     каналВверх=false, индВверх=false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ПересечОснКаналовВBuffer);
   SetIndexBuffer(1,ПересечДопКаналовВBuffer);
   SetIndexBuffer(2,ПересечОснКаналовНBuffer);
   SetIndexBuffer(3,ПересечДопКаналовНBuffer);
   SetIndexBuffer(4,ПересечИндВBuffer);
   SetIndexBuffer(5,ПересечИндНBuffer);
   
   SetIndexShift(0,10); 
   SetIndexShift(1,10); 
   SetIndexShift(2,10); 
   SetIndexShift(3,10); 
   SetIndexShift(4,10); 
   SetIndexShift(5,10); 
   
   short_name=WindowExpertName()+"("+string(колБаров)+","+string(колЭспираций)+","+string(баровПроверки)+"))";
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
   
   if(Bars<колБаров*(колЭспираций+1)+2 || Bars<баровПроверки)
      return(rates_total);
      
//   if(prev_calculated>0){
  //    for(int bar=rates_total-prev_calculated; bar>0; bar--){   
   if(ТекущийТаймфрейм!=Time[0]){
//      ArrayResize(ПересечДопКаналовНBuffer,Bars);
  //    ArrayResize(ПересечИндBuffer,Bars);
      
      int бар=iBarShift(NULL,0,ТекущийТаймфрейм,True);
      for(int bar=бар; bar>0; bar--){      
         РасчётИндИКаналов(bar);
         for(int i1=10;i1>=0;i1--)
            ЗаписьПересечений(bar+i1);     
      }
      
      ТекущийТаймфрейм=Time[0];
      
      ChartRedraw();
   }
//   } else 
  //    ИндBuffer[Bars-1]=NormalizeDouble((СредняяVolume(0,колБаров)-СредняяVolume(колБаров,колБаров*колЭспираций))*(Close[0]-Close[колБаров]*(1+1/колЭспираций)+Close[колБаров*(колЭспираций+1)]/колЭспираций)/колБаров,Digits);
            
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
   ArraySetAsSeries(ПересечОснКаналовВBuffer,True);
   ArraySetAsSeries(ПересечДопКаналовВBuffer,True);
   ArraySetAsSeries(ПересечОснКаналовНBuffer,True);
   ArraySetAsSeries(ПересечДопКаналовНBuffer,True);
   ArraySetAsSeries(ПересечИндВBuffer,True);
   ArraySetAsSeries(ПересечИндНBuffer,True);
   
   верхнийКанал.точка1=Time[Bars-1];
   верхнийКанал.точка2=Time[Bars-1];
   верхнийКанал.точка1Знач=0.0;
   верхнийКанал.точка2Знач=0.0;
   
   нижнийКанал=верхнийКанал;
   maxИнд=верхнийКанал;
   minИнд=верхнийКанал;
   
   ТекущийТаймфрейм=Time[1];
   for(int bar=Bars-1; bar>0; bar--)      
       РасчётИндИКаналов(bar);
      
   for(int i=0;i<Bars;i++)
      ЗаписьПересечений(i);

//--- перерисуем график    
   ChartRedraw();
   
   return true;
  }

//+------------------------------------------------------------------+
//| Расчёт индикатора и каналов                                      |
//+------------------------------------------------------------------+
void РасчётИндИКаналов(int bar)
  {
   // Расчёт индикатора
   if(Bars-bar>колБаров*(колЭспираций+1)){
      if(ArraySize(ИндBuffer)<Bars)
         ArrayResize(ИндBuffer,Bars);
      
      ИндBuffer[Bars-1-bar]=NormalizeDouble((СредняяVolume(bar,колБаров)-СредняяVolume(bar+колБаров,колБаров*колЭспираций))*(Close[bar]-Close[bar+колБаров]*(1+1/колЭспираций)+Close[bar+колБаров*(колЭспираций+1)]/колЭспираций)/колБаров,Digits);
      if(ПроверкаИнд_НаЭкстримумы(Bars-1-(bar+1))){   //т.к. ИндBuffer[bar]
         int точкаПересеч=ПоискПересеченийЛиний(bar-1,"");  //т.к. ИндBuffer[bar]
         if(точкаПересеч<=0){
            // точка пересечения (точкаПересеч) правее или на тек. баре (bar)
            if(ArraySize(ПересечИндВ)<Bars-bar-точкаПересеч+1){
               ArrayResize(ПересечИндВ,Bars-bar-точкаПересеч+1);
               ArrayResize(ПересечИндН,Bars-bar-точкаПересеч+1);
            }
            
            ПересечИндВ[Bars-bar-точкаПересеч]--;
            if(!индВверх)
               ПересечИндН[Bars-bar-точкаПересеч]--;
         }
      }
   }
   // Расчёт каналов
   if(bar>0 && bar<Bars-1-(баровПроверки-1)/2){
      if(ПроверкаКаналовНаЭкстремумы(bar+int((баровПроверки-1)/2))){ //(bar+1)  т.к. ИндBuffer[bar]
         int точкаПересеч=ПоискПересеченийЛиний(bar-1,"канал");
         if(точкаПересеч<=0){
            // точка пересечения (точкаПересеч) правее или на тек. баре (bar)
            if(ArraySize(ПересечОснКаналовВ)<Bars-bar-точкаПересеч+1){
               ArrayResize(ПересечОснКаналовВ,Bars-bar-точкаПересеч+1);
               ArrayResize(ПересечДопКаналовВ,Bars-bar-точкаПересеч+1);
               ArrayResize(ПересечОснКаналовН,Bars-bar-точкаПересеч+1);
               ArrayResize(ПересечДопКаналовН,Bars-bar-точкаПересеч+1);
            }
            
            ПересечОснКаналовВ[Bars-bar-точкаПересеч]++;
            if(!каналВверх)
               ПересечОснКаналовН[Bars-bar-точкаПересеч]++;
            
            if(типПересечКаналов=="Д"){
               ПересечДопКаналовВ[Bars-bar-точкаПересеч]++;
               if(!каналВверх)
                  ПересечДопКаналовН[Bars-bar-точкаПересеч]++;
            }
         }      
      }
   }
  } 
    
//+------------------------------------------------------------------+
//| Запись пересечений                                               |
//+------------------------------------------------------------------+
void ЗаписьПересечений(int i)
  {
   if(Bars-i+9<ArraySize(ПересечОснКаналовВ)){
      ПересечОснКаналовВBuffer[i]=ПересечОснКаналовВ[Bars-i+9];  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
      ПересечДопКаналовВBuffer[i]=ПересечДопКаналовВ[Bars-i+9];  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
      ПересечОснКаналовНBuffer[i]=ПересечОснКаналовН[Bars-i+9];  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
      ПересечДопКаналовНBuffer[i]=ПересечДопКаналовН[Bars-i+9];  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
   } else{
      ПересечОснКаналовВBuffer[i]=0;  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
      ПересечДопКаналовВBuffer[i]=0;  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
      ПересечОснКаналовНBuffer[i]=0;  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
      ПересечДопКаналовНBuffer[i]=0;  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
   }
   
   if(Bars-i+9<ArraySize(ПересечИндВ)){
      ПересечИндВBuffer[i]=ПересечИндВ[Bars-i+9];  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
      ПересечИндНBuffer[i]=ПересечИндН[Bars-i+9];  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе   
   } else{  
      ПересечИндВBuffer[i]=0;  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе 
      ПересечИндНBuffer[i]=0;  //для ПересечКаналов[] 1-й известный бар графика находится в 0-м  элементе 
   }
  } 
      
//+------------------------------------------------------------------+
//| Средняя тиков за выбранный период                                |
//+------------------------------------------------------------------+
double СредняяVolume(int bar, int Кол_во)
  {
   int сумма=0;
   for(int i=0;i<Кол_во;i++)
      сумма+=int(Volume[bar+i]);
   
   return NormalizeDouble(сумма/Кол_во,0);
  } 
    
//+------------------------------------------------------------------+
//| Проверка экстримумов для Инд                                     |
//+------------------------------------------------------------------+
bool ПроверкаИнд_НаЭкстримумы(int проверяемыйБар) // проверяемыйБар=0+2
  {
   bool rez=false;
   uchar max=0, min=0;
   double ind1=ИндBuffer[проверяемыйБар+1];
   double ind2=ИндBuffer[проверяемыйБар];
   
   int бар= ПоискInd3(проверяемыйБар);
   if(бар<0)
      return false;
   
   double ind3=ИндBuffer[бар]; 
     
   //-- проверка указанного бара на экстримум
   if(!(ind2>ind1 && ind2>ind3) && !(ind2<ind1 && ind2<ind3))
      return false;
   
   //-- Бар является экстримумом. Поиск новых точек построения 
   for(int bar=проверяемыйБар; bar>колБаров*(колЭспираций+1); bar--){
      ind1 = ИндBuffer[bar+1];
      ind2 = ИндBuffer[bar];
      бар= ПоискInd3(bar);
         
//      if(бар<0)
      if(бар<колБаров*(колЭспираций+1))
         return false;
      
      ind3 = ИндBuffer[бар];
         
      if(ind2>ind1 && ind2>ind3){ // максимум по 3-м барам
         if(max==0){
            maxИнд.точка2=Time[Bars-1-bar];
            maxИнд.точка2Знач=NormalizeDouble(ind2,Digits);
         }else if(max==1){
            maxИнд.точка1=Time[Bars-1-bar];
            maxИнд.точка1Знач=NormalizeDouble(ind2,Digits);
         }
         max++;
      }
      
      if(ind2<ind1 && ind2<ind3){ // минимум по 3-м барам
         if(min==0){
            minИнд.точка2=Time[Bars-1-bar];
            minИнд.точка2Знач=NormalizeDouble(ind2,Digits);
         } else if(min==1){
            minИнд.точка1=Time[Bars-1-bar];
            minИнд.точка1Знач=NormalizeDouble(ind2,Digits);
         }
         min++;
      }
         
      if(max>1 && min>1){
         rez=true;
         break;
      }
   }
//---  
   return rez;  
  }

//+------------------------------------------------------------------+
//| Поиск ind3 для индикатора                                        |
//+------------------------------------------------------------------+
int ПоискInd3(int проверяемыйБар)
  {
   int бар;
   
   for(бар=проверяемыйБар-1;бар>колБаров*(колЭспираций+1);бар--)
      if(ИндBuffer[проверяемыйБар] != ИндBuffer[бар])
          break;
   
   return бар;
  }

//+------------------------------------------------------------------+
//| Проверка каналов на экстремумы                                   |
//+------------------------------------------------------------------+
bool ПроверкаКаналовНаЭкстремумы(int проверяемыйБар)
  {
   bool rez=false;
   uchar max=0, min=0;   
   
   if(!ПроверкаНаMax(проверяемыйБар) && !ПроверкаНаMin(проверяемыйБар))
      return false;
   
   for(int bar=проверяемыйБар; bar<Bars-1; bar++){
      if(ПроверкаНаMax(bar)){
         if(max==0){
            верхнийКанал.точка2=Time[bar];
            верхнийКанал.точка2Знач=NormalizeDouble(High[bar],Digits);
         }else if(max==1){
            верхнийКанал.точка1=Time[bar];
            верхнийКанал.точка1Знач=NormalizeDouble(High[bar],Digits);
         }
         max++;
      }
      if(ПроверкаНаMin(bar)){
         if(min==0){
            нижнийКанал.точка2=Time[bar];
            нижнийКанал.точка2Знач=NormalizeDouble(Low[bar],Digits);
         } else if(min==1){
            нижнийКанал.точка1=Time[bar];
            нижнийКанал.точка1Знач=NormalizeDouble(Low[bar],Digits);
         }
         min++;
      }
      if(max>1 && min>1){
         rez=true;
         break;
      }   
   }
      
   return rez;
  }
  
//+------------------------------------------------------------------+
//| Проверка на максимум                                             |
//+------------------------------------------------------------------+
bool ПроверкаНаMax(int проверяемыйБар)
  {   
   for(int i=0;i<(баровПроверки-1)/2;i++){
      if(High[проверяемыйБар] <= High[проверяемыйБар-1-i])
          return(false);
   }   
   for(int i=проверяемыйБар+1;i<Bars;i++)
      if(High[проверяемыйБар] > High[i])
         return(true);
      else if(High[проверяемыйБар] < High[i] || i==Bars-1)
         return(false);
   
   return(false);   
  }

//+------------------------------------------------------------------+
//| Проверка на минимум                                              |
//+------------------------------------------------------------------+
bool ПроверкаНаMin(int проверяемыйБар)
  {
   for(int i=0;i<(баровПроверки-1)/2;i++)
      if(Low[проверяемыйБар] >= Low[проверяемыйБар-1-i])
          return(false);
      
   for(int i=проверяемыйБар+1;i<Bars;i++)
      if(Low[проверяемыйБар] > Low[i])
          return(false);
      else if(Low[проверяемыйБар] < Low[i])
         break;
      else if(i == Bars-баровПроверки)
         return(false);
   
   return(true);
  }

//+------------------------------------------------------------------+
//| Поиск пересечений каналов                                        |
//+------------------------------------------------------------------+
int ПоискПересеченийЛиний(int проверяемыйБар, string тип)
  {
   int точкаПересеч=Bars;
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
   
   //-- среднее направление прямых
   double y1=(A1y+A1x*n+C2)/2;
   double y2=(B1y+B1x*n+C2)/2;
   
   if(Mx<1){
      точкаПересеч=StrToInteger(DoubleToStr(MathFloor(Mx)));
      if(тип!="канал"){
         if(y1>y2)
            индВверх=false;
         else if(y1<y2)
            индВверх=true;
      } else
         типПересечКаналов="О";
   } else if(тип=="канал"){
      C1=NormalizeDouble(B2y-B2x*m,8);
      C2=NormalizeDouble(B1y-B1x*n,8);
      Mx=(C2-C1)/(m-n);   //Координата Х в точке пересеч.
   
      //if(MathAbs(Mx)>1000) return точкаПересеч;
      if(Mx<1)
         точкаПересеч=StrToInteger(DoubleToStr(MathFloor(Mx)));
      
      типПересечКаналов="Д";
      
      //-- направление каналов
//      double y1=(A1y+A1x*n+C2)/2;
  //    double y2=(B1y+B1x*n+C2)/2;
      if(y1>y2)
         каналВверх=false;
      else if(y1<y2)
         каналВверх=true;
   }
   
   return точкаПересеч;
  } 

//+------------------------------------------------------------------+
