//+------------------------------------------------------------------+
//|                                 ДвижСмещТиковСДвижСмещЦен+ТЛ.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
//выводит разницу тиков между текущим и прошлым баром
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot ДвижСмещТиковСДвижСмещЦен
#property indicator_label1  "ДвижСмещТиковСДвижСмещЦен+"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWheat
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- extern parameters
extern string  Символ = "EURUSDb";    //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
int            Период;    //Время исполнения
extern int     КолБаров = 2;    //Кол-во баров в эспирации //1
extern int     КолЭспираций = 1;    //Кол-во проверяемых эспираций //1

//--- indicator buffers
double   Индик[];   //РазницаТиковВБарах

bool     старт;
//int      Bar;
datetime ТекущийТаймфрейм=0;

datetime МаксМинВремяЛок[2][2];     //МаксМинВремя[0-Макс, 1-Мин][0-Max1/Min1, 1-Max2/Min2]
double   МаксМинЗначениеЛок[2][2];  //МаксМинЗначение[0-Макс, 1-Мин][0-Max1/Min1, 1-Max2/Min2]
string   short_name, НазваниеЛиний[2];
//bool     Стоп, sМаксМинЛок[2][2], sМаксМинГлоб[2][2];   //, Лок, Глоб   //Массив для контроля заполненности точек тренд. линий
double   ind1, ind2, ind3;      //Значения индикатора(ind1 - 1-й бар, ind2 - 2-й бар, ...)
string   Отчёт;

int      wind_ex; 

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,Индик);

   short_name=WindowExpertName()+"("+string(КолБаров)+"/"+string(КолЭспираций)+")";
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
   
//   ChartRedraw();
   
   //if(rates_total<b1+2)
   if(Bars<КолБаров*(КолЭспираций+1)+2)
      return(rates_total);
   
   if(ТекущийТаймфрейм!=Time[0])
      {
       //если не нужны промеж. данные
       ПоискБлижайшихМаксМин(1);
       //иначе - разблокировать код ниже (7 строк)
/*       int ПоследнийБар=iBarShift(NULL,0,ТекущийТаймфрейм,false);
       if(ПоследнийБар>0)  //if(prev_calculated>0)
         for(int Bar=ПоследнийБар; Bar>0; Bar--) //for(Bar=rates_total-prev_calculated; Bar>0; Bar--)//for(Bar=Bars-2; Bar>=0; Bar--)
            {Индик[Bar]=NormalizeDouble((Volume[Bar]-Volume[Bar+b1])*(Close[Bar]-Close[Bar+1]-Close[Bar+b1]+Close[Bar+1+b1]),Digits);
             
             ПоискБлижайшихМаксМин(Bar);
            }
*/       
       ПереносТрендовыхЛиний();
       
       ТекущийТаймфрейм=Time[0];
      }
   else
      //Индик[0]=NormalizeDouble((Volume[0]-Volume[b1])*(Close[0]-Close[1]-Close[b1]+Close[1+b1]),Digits);
      Индик[0]=NormalizeDouble((СредняяVolume(0,КолБаров)-СредняяVolume(КолБаров,КолБаров*КолЭспираций))*(Close[0]-Close[КолБаров]*(1+1/КолЭспираций)-Close[КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);    
      
//   Bar=0;
   ChartRedraw();
   
//--- return value of prev_calculated for next call
   return(rates_total);
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

   for(int bar=Bars-КолБаров*(КолЭспираций+1)-2; bar>0; bar--)
      //Индик[Bar]=NormalizeDouble((Volume[Bar]-Volume[Bar+b1])*(Close[Bar]-Close[Bar+1]-Close[Bar+b1]+Close[Bar+1+b1]),Digits);
      Индик[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(КолБаров,КолБаров*КолЭспираций))*(Close[bar]-Close[bar+КолБаров]*(1+1/КолЭспираций)-Close[bar+КолБаров*(КолЭспираций+1)]/КолЭспираций/КолБаров),Digits);    

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
   
   ТекущийТаймфрейм=Time[0];
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
void ПоискБлижайшихМаксМин(int ПроверяемыйБар)
  {
   char c, точекMin=0, точекMax=0;
   
   for(int Bar=ПроверяемыйБар;Bar<Bars-3-КолБаров*(КолЭспираций+1);Bar++){
      c=РасчётЛокДанных(Bar);
      if(c<0){
          Отчёт="Недостаточно данных в истории.";
          Print(Отчёт);
          return;
      } else if(c==2){ // для максимумов
          if(точекMax==0){
            МаксМинВремяЛок[0][1]=Time[Bar+1];
            МаксМинЗначениеЛок[0][1]=ind2;
          } else{
            МаксМинВремяЛок[0][0]=Time[Bar+1];
            МаксМинЗначениеЛок[0][0]=ind2;
          } 
/*          МаксМинВремяЛок[0][1]=МаксМинВремяЛок[0][0];
          МаксМинВремяЛок[0][0]=Time[Bar+1];
          
          МаксМинЗначениеЛок[0][1]=МаксМинЗначениеЛок[0][0];
          МаксМинЗначениеЛок[0][0]=ind2;
*/          
          точекMax++;
      } else if(c==3){ // для минимумов     
          if(точекMin==0){
            МаксМинВремяЛок[1][1]=Time[Bar+1];
            МаксМинЗначениеЛок[1][1]=ind2;
          } else{
            МаксМинВремяЛок[1][0]=Time[Bar+1];
            МаксМинЗначениеЛок[1][0]=ind2;
          }
 /*         МаксМинВремяЛок[1][1]=МаксМинВремяЛок[1][0];
          МаксМинВремяЛок[1][0]=Time[Bar+1];
          МаксМинЗначениеЛок[1][1]=МаксМинЗначениеЛок[1][0];
          МаксМинЗначениеЛок[1][0]=ind2;
*/          
          точекMin++;
      }
      
//      if(МаксМинВремяЛок[0][1]>=Time[Bars-1] && МаксМинВремяЛок[1][1]>=Time[Bars-1]) 
  //       Bar=Bars;    
      if(точекMin>1 && точекMax>1) break;   
   }   
  }
    
//+------------------------------------------------------------------+
//| Расчёт локальных экстримумов                                     |
//+------------------------------------------------------------------+
//bool РасчётДанных(int Предел)
char РасчётЛокДанных(int ПроверяемыйБар)
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
      return(2);
             
   if(ind2<ind1 && ind2<ind3) // минимум по 3-м барам
      return(3);
        
//---  
   return(1);  
  }
/*  
//+------------------------------------------------------------------+
//| Расчёт локальных экстримумов                                     |
//+------------------------------------------------------------------+
//bool РасчётДанных(int Предел)
char РасчётЛокДанных()
  {
   ind1 = Индик[Bar];
   ind2 = Индик[Bar+1];
   ind3 = Индик[Bar+2];
      
   for(int i1=Bar+3;i1<Bars-2-b1 && ind2==ind3;i1++)
 //     ind3 = Индик[i1];
      if(ind3 != Индик[i1]){
          ind3 = Индик[i1];
          break;
      }
   
   if(ind2==ind3) 
      return(1);
         
   if(ind2>ind1 && ind2>ind3) 
      return(-2);
             
   if(ind2<ind1 && ind2<ind3) 
      return(-3);
        
//---  
   return(-1);  
  }
*/
//+------------------------------------------------------------------+
//| Перенос трендовых линий                                          |
//+------------------------------------------------------------------+
void ПереносТрендовыхЛиний()
  {
   for(int i=0;i<ArraySize(НазваниеЛиний);i++)
      {//--- сбросим значение ошибки 
       ResetLastError(); 
       if(i==0)
         {if(!ObjectMove(0,НазваниеЛиний[i],1,МаксМинВремяЛок[0][1],МаксМинЗначениеЛок[0][1])) 
               Print(__FUNCTION__, 
                     ": не удалось переместить 1-ю точку привязки линии ",НазваниеЛиний[i],"! Код ошибки = ",GetLastError());
            
          ResetLastError();
          if(!ObjectMove(0,НазваниеЛиний[i],0,МаксМинВремяЛок[0][0],МаксМинЗначениеЛок[0][0])) 
               Print(__FUNCTION__, 
                     ": не удалось переместить 2-ю точку привязки линии ",НазваниеЛиний[i],"! Код ошибки = ",GetLastError());
         }
       else if(i==1)
         {if(!ObjectMove(0,НазваниеЛиний[i],1,МаксМинВремяЛок[1][1],МаксМинЗначениеЛок[1][1])) 
               Print(__FUNCTION__, 
                     ": не удалось переместить 1-ю точку привязки линии ",НазваниеЛиний[i],"! Код ошибки = ",GetLastError());
            
          ResetLastError();
          if(!ObjectMove(0,НазваниеЛиний[i],0,МаксМинВремяЛок[1][0],МаксМинЗначениеЛок[1][0])) 
               Print(__FUNCTION__, 
                     ": не удалось переместить 2-ю точку привязки линии ",НазваниеЛиний[i],"! Код ошибки = ",GetLastError());
         }
      }
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int СредняяVolume(int bar, int Кол_во )
  {
   int сумма=0;
   for(int i=0;i<Кол_во;i++)
      сумма+=int(Volume[bar+i]);
   
   return int(NormalizeDouble(сумма/Кол_во,0));
  }  
  
//+------------------------------------------------------------------+
