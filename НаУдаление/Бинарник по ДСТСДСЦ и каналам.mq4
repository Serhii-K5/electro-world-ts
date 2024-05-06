//+------------------------------------------------------------------+
//|                                Бинарник по ДСТСДСЦ и каналам.mq4 |
//|                                                                Я |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Я"
#property link      ""
#property version   "1.00"
#property strict
#property description "Бинарник по пересечениям ДСТСДСЦ и каналов"

extern string Символ = "EURUSDab";   //Валютная пара графика
input string  простые="AUDUSDb NZDUSDb CHFJPYb EURGBPb";  //.........простые: 
//AUD/USD и NZD/USD. Сильно похожи между собой и хорошо коррелируемые. Отличается чувствительностью к стоимости на металлы, а также на погодные изменения. Цены на эти пары растут, когда повышаются стоимость металлов. Курс AUD/USD и NZD/USD может понижаться, когда металлы дешевеют, а погода ухудшается. Достаточно легко прогнозируемый актив, соответственно подходит для трейдинга начинающим.
//CHF/JPY. Достаточно легко прогнозируется, что отлично подойдет новичкам. Часто наблюдается запоздалое повторение движений за парой EUR/JPY.
//EUR/GBP. Спокойная, слабо волатильная пара.
input string  тяжёлые="EURUSDb GBPUSDb USDCADb";  //.........тяжёлые: 
//EUR/USD. Наиболее популярная валютная пара на всех финансовых рынках. В связи с этим по ней торгует очень большое количество профессиональных трейдеров, что делает прогнозирование ее движения довольно проблематичным. Поэтому новичкам не рекомендуется торговать по EUR/USD.
//GBP/USD. Наблюдается достаточно высокая волатильность, а также частое пробитие уровней. Пара GBP/USD очень чувствительна к выходу экономических новостей по Великобритании.
//USD/CAD. Часто эту валютную пару называют сырьевой, так как она отражает ценовое движение нефти. Когда стоимость нефти повышается, USD/CAD тоже. Следовательно, при торговле «канадцем» необходимо учитывать котировки нефти. Для новичков также не советуется.
input string  непредсказуемые="EURJPYb GBPJPYb"; //.........непредсказуемые: 
//EUR/JPY и GBP/JPY. Эти валютные пары можно назвать непредсказуемыми и опасными. Новичкам крайне не советуется торговать по ним.

extern bool   Торговля = True; //Разрешение на торговлю 
extern int    bar   = 3;   // Количество баров для расчета = 3
extern int    ПунктовВБаре  = 10;   // Количество пунктов в баре для расчета = 10
extern int    ВремяФлета    = 60;   // Время для флета = 60с (Период*60)
extern int    ВремяЗадержки = 5;   // Время задержки данных для нового бара = 5с
extern int    МаксОрдеров = 2;   // Максимум одновременно открытых ордеров = 2

extern int    Период    = PERIOD_M1;   //Время исполнения
extern double Lot    = 5; //Лот
extern int    Slippege  = 3; //Проскальзывание
extern int    Проигрышей  = 3; //максимум проигрышных подряд ставок

extern uchar  ТипСхемы = 1;  //Тип схемы
input string  ТипыСхем = "Типы схем";  //"--Таблица выбора типа схемы--"
input string  Схема0 = "всегда ставка=Lot";    // 0
input string  Схема1 = "выигрыш=+Лот*0,53 за ход при проигрыше";    // 1
input string  Схема2 = "предыдущая ставка *2,8 при проигрыше";    // 2
input string  Схема3 = "суммарный выигрыш=Lot*0,53";    // 3
input string  Схема4 = "1-я ставка выигрыш=Lot*0,53,а у остальных выигрыш=0";    // 4

bool     Старт=False;
int      Множитель, Bar;
double   СхемаСтавок[10], СуммаПроигрыша=0;
double   БарВПунктах[], min, max;  //Цена открытия бара
datetime БарВПунктахТ[];    //Время открытия бара
double   VТика[], minV=-1, maxV=-1;
double   Sбара[], minS=-1, maxS=-1;

datetime ТекущийТаймфрейм=0;
string   Str, text, Отчёт, РезСтавки, Отчётbuy;
double   Lot0, x;
char     НаправлТренда=0;

uchar    ОткрытоОрдеров=0;
int      IDОрдера[]; //№ ордера ставки
int      Ставка[]; //Размер лота из СхемаСтавок[10]
int      НомерСтавки=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
//--- получение handle текущего графика
  {long handle=ChartID();
   if(handle>0) // если получилось, дополнительно настроим
     {//--- Приведение разрядности к единому стандарту
      if(Digits == 3 || Digits == 5)
         Slippege *= 10;

      //определение уровня
      Множитель=1;
      for(int i=0; i<Digits; i++)
         Множитель*=10;

      //--- Установка периода графика
      //ChartSetSymbolPeriod(0,NULL,Период);
      if(!ChartSetSymbolPeriod(0,Символ,Период))
         ChartSetSymbolPeriod(0,Символ,Период);

      //--- сброс значения ошибки
      ResetLastError();
      //--- установка значения приближеня/отдаления графика (дальше(0)-ближе(5))
      ChartSetInteger(handle,CHART_SCALE,0,5);

      //--- сброс значения ошибки
      ResetLastError();
      //--- отображение в виде свечей
      ChartSetInteger(handle,CHART_MODE,CHART_CANDLES);

      //--- установить режим отображения тиковых объемов
      // ChartSetInteger(handle,CHART_SHOW_VOLUMES,CHART_VOLUME_TICK);
      ////--- отключим автопрокрутку
      //    ChartSetInteger(handle,CHART_AUTOSCROLL,false);
      //  //--- установим отступ правого края графика
      // ChartSetInteger(handle,CHART_SHIFT,true);
     }

   if(!Старт)  //if(Старт==False)
     {Print(StringConcatenate("Начальный баланс=",AccountBalance()));
      Shema();
     }
   x=NormalizeDouble(ПунктовВБаре,0);
   x=NormalizeDouble(x/Множитель,Digits);
   
   Старт=True;
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {Отчёт="";
   if((AccountBalance()<Lot && !Старт) || AccountInfoDouble(ACCOUNT_MARGIN_FREE)<Lot)
      {Отчёт=StringConcatenate("Торговля ОТКЛЮЧЕНА!!!  "," /n ","Необходимо пополнить баланс.(",AccountBalance(),")");
       Print(Отчёт);
       Comment(Отчёт);
       Торговля=False;
      }
   
   if(Symbol()!=Символ || Period()!=Период)
      {Символ=Symbol();
       Период=Period(); 
       OnInit(); 
//       return;
      }
   
   if(Старт)
      {ArrayResize(IDОрдера,МаксОрдеров);
       ArrayResize(Ставка,МаксОрдеров);
       if(!СтартоваяЗагрузка())
         {Старт=True; return;}
       else
         Старт=False;
       Str=StringConcatenate("BO exp:",Период*60);
       //IDОрдера[0]=-1;
      }
   
//---Обработка результата ставки
   if(ОткрытоОрдеров>0)
      РезультатОрдера();
   
   if(ТекущийТаймфрейм!=Time[0])
      {Bar=iBarShift(NULL,0,ТекущийТаймфрейм,True)-1;
       for(int i=1; i<=Bar; i++)
         {ArrayResize(Sбара,ArraySize(Sбара)+1);
          ArrayResize(VТика,ArraySize(VТика)+1);
          Движбара();
          СкоростьТика();
          БарыПоПунктах();
         }
       ТекущийТаймфрейм=Time[0];
      }
   else
      {Движбара();
       СкоростьТика();
       БарыПоПунктах();
      }
   
   Bar=0;
   if(ArraySize(БарВПунктах)<bar)
      return;
   
//---Определение флета/тренда по инд. БарыПоПунктах   
   //---флет по смещению
   НаправлТренда=0;
   if(БарВПунктах[0]<БарВПунктах[bar-1] && БарВПунктах[0]<БарВПунктах[bar-2])
      НаправлТренда=-1;
   else if(БарВПунктах[0]>БарВПунктах[bar-1] && БарВПунктах[0]<=БарВПунктах[bar-2])
      НаправлТренда=1;
//   else
  //    НаправлТренда=0;

   //---флет по времени   
   int t=TimeCurrent()-БарВПунктахТ[Bar];
   int t1=БарВПунктахТ[Bar]-БарВПунктахТ[Bar+1];
//   
   if(t>ВремяФлета || (t<=ВремяЗадержки && t1>ВремяФлета))   
      {НаправлТренда=0; Отчёт=StringConcatenate("Отмена торговли из-за флета по времени. (t=",t,"; t1=",t1);} 

//---Поправка направления по пробою maxS/minS   
   if(Sбара[Bar+1]<minS && Open[Bar]>Close[Bar] && БарВПунктах[0]>Close[Bar])
      {НаправлТренда=-1; Отчёт=StringConcatenate("Тренд задан по пробою minS. (minS=",minS,"; Sбара[",Bar+1,"]=",Sбара[Bar+1]);}
   else if(Sбара[Bar+1]>maxS && Open[Bar]<Close[Bar] && БарВПунктах[0]<Close[Bar])
      {НаправлТренда=1; Отчёт=StringConcatenate("Тренд задан по пробою maxS. (minS=",maxS,"; Sбара[",Bar+1,"]=",Sбара[Bar+1]);}

   
   Отчёт=StringConcatenate(Отчёт,"; Направление=",НаправлТренда,"\r\n","БарВПунктах[");
   for(int i=0;i<ArraySize(БарВПунктах);i++)
      Отчёт=StringConcatenate(Отчёт,БарВПунктах[i],"; ");
   Отчёт=StringConcatenate(Отчёт,"]; max=",NormalizeDouble(max,Digits),"; min=",NormalizeDouble(min,Digits));
   
   Отчёт=StringConcatenate(Отчёт,"\r\n","Sбара[");
   int a=(ArraySize(Sбара)>10) ?11 :1;
   for(int i=ArraySize(Sбара)-a;i>=0;i--) //for(int i=0;i<ArraySize(Sбара);i++)
      Отчёт=StringConcatenate(Отчёт,Sбара[i],"; ");
   Отчёт=StringConcatenate(Отчёт,"]; maxS=",NormalizeDouble(maxS,Digits),"; minS=",NormalizeDouble(minS,Digits));
   
   
   if(НаправлТренда==0 || !Торговля || ОткрытоОрдеров>1 || (ОткрытоОрдеров>0 && СуммаПроигрыша<0) || ОткрытоОрдеров>=МаксОрдеров) 
      {Comment(Отчёт); return;}
   
   for(НомерСтавки=0; НомерСтавки<МаксОрдеров; НомерСтавки++)
      if(IDОрдера[НомерСтавки]<0) 
         break;//{НомерСтавки++; break;}
   
   if(IDОрдера[НомерСтавки]<0)   //перестраховка
      Lot0=СхемаСтавок[Ставка[НомерСтавки]];
   else 
      return;
   
   if(Lot0>0 && AccountInfoDouble(ACCOUNT_MARGIN_FREE)<Lot0)
      Lot0=MathFloor(AccountInfoDouble(ACCOUNT_MARGIN_FREE));

   if(НаправлТренда>0 && Lot0>=Lot)
       OpenForBuy();   //Тренд ожидается вверх, будем покупать
   else if(НаправлТренда<0 && Lot0>=Lot)
       OpenForSell();  //Тренд ожидается вниз, будем продавать
   else
      Отчётbuy=StringConcatenate("\r\n Отмена торговли.");
      
   Отчёт=StringConcatenate(Отчёт,"\r\n" ,РезСтавки,"; ",Отчётbuy);
//   Отчёт=StringConcatenate(Отчёт,"\r\n" ,РезСтавки,"; ",Отчётbuy,"; Lot0",Lot0,"; id=",IDОрдера[НомерСтавки]," Ставка=",НомерСтавки," \r\n ");
   Comment(Отчёт);
  
  }

//+------------------------------------------------------------------+
//| Модуль загрузки начальных данных                                 |
//+------------------------------------------------------------------+
bool СтартоваяЗагрузка()
  {if(СхемаСтавок[0]==0)
     {Отчёт="Не задано значение ''Lot''";
      Comment(Отчёт); Print(Отчёт);
      return(false);
     }

   ArrayFill(IDОрдера,0,ArraySize(IDОрдера),-1);  //Заполнение всего массива "-1"
   ArrayFill(Ставка,0,ArraySize(Ставка),0);  //Заполнение всего массива "0"
   
//---Подготовка индикатора Движбара   
   if(Bars>5)
     {ArrayResize(Sбара,2);
      ArrayFill(Sбара,0,ArraySize(Sбара),-1);  //Заполнение всего массива "-1"
      Bar=1;
      while((minS<0 && Bar<Bars-5) || (maxS<0 && Bar<Bars-5))
         {ArrayResize(Sбара,ArraySize(Sбара)+1);
          Движбара(); 
          Bar++;
         }
//---Подготовка индикатора СкоростьТика   
      ArrayResize(VТика,2);
      ArrayFill(VТика,0,ArraySize(VТика),-1);  //Заполнение всего массива "-1"
      Bar=1;
      while((minV<0 && Bar<Bars-5) || (maxV<0 && Bar<Bars-5))
         {ArrayResize(VТика,ArraySize(VТика)+1);
          СкоростьТика();
          Bar++;
         }
     }

//---Подготовка массива для индикатора флета (бары по пунктах)   
   if(bar>0)
      {ArrayResize(БарВПунктах,bar);
       ArrayResize(БарВПунктахТ,bar);
      }
   else 
      {ArrayResize(БарВПунктах,1);
       ArrayResize(БарВПунктахТ,1);
       bar=1;
      }
   
   ArrayFill(БарВПунктах,0,ArraySize(БарВПунктах),-1);  //Заполнение всего массива "-1"
   
   Bar=0;
   Движбара();
   СкоростьТика();
   
   return(true);
  }

//+------------------------------------------------------------------+
//| Заполнение значений для массива Движбара[] до 0-го бара          |
//+------------------------------------------------------------------+
void Движбара()
  {int Bar1=ArraySize(Sбара)-1;
   int n=1;
   if(Старт)
      {for(int i=ArraySize(Sбара)-1; i>0;i--)
         Sбара[i]=Sбара[i-1];
       
       Sбара[0]=(Open[Bar]>Close[Bar])?NormalizeDouble(((High[Bar]-Low[Bar])*2+Open[Bar]-Close[Bar])*Множитель,0) :NormalizeDouble(((High[Bar]-Low[Bar])*2-Open[Bar]+Close[Bar])*Множитель,0);
       Bar1=1;
       if(ArraySize(Sбара)-2>Bar1)
         while(Sбара[Bar1]==Sбара[Bar1+n] && ArraySize(Sбара)>Bar1+n)
            n++;
       if(ArraySize(Sбара)<=Bar1+n) 
         n--;
       
       if(Sбара[Bar1]==Sбара[Bar1+n]) return;
      }
   else 
      {Sбара[Bar1]=(Open[Bar]>Close[Bar])?NormalizeDouble(((High[Bar]-Low[Bar])*2+Open[Bar]-Close[Bar])*Множитель,0) :NormalizeDouble(((High[Bar]-Low[Bar])*2-Open[Bar]+Close[Bar])*-Множитель,0);
       Bar1-=1;
       while(Sбара[Bar1]==Sбара[Bar1-n] && Bar1>=0)
         n++;
       if(ArraySize(Sбара)<=Bar1+n) 
         n--;
         
       if(Sбара[Bar1]==Sбара[Bar1-n]) return;
      }
   
   if(Sбара[Bar1]>Sбара[Bar1+n] && Sбара[Bar1]>Sбара[Bar1-1])
      {if(maxS<0 || (maxS>0 && maxS<Sбара[Bar1]))
         maxS=Sбара[Bar1];
      }
   else if(Sбара[Bar1]<Sбара[Bar1+n] && Sбара[Bar1]<Sбара[Bar1-1])
      {if(minS<0 || (minS>0 && minS<Sбара[Bar1]))
         minS=Sбара[Bar1];
      }
  } 

//+------------------------------------------------------------------+
//| Заполнение значений для массива СкоростьТика[] до 0-го бара      |
//+------------------------------------------------------------------+
void СкоростьТика()
  {double a;
   long z;
   
   z=(TimeDay(TimeCurrent())-TimeDay(Time[Bar]))*86400+(TimeHour(TimeCurrent())-TimeHour(Time[Bar]))*3600+(TimeMinute(TimeCurrent())-TimeMinute(Time[Bar]))*60+TimeSeconds(TimeCurrent()); 
   a=NormalizeDouble(Volume[Bar],1);
   VТика[Bar]=(z!=0)?NormalizeDouble(a/z,5) :0;
   
   int Bar1=Bar+2;
   if(ArraySize(VТика)>Bar1)
     {int n=1;
      if(VТика[Bar1]==VТика[Bar1+1])
         for(n=1; VТика[Bar1]==VТика[Bar1+n] && n<Bars-2; n++)
            continue;
            
      if(VТика[Bar1]>VТика[Bar1+n] && VТика[Bar1]>VТика[Bar1-1])
         {if(maxV<0 || (maxV>0 && maxV<VТика[Bar1]))
            maxV=VТика[Bar1];
         }
      else if(VТика[Bar1]<VТика[Bar1+n] && VТика[Bar1]<VТика[Bar1-1])
         {if(minV<0 || (minV>0 && minV<VТика[Bar1]))
            minV=VТика[Bar1];
         }
     }
  } 

//+------------------------------------------------------------------+
//| Заполнение значений для массива Движбара[] до 0-го бара          |
//+------------------------------------------------------------------+
void БарыПоПунктах()
   {//---Поиск начальной кратной точки
    double cl=Close[Bar];
    double x1=NormalizeDouble(cl/x,0);
    if(БарВПунктах[0]<0)
      {min=NormalizeDouble(x1*x,Digits); //ближайший минимум для баров по пунктах
       max=NormalizeDouble(min+x,Digits); //ближайший максимум для баров по пунктах
      }
//    else
 //     БарВПунктах[0]=NormalizeDouble(x1*x,Digits);
    
    while(min>cl)
      {for(int i=bar-1; i>0; i--)
         {БарВПунктах[i]=NormalizeDouble(БарВПунктах[i-1],5);
          БарВПунктахТ[i]=БарВПунктахТ[i-1];
         }
       БарВПунктах[0]=min;
       БарВПунктахТ[0]=TimeCurrent();
       max=min+x;
       min-=x;
      }
    while(max<cl)
      {for(int i=bar-1; i>0; i--)
         {БарВПунктах[i]=NormalizeDouble(БарВПунктах[i-1],5);
          БарВПунктахТ[i]=БарВПунктахТ[i-1];
         }
       БарВПунктах[0]=max;
       БарВПунктахТ[0]=TimeCurrent();
       min=max-x;;
       max+=x;
      }   
    if(БарВПунктах[0]>0)
      {min=NormalizeDouble(БарВПунктах[0]-x,Digits);   //ближайший минимум для баров по пунктах
       max=NormalizeDouble(БарВПунктах[0]+x,Digits); //ближайший максимум для баров по пунктах
      }
   }

//+------------------------------------------------------------------+
//| Открытие ордера на покупку                                       |
//+------------------------------------------------------------------+
void OpenForBuy()
  {//открытие ордера на покупку
   int ticket=OrderSend(Symbol(),OP_BUY,Lot0,Ask,Slippege,0,0,Str);
   if(ticket<0)
     {Print("Функция OrderSend на покупку завершилась с ошибкой #",GetLastError());
      Comment("Функция OrderSend на покупку завершилась с ошибкой #",GetLastError());
     }
   else
     {IDОрдера[НомерСтавки]=ticket; //IDОрдера[0][0]=ticket;
      ОткрытоОрдеров++;
      Отчётbuy=StringConcatenate("Открыт ордер ",ОткрытоОрдеров," на покупку; Lot0=",Lot0);
     }
   Comment(Отчётbuy);
//---
   return;
  }

//+------------------------------------------------------------------+
//| Открытие ордеров на продажу                                      |
//+------------------------------------------------------------------+
void OpenForSell()
  {//открытие ордера на продажу
//   Str=StringConcatenate("BO exp:",Период*60);

   int ticket=OrderSend(Symbol(),OP_SELL,Lot0,Bid,Slippege,0,0,Str);
   if(ticket<0)
     {Print("Функция OrderSend на продажу завершилась с ошибкой #",GetLastError());
      Comment("Функция OrderSend на продажу завершилась с ошибкой #",GetLastError());
     }
   else
     {IDОрдера[НомерСтавки]=ticket;
      ОткрытоОрдеров++;
      Отчётbuy=StringConcatenate("Открыт ордер ",ОткрытоОрдеров," на продажу; Lot0=",Lot0);
     }
   Comment(Отчётbuy);
//---
   return;
  }

//+------------------------------------------------------------------+
//| Обработка результата ставки                                      |
//+------------------------------------------------------------------+
void РезультатОрдера()
  {РезСтавки="";
   text="";   
   for(int i=0; i<ArraySize(IDОрдера); i++)
      if(IDОрдера[i]>0)
         if(OrderSelect(IDОрдера[i],SELECT_BY_TICKET,MODE_TRADES) && OrderCloseTime()>0)
            {СуммаПроигрыша=NormalizeDouble(СуммаПроигрыша+OrderProfit(),2);
             if(СуммаПроигрыша>0)
               СуммаПроигрыша=0;
                
             if(OrderProfit()>0)
               {РезСтавки=StringConcatenate(РезСтавки,"Выиграл ордер ");
                
                if(ТипСхемы>0)
                  Ставка[i]=(СуммаПроигрыша<0) ?1 :0;
                else
                  Ставка[i]=0;
                //IDОрдера[ArraySize(IDОрдера)-1]=-1;
               }
             else if(OrderProfit()<0)
               {РезСтавки=StringConcatenate(РезСтавки,"Проиграл ордер ");
                if(ТипСхемы>0)
                  {Ставка[i]++;
//                   if(Ставка==4) //ограничение не более 161
                   if(Ставка[i]>Проигрышей-1) //ограничение не более 57
                     Ставка[i]=1;
                  }
                else
                  Ставка[i]=0;  
                //IDОрдера[i]=(IDОрдера[i]>1) ?0 :IDОрдера[i]++; //для отмены повторного выставления проигравшей ставки независимо от ожиданий
               }
             else 
               РезСтавки=StringConcatenate(РезСтавки,"Ничия. Ордер "); 
             
             РезСтавки=StringConcatenate(РезСтавки,IDОрдера[i],"! Откр.=",OrderOpenPrice()," Закр.= ",OrderClosePrice(),"; на сумму=",NormalizeDouble(OrderProfit(),2),"; СуммаПроигрыша=",NormalizeDouble(СуммаПроигрыша,2)," \r\n ");
             text=StringConcatenate(text,"\r\n ",РезСтавки);
             Print(РезСтавки);
             IDОрдера[i]=-1;
             ОткрытоОрдеров--;
            }
   if(text!="")
      Comment(text);
  }

//+------------------------------------------------------------------+
//| Функция загрузки сетки ставок                                    |
//+------------------------------------------------------------------+
void Shema()
  {//double КоєфЛота=Lot/5;
//Для схемы 5/19/57/161/446/1225/3356 или (за ставку +Lot0*0.53)
   double ЛотМин=0, ЛотМакс=0;

   if(AccountInfoString(ACCOUNT_CURRENCY)=="UAH")
     {ЛотМин=5; ЛотМакс=6000;}
   else
      if(AccountInfoString(ACCOUNT_CURRENCY)=="USD")
        {ЛотМин=1; ЛотМакс=300;}
      else
         if(AccountInfoString(ACCOUNT_CURRENCY)=="EUR")
           {ЛотМин=1; ЛотМакс=250;}
         else
            if(AccountInfoString(ACCOUNT_CURRENCY)=="RUB")
              {ЛотМин=10; ЛотМакс=15000;}

   if(Lot<ЛотМин)
     {Lot=ЛотМин;
      Отчёт=StringConcatenate("Лот не может быть < ",Lot,". Значение исправлено на ",Lot);
      Alert(Отчёт);
      Comment(Отчёт);
      Print(Отчёт);
     }

   double Перем=NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_FREE)/500,3);
   double Перем1=NormalizeDouble(Перем/Lot,3);
   double a=MathFloor(Перем); //a=MathRound(Перем);
   if(Перем1<0.97)
     {string tx;
      if(Lot>=ЛотМин && MathRound(Перем)>=ЛотМин)
        {tx=StringConcatenate("Размер лота выше расчётного. Риск увеличен на ",MathFloor((1-Перем1)*100)," %");
         if(Lot!=a)  //if(Lot!=MathRound(Перем))
           {tx=StringConcatenate(tx," ","\r\n ","Рекомендуется лот=",MathFloor(Перем)," \r\n","Для продолжения нажмите ''ОК''");
            int choice=MessageBox(tx,NULL,MB_OK|MB_ICONWARNING);
/*            
            int choice=MessageBox(tx,NULL,MB_YESNO|MB_ICONWARNING);
            ResetLastError();
            if(choice==IDYES)
              {Lot=MathFloor(Перем); MessageBox("Лот изменён и ="+DoubleToStr(MathFloor(Перем)),NULL,MB_OK|MB_ICONWARNING);}
*/           
           }
        }
      else if(a<ЛотМин) //else if(MathRound(Перем)<ЛотМин)
         {tx=StringConcatenate("Размер лота выше расчётного из-за низкого значения свободных средств. Риск увеличен на ",MathFloor((1-Перем1)*100)," % ","\r\n",
                               "Рекомендуется увеличить значения свободных средств на ",MathFloor(AccountInfoDouble(ACCOUNT_MARGIN_FREE)-ЛотМин*500)," ",AccountInfoString(ACCOUNT_CURRENCY)," \r\n",
                               "Для продолжения нажмите ''ОК''");
            MessageBox(tx,NULL,MB_OK|MB_ICONWARNING);
            ResetLastError();
           }
     }
   else if(Перем1>1.03)
     {string tx=StringConcatenate("Размер лота ниже расчётного. Риск уменьшен на ",MathFloor((Перем1-1)*100)," %");
      if(Lot!=a)  //if(Lot!=MathRound(Перем))
         {tx=StringConcatenate(tx," ","\r\n ","Рекомендуется лот=",MathFloor(Перем)," \r\n","Для продолжения нажмите ''ОК''");
          int choice=MessageBox(tx,NULL,MB_OK|MB_ICONWARNING);
/*          
          int choice=MessageBox(tx,NULL,MB_YESNO|MB_ICONWARNING);
          ResetLastError();
          if(choice==IDYES)
            {Lot=MathFloor(Перем); MessageBox(StringConcatenate("Лот изменён и =",MathFloor(Перем)),NULL,MB_OK|MB_ICONWARNING);}
*/         
         }
     }

   СхемаСтавок[0]=Lot;
   ЛотМин=NormalizeDouble(Lot*0.92,2); //Сумма проигрыша
   if(ТипСхемы==1) //выигрыш +Lot*0.53 за ход
      for(int i=1; СхемаСтавок[i-1]<=ЛотМакс; i++)
        {СхемаСтавок[i]=NormalizeDouble(ЛотМин/0.53+Lot*(i+1),0);
         ЛотМин+=NormalizeDouble(СхемаСтавок[i]*0.92,2);
        }
   else if(ТипСхемы==2) //предыдущая ставка *2,8
      for(int i=1; СхемаСтавок[i-1]<=ЛотМакс; i++)
         {СхемаСтавок[i]=NormalizeDouble(СхемаСтавок[i-1]*2.8,0);
          ЛотМин+=NormalizeDouble(СхемаСтавок[i]*0.92,2);
         }
   else if(ТипСхемы==3) //суммарный выигрыш=Lot*0,53
      for(int i=1; СхемаСтавок[i-1]<=ЛотМакс; i++)
         {СхемаСтавок[i]=MathFloor(ЛотМин/0.53+Lot);
          ЛотМин+=NormalizeDouble(СхемаСтавок[i]*0.92,2);
         }
   else if(ТипСхемы==4) //1-я ставка выигрыш= +Лот*0,53,а у остальных=0
      for(int i=1; СхемаСтавок[i-1]<=ЛотМакс; i++)
         {СхемаСтавок[i]=NormalizeDouble(ЛотМин/0.53,0);
          ЛотМин+=NormalizeDouble(СхемаСтавок[i]*0.92,2);
         }
   else
     ТипСхемы=0;
  }

//+------------------------------------------------------------------+
