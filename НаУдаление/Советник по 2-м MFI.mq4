//+------------------------------------------------------------------+
//|                                          Советник по 2-м MFI.mq4 |
//|                                                                Я |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Я"
#property link      ""
#property version   "1.00"
#property strict
#property description "Советник по по 2-м MFI"

extern string символ = "EURUSD";     //Валютная пара графика
input string  простые="AUDUSD NZDUSD CHFJPY EURGBP";  //.........простые: 
//AUD/USD и NZD/USD. Сильно похожи между собой и хорошо коррелируемые. Отличается чувствительностью к стоимости на металлы, а также на погодные изменения. Цены на эти пары растут, когда повышаются стоимость металлов. Курс AUD/USD и NZD/USD может понижаться, когда металлы дешевеют, а погода ухудшается. Достаточно легко прогнозируемый актив, соответственно подходит для трейдинга начинающим.
//CHF/JPY. Достаточно легко прогнозируется, что отлично подойдет новичкам. Часто наблюдается запоздалое повторение движений за парой EUR/JPY.
//EUR/GBP. Спокойная, слабо волатильная пара.
input string  тяжёлые="EURUSD GBPUSD USDCAD";  //.........тяжёлые: 
//EUR/USD. Наиболее популярная валютная пара на всех финансовых рынках. В связи с этим по ней торгует очень большое количество профессиональных трейдеров, что делает прогнозирование ее движения довольно проблематичным. Поэтому новичкам не рекомендуется торговать по EUR/USD.
//GBP/USD. Наблюдается достаточно высокая волатильность, а также частое пробитие уровней. Пара GBP/USD очень чувствительна к выходу экономических новостей по Великобритании.
//USD/CAD. Часто эту валютную пару называют сырьевой, так как она отражает ценовое движение нефти. Когда стоимость нефти повышается, USD/CAD тоже. Следовательно, при торговле «канадцем» необходимо учитывать котировки нефти. Для новичков также не советуется.
input string  непредсказуемые="EURJPY GBPJPY"; //.........непредсказуемые: 
//EUR/JPY и GBP/JPY. Эти валютные пары можно назвать непредсказуемыми и опасными. Новичкам крайне не советуется торговать по ним.

extern bool    торговля = True; //Разрешение на торговлю 
extern int     начРаботы = 7;              //8 Начало работы (часы) // 0 - круглосуточно
extern int     конРаботы = 22;             //22 Конец работы (часы) // 24 - круглосуточно
//extern char   баровПроверки = 3;   //Кол-во проверяемых баров для макс/мин //5

extern int     времяЗадержки = 5;   // Время задержки данных для нового бара = 5с

extern int     период       = PERIOD_M5;   //Период графика
extern int     периодMFI1   = 3;           //Период MFI1
extern int     периодMFI2   = 5;           //Период MFI2
extern int     проскальзывание  = 1;       //Проскальзывание
input double   лот  = 0.01;                //Лот
input double   MaxРиск   =0.02;

int magicNumber=20240621;
datetime ТекущийТаймфрейм=0;
string   str, text, отчёт,отчётПокупки;
int      открытоОрдеров=0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
//--- получение handle текущего графика
  {long handle=ChartID();
   if(handle>0){ // если получилось, дополнительно настроим
     //--- Приведение разрядности к единому стандарту
      if(Digits == 3 || Digits == 5)
         проскальзывание *= 10;

      //--- Установка периода графика
      //ChartSetSymbolPeriod(0,NULL,период);
      if(!ChartSetSymbolPeriod(0,символ,период))
         ChartSetSymbolPeriod(0,символ,период);

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
   
   if(периодMFI1>периодMFI2){ 
      int p=периодMFI2;
      периодMFI2=периодMFI1;
      периодMFI1=p;
   }
//---
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {отчёт="";
   if(AccountBalance()<=0 || AccountInfoDouble(ACCOUNT_MARGIN_FREE)<=0){
      отчёт=StringConcatenate("торговля ОТКЛЮЧЕНА!!!  "," /n ","Необходимо пополнить баланс.(",AccountBalance(),")");
      Print(отчёт);
      Comment(отчёт);
      торговля=False;
   }
   
   if(Symbol()!=символ || Period()!=период){
//      символ=Symbol();
  //    период=Period(); 
      OnInit();
      return; 
   }

   if(TimeHour(Time[0])<начРаботы  || (TimeHour(Time[0])>конРаботы && открытоОрдеров==0))
      return;
/*   
  int handle=FileOpen("OrdersReport.csv",FILE_WRITE|FILE_CSV,"\t"); 
  if(handle<0) return(0); 
  // запишем заголовок в файл 
  FileWrite(handle,"#","Цена открытия","Время открытия","Символ","Лоты"); 
  int total=OrdersTotal(); 
  // записываем в файл только открытые ордера 
  for(int pos=0;pos<total;pos++) 
    { 
     if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false) continue; 
     FileWrite(handle,OrderTicket(),OrderOpenPrice(),OrderOpenTime(),OrderSymbol(),OrderLots()); 
    } 
  FileClose(handle);  
*/   
   
   
   
   if(ТекущийТаймфрейм!=Time[0]){
      Comment("");
      ТекущийТаймфрейм=Time[0];
      
      if(AccountFreeMargin()<(25000*лот))
         отчёт=StringConcatenate("Не достаточно свободных средств! Необходимо пополнить баланс.(",AccountBalance(),")");
         Comment(отчёт);
         return;
      
      int rez=Фильтр();
        
      //---флет по времени   
      int t=int(TimeCurrent()-Time[0]);
      
      if(t>времяЗадержки){
         rez=0;
         отчёт=StringConcatenate("Отмена торговли из-за задержки по времени. (t=",t,")");
      }
                
      if(rez==0 || !торговля){
         Comment(отчёт);
         return;
      }
/*      
      if(лот>0 && AccountInfoDouble(ACCOUNT_MARGIN_FREE)<лот*25000)
         лот=0.01;
      else return;
*/      
      if (IsTradeAllowed()){
         //-- Торговля разрешена
         if(rez>0)
             ОткрытьНаПокупку();   //Тренд ожидается вверх, будем покупать
         else if(rez<0)
             ОткрытьНаПродажу();  //Тренд ожидается вниз, будем продавать
         else
            отчётПокупки=StringConcatenate("Отмена торговли.");
      }
      
      отчёт=StringConcatenate(отчёт,"\r\n ",отчётПокупки);
      Comment(отчёт);
   }
  }

//+------------------------------------------------------------------+
//| Модуль загрузки начальных данных                                 |
//+------------------------------------------------------------------+
char Фильтр()
  {
   char rez=0;
   double MFI1=iMFI(NULL,0,периодMFI1,1);
   double MFI2=iMFI(NULL,0,периодMFI2,1);
      
   if(MFI1==100 && MFI2>=85)
      rez=2; 
   else if(MFI1==0 && MFI2<=15)
      rez=-2; 
   else{
      double MFI1_2=iMFI(NULL,0,периодMFI1,2);
      double MFI1_3=iMFI(NULL,0,периодMFI1,3);
      double MFI2_2=iMFI(NULL,0,периодMFI2,2);
      double MFI2_3=iMFI(NULL,0,периодMFI2,3);
      if(MFI1_2>MFI1 && MFI1_2>MFI1_3 && MFI1>60 && MFI2_2>MFI2 && MFI2_2>MFI2_3)
         rez=-1; 
      else if(MFI1_2<MFI1 && MFI1_2<MFI1_3 &&MFI1<40 && MFI2_2<MFI2 && MFI2_2<MFI2_3)
         rez=1; 
   }
   
   return rez;
  }

//+------------------------------------------------------------------+
//| Открытие ордера на покупку                                       |
//+------------------------------------------------------------------+
void ОткрытьНаПокупку()
  {//открытие ордера на покупку
   int ticket=OrderSend(Symbol(),OP_BUY,лот,Ask,проскальзывание,0,0,"Ордер 2-х MFI",magicNumber,0,clrGreen);
   if(ticket<0){
      Print("Функция OrderSend на покупку завершилась с ошибкой #",GetLastError());
      Comment("Функция OrderSend на покупку завершилась с ошибкой #",GetLastError());
   } else{
      открытоОрдеров++;
      отчётПокупки=StringConcatenate("Открыт ордер ",OrdersTotal()+1," на покупку; лот=",лот);
   }
   Comment(отчётПокупки);
//---
   return;
  }

//+------------------------------------------------------------------+
//| Открытие ордеров на продажу                                      |
//+------------------------------------------------------------------+
void ОткрытьНаПродажу()
  {//открытие ордера на продажу
   int ticket=OrderSend(Symbol(),OP_BUY,лот,Bid,проскальзывание,0,0,"Ордер 2-х MFI",magicNumber,0,clrGreen);
   if(ticket<0){
      Print("Функция OrderSend на продажу завершилась с ошибкой #",GetLastError());
      Comment("Функция OrderSend на продажу завершилась с ошибкой #",GetLastError());
   } else{
      открытоОрдеров++;
      отчётПокупки=StringConcatenate("Открыт ордер ",OrdersTotal()+1," на продажу; лот=",лот);
   }
   Comment(отчётПокупки);
//---
   return;
  }

//+------------------------------------------------------------------+

/*
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   double ma;
   int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//--- sell conditions
   if(Open[1]>ma && Close[1]<ma)
     {
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
      return;
     }
//--- buy conditions
   if(Open[1]<ma && Close[1]>ma)
     {
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   double ma;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(Open[1]>ma && Close[1]<ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(Open[1]<ma && Close[1]>ma)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
//---
  }
//+------------------------------------------------------------------+
*/