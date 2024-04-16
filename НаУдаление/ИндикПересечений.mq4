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
#property indicator_buffers 3
#property indicator_plots   3
//--- plot ПересечКаналов
#property indicator_label1  "ПересечКаналов"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot ПересечДСТСДСЦ
#property indicator_label2  "ПересечДСТСДСЦ"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot ДСТСДСЦ
#property indicator_label2  "ДСТСДСЦ"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrWheat
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- indicator buffers
extern string  Символ = "EURUSDb";    //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
extern int     КолБаров = 2;    //Кол-во баров в эспирации //1
extern int     КолЭспираций = 1;    //Кол-во проверяемых эспираций //1
int            Период;    //Время исполнения

double         ПересечКаналовBuffer[];
double         ПересечДСТСДСЦBuffer[];
double         ДСТСДСЦBuffer[];

bool     старт;
//int      Bar;
datetime ТекущийТаймфрейм=0;

datetime МаксМинДатаКаналы[2][2], МаксМинДатаКаналы1[2][2];     //МаксМинВремя[0-Макс, 1-Мин][0-Max1/Min1, 1-Max2/Min2]
double   МаксМинЗначениеКаналы[2][2], МаксМинЗначениеКаналы1[2][2];  //МаксМинЗначение[0-Макс, 1-Мин][0-Max1/Min1, 1-Max2/Min2]
datetime МаксМинВремяИнд[2][2];     //МаксМинВремя[0-Макс, 1-Мин][0-Max1/Min1, 1-Max2/Min2]
double   МаксМинЗначениеИнд[2][2];  //МаксМинЗначение[0-Макс, 1-Мин][0-Max1/Min1, 1-Max2/Min2]
double   ind1, ind2, ind3;      //Значения индикатора(ind1 - 1-й бар, ind2 - 2-й бар, ...)

string   short_name;
int      wind_ex;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ПересечКаналовBuffer);
   SetIndexBuffer(1,ПересечДСТСДСЦBuffer);
   SetIndexBuffer(2,ДСТСДСЦBuffer);
   
   short_name=WindowExpertName()+"("+string(b1)+")";
   IndicatorShortName(short_name);
   
   long handle=ChartID();
   if(handle>0) // если получилось, дополнительно настроим
     {IndicatorDigits(Digits);
      //--- Установка периода графика
      //ChartSetSymbolPeriod(0,NULL,Период);
      if (!ChartSetSymbolPeriod(0,Символ,Период)) 
         ChartSetSymbolPeriod(0,NULL,Период);
      
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
   if(Symbol()!=Символ || Period()!=Период)
      {Символ=Symbol();
       Период=Period(); 
       OnInit(); 
       return(0);
      }
   
   if(старт)
      {if(Symbol()!=Символ || Period()!=Период)
         {OnInit(); 
          return(0);
         }
       Старт();
       if(wind_ex<0)
         return(rates_total);
       старт=False;
      }
   
   //if(rates_total<b1+2)
   if(Bars<b1+2)
      return(rates_total);
      
   if(prev_calculated>0){
      for(Bar=rates_total-prev_calculated; Bar>0; Bar--){   
         
         //ДСТСДСЦBuffer[Bar]=NormalizeDouble((Volume[Bar]-Volume[Bar+b1])*(Close[Bar]-Close[Bar+1]-Close[Bar+b1]+Close[Bar+1+b1]),Digits);
         //ДСТСДСЦBuffer[Bar]=NormalizeDouble((Volume[Bar]-Volume[Bar+КолЭспираций])*(Close[Bar]-Close[Bar+1]-Close[Bar+КолЭспираций]+Close[Bar+1+КолЭспираций]),Digits);
         ДСТСДСЦBuffer[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(КолБаров,КолБаров*КолЭспираций))*(Close[bar]-Close[bar+КолБаров]*(1+1/КолЭспираций)-Close[bar+КолБаров*(КолЭспираций+1)]/КолЭспираций),Digits);    

         
             
         ПоискБлижайшихМаксМинДСТСДСЦ(Bar);
         
         //---Поиск эскстримумов для каналов
         if(ПоискБлижайшихЭкстремумов(bar) && ПроверкаНаИзменениеMaxMin())
            ПоискПересеченийКаналов(bar);
      
         ПерестроениеКаналов();
//         текущийТаймфрейм=Time[0];  //присваиваем текущему таймфрейму таймфрейм 0-го бара
      }
      
/*      
      int ПоследнийБар=iBarShift(NULL,0,ТекущийТаймфрейм,false);
      if(ПоследнийБар>0)  //if(prev_calculated>0)
         for(int Bar=ПоследнийБар; Bar>0; Bar--) //for(Bar=rates_total-prev_calculated; Bar>0; Bar--)//for(Bar=Bars-2; Bar>=0; Bar--)
            {Индик[Bar]=NormalizeDouble((Volume[Bar]-Volume[Bar+b1])*(Close[Bar]-Close[Bar+1]-Close[Bar+b1]+Close[Bar+1+b1]),Digits);
             
             ПоискБлижайшихМаксМин(Bar);
            }
*/   
   } else {
      ДСТСДСЦBuffer[0]=NormalizeDouble((СредняяVolume(0,КолБаров)-СредняяVolume(КолБаров,КолБаров*КолЭспираций))*(Close[0]-Close[КолБаров]*(1+1/КолЭспираций)-Close[КолБаров*(КолЭспираций+1)]/КолЭспираций),Digits);    
   }  
      
      
   
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
      return;
      
//---Начальное заполнение массивов   
   ArraySetAsSeries(ДСТСДСЦBuffer,True);
   
   ArrayFill(МаксМинДатаКаналы,0,ArraySize(МаксМинДатаКаналы),Time[Bars-1]);
   ArrayFill(МаксМинВремяИнд,0,ArraySize(МаксМинВремяИнд),Time[Bars-1]);
   
   for(int bar=Bars-3; bar>0; bar--){      
      // Расчёт индикатора
      if(bar<Bars-КолБаров*(КолЭспираций+1)-1){
         ДСТСДСЦBuffer[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(bar+КолБаров,КолБаров*КолЭспираций))*((Close[bar]-Close[bar+КолБаров])/КолБаров-(Close[bar+КолБаров]+Close[bar+1+b1])/КолБаров/КолЭспираций),Digits);
         ПоискБлижайшихМаксМинДСТСДСЦ(bar);
         ПоискПересеченийЛиний(bar, МаксМинВремяИнд, МаксМинЗначениеИнд);
      }
      
      // Расчёт каналов
      //---Поиск эскстримумов для каналов
      if(ПоискБлижайшихЭкстремумовКаналов(bar) && ПроверкаНаИзменениеMaxMinКаналов())
         ПоискПересеченийКаналов(bar);
         ПоискПересеченийЛиний(bar, МаксМинДатаКаналы, МаксМинЗначениеКаналы);
         
         
   }   
      
  } 
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   датаОтсчёта=Time[Bars-1];
   ArrayFill(МаксМинДатаКаналы,0,ArraySize(МаксМинДатаКаналы),Time[Bars-1]);
   текущийТаймфрейм=Time[1];
   
//---Поиск пересечений каналов
   for(int bar=Bars-3;bar>0;bar--){
      //---Поиск эскстримумов для каналов
      if(ПоискБлижайшихЭкстремумов(bar) && ПроверкаНаИзменениеMaxMin())
         ПоискПересеченийКаналов(bar);
      
//      if(bar==1) return false;
   }
/*   
   //--- создание равноудаленных каналов 
   if(!ChannelCreate(0,InpName1,0,Time[5],High[5],Time[1],High[1],Time[3],Low[3],InpColor1, 
       InpStyle,,InpBack,,,InpRayRight,,)){ 
      return false; 
    }
   if(!ChannelCreate(0,InpName2,0,Time[7],Low[7],Time[3],Low[3],Time[1],High[1],InpColor1, 
       InpStyle,,InpBack,,,InpRayRight,,)){ 
      return false; 
    }
   
   ПерестроениеКаналов();
*/   
   if(МаксМинДатаКаналы[0][0]<Time[Bars-1] || МаксМинДатаКаналы[0][1]<Time[Bars-1] || МаксМинДатаКаналы[1][0]<Time[Bars-1] || МаксМинДатаКаналы[1][1]<Time[Bars-1])
      return false;
   if(!ChannelCreate(0,InpName1,0,МаксМинДатаКаналы[0][0],maxMinЗначение[0][0],МаксМинДатаКаналы[0][1],maxMinЗначение[0][1],МаксМинДатаКаналы[1][1],maxMinЗначение[1][1],InpColor1, 
       InpStyle,1,false,InpBack,true,InpRayRight,false)){ 
       Print("Неудалось создать канал ", InpName1);
//      return false; 
    }
   if(!ChannelCreate(0,InpName2,0,МаксМинДатаКаналы[1][0],maxMinЗначение[1][0],МаксМинДатаКаналы[1][1],maxMinЗначение[1][1],МаксМинДатаКаналы[0][1],maxMinЗначение[0][1],InpColor2, 
       InpStyle,1,false,InpBack,true,InpRayRight,false)){        
       Print("Неудалось создать канал ", InpName2);
//      return false; 
    }
    
//--- перерисуем график    
   ChartRedraw();
   
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Старт()
  {wind_ex=WindowFind(short_name);
//----
   if(wind_ex<0)
      return;
      
//---Начальное заполнение массивов   
   ArraySetAsSeries(Индик,True);

   for(int Bar=Bars-b1-2; Bar>0; Bar--)
      Индик[Bar]=NormalizeDouble((Volume[Bar]-Volume[Bar+b1])*(Close[Bar]-Close[Bar+1]-Close[Bar+b1]+Close[Bar+1+b1]),Digits);

   for(int i=0;i<ArraySize(НазваниеЛиний);i++)
      switch(i) 
        {case 0:
            if(ObjectsTotal()>0) НазваниеЛиний[0]="МаксДвижСмещТиковСДвижСмещЦен"+string(ObjectsTotal());
            else НазваниеЛиний[0]="МаксДвижСмещТиковСДвижСмещЦен";
         case 1: 
            if(ObjectsTotal()>1) НазваниеЛиний[1]="МинДвижСмещТиковСДвижСмещЦен"+string(ObjectsTotal()-1);
            else НазваниеЛиний[1]="МинДвижСмещТиковСДвижСмещЦен";
        } 
   
   for(int i=0;i<ArraySize(НазваниеЛиний) ;i++) 
     {//--- сбросим значение ошибки 
      ResetLastError();      
      if(НазваниеЛиний[i]=="") НазваниеЛиний[i]=StringConcatenate("Линия",i);
      if(!ObjectCreate(0,НазваниеЛиний[i],OBJ_TREND,wind_ex,Time[i+5],Индик[i+5],Time[i+3],Индик[i+3])) 
        {Print("Ошибка создания линии ",НазваниеЛиний[i],": code #",GetLastError());
         //return;
        } 
      else if(i<2)
         //--- установим цвет пары линий 
            ObjectSetInteger(0,НазваниеЛиний[i],OBJPROP_COLOR,clrOrange);  //clrRed
     }
   
   ТекущийТаймфрейм=Time[1];
//   char c;
//   char c, точекMin=0, точекMax=0;
   ArrayFill(МаксМинВремяЛок,0,ArraySize(МаксМинВремяЛок),Time[Bars-1]);
   
   ПоискБлижайшихМаксМин(1);
/*   for(int Bar=1;Bar<Bars-3-b1;Bar++) 
      {c=РасчётЛокДанных();
      if(c>0)
         {Отчёт="Недостаточно данных в истории.";
          Print(Отчёт);
          return;
         } 
      else if(c==-2)
         {МаксМинВремяЛок[0][1]=МаксМинВремяЛок[0][0];
          МаксМинВремяЛок[0][0]=Time[Bar+1];
          МаксМинЗначениеЛок[0][1]=МаксМинЗначениеЛок[0][0];
          МаксМинЗначениеЛок[0][0]=ind2;
         }
      else if(c==-3)      
         {МаксМинВремяЛок[1][1]=МаксМинВремяЛок[1][0];
          МаксМинВремяЛок[1][0]=Time[Bar+1];
          МаксМинЗначениеЛок[1][1]=МаксМинЗначениеЛок[1][0];
          МаксМинЗначениеЛок[1][0]=ind2;
         }
      
      if(МаксМинВремяЛок[0][1]>Time[Bars-1] && МаксМинВремяЛок[1][1]>Time[Bars-1]) 
         Bar=Bars;      
      }
*/   
   
   ПереносТрендовыхЛиний();
   
   ChartRedraw();
  
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int СредняяVolume(int bar, int Кол_во )
  {
   int сумма=0;
   for(int i=0;i<Кол_во;i++)
      сумма+=Volume[bar+i];
   
   return NormalizeDouble(сумма/Кол_во,0);
  } 

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ПоискБлижайшихМаксМинДСТСДСЦ(int ПроверяемыйБар)
  {
   char c, точекMin=0, точекMax=0;
   
   for(int bar=ПроверяемыйБар;bar<Bars-3-КолБаров*(КолЭспираций+1);bar++){
      c=ПроверкаЭкстримумовДСТСДСЦ(bar);
      if(c<0){
          Отчёт="Недостаточно данных в истории.";
          Print(Отчёт);
          return;
      } else if(c==1){ // для максимумов
          if(точекMax==0){
            МаксМинВремяИнд[0][1]=Time[bar+1];
            МаксМинЗначениеИнд[0][1]=ind2;
          } else{
            МаксМинВремяИнд[0][0]=Time[bar+1];
            МаксМинЗначениеИнд[0][0]=ind2;
          } 
          точекMax++;
      } else if(c==2){ // для минимумов     
          if(точекMin==0){
            МаксМинВремяИнд[1][1]=Time[bar+1];
            МаксМинЗначениеИнд[1][1]=ind2;
          } else{
            МаксМинВремяИнд[1][0]=Time[bar+1];
            МаксМинЗначениеИнд[1][0]=ind2;
          }
          точекMin++;
      }
      
      if(точекMin>1 && точекMax>1) break;   
   }     
  }
    
//+------------------------------------------------------------------+
//| Проверка экстримумов для ДСТСДСЦ                                 |
//+------------------------------------------------------------------+
char ПроверкаЭкстримумовДСТСДСЦ(int ПроверяемыйБар)
  {
   ind1 = Индик[ПроверяемыйБар];
   ind2 = Индик[ПроверяемыйБар+1];
   ind3 = Индик[ПроверяемыйБар+2];
      
   for(int i1=ПроверяемыйБар+3;i1<Bars-2-КолБаров*(КолЭспираций+1) && ind2==ind3;i1++)
      if(ind3 != Индик[i1]){
          ind3 = Индик[i1];
          break;
      }
   
   if(ind2==ind3) //не хватает баров для проверки
      return(-1);
         
   if(ind2>ind1 && ind2>ind3) // максимум по 3-м барам
      return(1);
             
   if(ind2<ind1 && ind2<ind3) // минимум по 3-м барам
      return(2);
        
//---  
   return(3);  
  }
  
  
//+------------------------------------------------------------------+
//| Поиск ближайших экстремумов                                      |
//+------------------------------------------------------------------+
bool ПоискБлижайшихЭкстремумов(int проверяемыйБар)
  {
   char точекMin=0, точекMax=0;
   
   for(int bar=проверяемыйБар;bar<Bars-3;bar++){
      if(ПроверкаНаMax(bar)){
         МаксМинДатаКаналы[0][1]=МаксМинДатаКаналы[0][0];
         МаксМинДатаКаналы[0][0]=Time[bar+1];
         МаксМинЗначениеКаналы[0][1]=МаксМинЗначениеКаналы[0][0];
         МаксМинЗначениеКаналы[0][0]=NormalizeDouble(ind2,Digits);
         точекMax++;
      }
      if(ПроверкаНаMin(bar)){
         МаксМинДатаКаналы[1][1]=МаксМинДатаКаналы[1][0];
         МаксМинДатаКаналы[1][0]=Time[bar+1];
         МаксМинЗначениеКаналы[1][1]=МаксМинЗначениеКаналы[1][0];
         МаксМинЗначениеКаналы[1][0]=NormalizeDouble(ind2,Digits);
         точекMin++;
      }
      
      if(точекMin>1 && точекMax>1) break;   
   }   
  
   if(точекMin>1 && точекMax>1) return true;
   else return false;
  }  
//+------------------------------------------------------------------+
//| Проверка на максимум                                             |
//+------------------------------------------------------------------+
bool ПроверкаНаMax(int ПроверяемыйБар)
  {
   ind1 = High[ПроверяемыйБар];
   ind2 = High[ПроверяемыйБар+1];
   ind3 = High[ПроверяемыйБар+2];
      
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
   ind1 = Low[ПроверяемыйБар];
   ind2 = Low[ПроверяемыйБар+1];
   ind3 = Low[ПроверяемыйБар+2];
      
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
//| Проверка на изменение max/min                                    |
//+------------------------------------------------------------------+
bool ПроверкаНаИзменениеMaxMin()
  {
   if(МаксМинДатаКаналы1[0][0]==МаксМинДатаКаналы[0][0] && МаксМинДатаКаналы1[0][1]==МаксМинДатаКаналы[0][1])
      КаналMaxИзменён=false;
   else КаналMaxИзменён=true;
   if(МаксМинДатаКаналы1[0][0]!=МаксМинДатаКаналы[0][0])
      МаксМинДатаКаналы1[0][0]=МаксМинДатаКаналы[0][0];
   if(МаксМинДатаКаналы1[0][1]!=МаксМинДатаКаналы[0][1])
      МаксМинДатаКаналы1[0][1]=МаксМинДатаКаналы[0][1]; 
   
   if(МаксМинДатаКаналы1[1][0]==МаксМинДатаКаналы[1][0] && МаксМинДатаКаналы1[1][1]==МаксМинДатаКаналы[1][1])
      КаналMinИзменён=false;
   else КаналMinИзменён=true;
   if(МаксМинДатаКаналы1[1][0]!=МаксМинДатаКаналы[1][0])
      МаксМинДатаКаналы1[1][0]=МаксМинДатаКаналы[1][0];
   if(МаксМинДатаКаналы1[1][1]!=МаксМинДатаКаналы[1][1])
      МаксМинДатаКаналы1[1][1]=МаксМинДатаКаналы[1][1];
   
   if(КаналMaxИзменён || КаналMinИзменён)
      return(true);
   else return(false); 
  }
/* 
//+------------------------------------------------------------------+
//| Поиск пересечений каналов                                        |
//+------------------------------------------------------------------+
void ПоискПересеченийКаналов(int проверяемыйБар)
  {
   //пара прямых выбирается по принципу:
   // - если основные линии канала сходятся (знач. Mx<0), то выбор по основным;
   // - если основные линии канала расходятся (знач. Mx>0), то выбор по вспомогательным;
   // Сначала проверяем по основным, а если знач. Mx>0, то потом по доп.
   
   // формула расчёта пересечений прямых
   // составляем ур-ния прямых
   // формула прямой y=mx+C, где m - коэффициент наклона, С - смещение по оси ординат (по y)
   // здесь бары - ось х, а значения - ось у
   int A1x=iBarShift(NULL,0,МаксМинДатаКаналы[0][0],false);
   int A2x=iBarShift(NULL,0,МаксМинДатаКаналы[0][1],false);
   double A1y=NormalizeDouble(maxMinЗначение[0][0],Digits);
   double A2y=NormalizeDouble(maxMinЗначение[0][1],Digits);
   //для нахождения m подставим значения в формулу прямой и вычтем значения, для избавления от С
   double m =NormalizeDouble((A2y-A1y)/(A2x-A1x),8);
   
   int B1x=iBarShift(NULL,0,МаксМинДатаКаналы[1][0],false);
   int B2x=iBarShift(NULL,0,МаксМинДатаКаналы[1][1],false);
   double B1y=NormalizeDouble(maxMinЗначение[1][0],Digits);
   double B2y=NormalizeDouble(maxMinЗначение[1][1],Digits);   
   //для нахождения n подставим значения в формулу прямой и вычтем значения, для избавления от С
   double n=NormalizeDouble((B2y-B1y)/(B2x-B1x),8);
     
   if(m==n) return;
   
   double C1=NormalizeDouble(A1y-A1x*m,8);
   double C2=NormalizeDouble(B1y-B1x*n,8);
   
   int Mx=StrToInteger(DoubleToStr(MathCeil((C2-C1)/(m-n))));   //Координата Х в точке пересеч.
   
   if(MathAbs(Mx-проверяемыйБар)>1000) return;
   if(Mx-проверяемыйБар<=0){
      if(Bars-Mx<ArraySize(точкиПересеченийБары))
         точкиПересеченийБары[Bars-Mx]++;
      else{
         ArrayResize(точкиПересеченийБары, Bars-Mx+1);
         точкиПересеченийБары[Bars-Mx]++;
      }
   } else {
      C1=NormalizeDouble(B1y-B1x*m,8);
      C2=NormalizeDouble(A1y-A1x*n,8);
      Mx=StrToInteger(DoubleToStr(MathCeil((C2-C1)/(m-n))));   //Координата Х в точке пересеч.
   
      if(MathAbs(Mx)>1000) return;
      if(Mx-проверяемыйБар<=0){
         if(Bars-Mx<ArraySize(точкиПересеченийБарыДоп))
            точкиПересеченийБарыДоп[Bars-Mx]++;
         else{
            ArrayResize(точкиПересеченийБарыДоп, Bars-Mx+1);
            точкиПересеченийБарыДоп[Bars-Mx]++;
         }
      }
   } 
  }
*/   
//+------------------------------------------------------------------+
//| Поиск пересечений каналов                                        |
//+------------------------------------------------------------------+
void ПоискПересеченийЛиний(int проверяемыйБар, datetime проверяемыйМассивДат, double проверяемыйМассивЗначение)
  {
   //пара прямых выбирается по принципу:
   // - если основные линии канала сходятся (знач. Mx<0), то выбор по основным;
   // - если основные линии канала расходятся (знач. Mx>0), то выбор по вспомогательным;
   // Сначала проверяем по основным, а если знач. Mx>0, то потом по доп.
   
   // формула расчёта пересечений прямых
   // составляем ур-ния прямых
   // формула прямой y=mx+C, где m - коэффициент наклона, С - смещение по оси ординат (по y)
   // здесь бары - ось х, а значения - ось у
   int A1x=iBarShift(NULL,0,проверяемыйМассивДат[0][0],false);
   int A2x=iBarShift(NULL,0,проверяемыйМассивДат[0][1],false);
   double A1y=NormalizeDouble(проверяемыйМассивЗначение[0][0],Digits);
   double A2y=NormalizeDouble(проверяемыйМассивЗначение[0][1],Digits);
   //для нахождения m подставим значения в формулу прямой и вычтем значения, для избавления от С
   double m =NormalizeDouble((A2y-A1y)/(A2x-A1x),8);
   
   int B1x=iBarShift(NULL,0,проверяемыйМассивДат[1][0],false);
   int B2x=iBarShift(NULL,0,проверяемыйМассивДат[1][1],false);
   double B1y=NormalizeDouble(проверяемыйМассивЗначение[1][0],Digits);
   double B2y=NormalizeDouble(проверяемыйМассивЗначение[1][1],Digits);   
   //для нахождения n подставим значения в формулу прямой и вычтем значения, для избавления от С
   double n=NormalizeDouble((B2y-B1y)/(B2x-B1x),8);
     
   if(m==n) return;
   
   double C1=NormalizeDouble(A1y-A1x*m,8);
   double C2=NormalizeDouble(B1y-B1x*n,8);
   
   int Mx=StrToInteger(DoubleToStr(MathCeil((C2-C1)/(m-n))));   //Координата Х в точке пересеч.
   
   if(MathAbs(Mx-проверяемыйБар)>1000) return;
   if(Mx-проверяемыйБар<=0){
      if(Bars-Mx<ArraySize(точкиПересеченийБары))
         точкиПересеченийБары[Bars-Mx]++;
      else{
         ArrayResize(точкиПересеченийБары, Bars-Mx+1);
         точкиПересеченийБары[Bars-Mx]++;
      }
   } else {
      C1=NormalizeDouble(B1y-B1x*m,8);
      C2=NormalizeDouble(A1y-A1x*n,8);
      Mx=StrToInteger(DoubleToStr(MathCeil((C2-C1)/(m-n))));   //Координата Х в точке пересеч.
   
      if(MathAbs(Mx)>1000) return;
      if(Mx-проверяемыйБар<=0){
         if(Bars-Mx<ArraySize(точкиПересеченийБарыДоп))
            точкиПересеченийБарыДоп[Bars-Mx]++;
         else{
            ArrayResize(точкиПересеченийБарыДоп, Bars-Mx+1);
            точкиПересеченийБарыДоп[Bars-Mx]++;
         }
      }
   } 
  }  
  
  
//+------------------------------------------------------------------+
