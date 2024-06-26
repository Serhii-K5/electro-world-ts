//+------------------------------------------------------------------+
//|                                        Слом структуры+уровни.mq4 |
//|                                                                Я |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Я"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window

extern char          баровПроверки = 3;            // Кол-во проверяемых баров для макс/мин //5
extern string        InpNameC1="ВерхнийКанал";     // Название канала 1
extern string        InpNameC2="НижнийКанал";      // Название канала 2
extern string        InpNameL1="СредняяВерхнегоКанала";     // Название средней канала 1
extern string        InpNameL2="СредняяНижнегоКанала";      // Название средней канала 2
string         InpNameC3, InpNameC4;         // Название каналов для проверки
string         InpNameL3, InpNameL4;         // Название средних каналов для проверки 
ENUM_LINE_STYLE InpStyle=STYLE_SOLID;     // Стиль линий канала 
ENUM_LINE_STYLE InpStyleL=STYLE_DOT;      // Стиль средних линий канала 
input color          InpColor1=clrRed;         // Цвет вехнего канала 
input color          InpColor2=clrBlue;        // Цвет нижнего канала
input color          InpColor3=clrOrange;      // Цвет вехнего канала для проверки 
input color          InpColor4=clrDodgerBlue;  // Цвет нижнего канала для проверки


double tablMax[],talMin[];    //Таблицы экстримумов
struct структураЛинии {
   datetime точка1;
   datetime точка2;
   double точка1Знач;
   double точка2Знач;  
};
структураЛинии maxКанала, minКанала, maxКаналаДляПроверки, minКаналаДляПроверки;

bool     старт;
datetime текущийТаймфрейм=0;
double   ind2;     
string   Отчёт;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---Задём отображаемое имя индикатору    
//   short_name=WindowExpertName()+"("+string(КолБаров)+"/"+string(КолЭспираций)+"+)";
  // IndicatorShortName(short_name);

   
//---Настройка графика   
   long handle=ChartID();
   if(handle>0){ // если получилось, дополнительно настроиваем
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

      //--- отключение автопрокрутки
      ChartSetInteger(handle,CHART_AUTOSCROLL,false);
      //---сдвигание графика к 0-му бару
      ChartNavigate(ChartID(),CHART_END,0);
   }

   СозданиеОбъекта("Кнопка1",132,10,"<",25,20); //создание кнопки "Кнопка1"(имя кнопки1,координата по Х,координата по Y,отображаемый текст,длина,высота)
   СозданиеОбъекта("Кнопка2",52,10,">",25,20);  //создание кнопки "Кнопка2"(имя кнопки2,координата по Х,координата по Y,отображаемый текст,длина,высота)
   СозданиеОбъекта("Поле1",104,10,"1",50,20);   //создание поля1 (число) (имя поля1,координата по Х,координата по Y,отображаемый текст,длина,высота)
   СозданиеОбъекта("Поле2",160,35,TimeToStr(Time[0]),150,20);   //создание поля2 (дата) (имя поля1,координата по Х,координата по Y,отображаемый текст,длина,высота)
   
   InpNameC3=StringConcatenate(InpNameC1,"Проверка");
   InpNameC4=StringConcatenate(InpNameC2,"Проверка");
   InpNameL3=StringConcatenate(InpNameL1,"Проверка");
   InpNameL4=StringConcatenate(InpNameL2,"Проверка");
   
   старт=true;
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Создание объектов                                                |
//+------------------------------------------------------------------+
void СозданиеОбъекта(string name,int x,int y,string text,int длина,int высота)
  {
   if(name == "Кнопка1" || name == "Кнопка2")
      ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
   else
      ObjectCreate(0,name,OBJ_EDIT,0,0,0);
      
//--- установим координаты кнопки
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
//--- установим размер кнопки
   ObjectSetInteger(0,name,OBJPROP_XSIZE,длина);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,высота);
//--- установим угол графика, относительно которого будут определяться координаты точки
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
//--- установим текст
   ObjectSetString(0,name,OBJPROP_TEXT,text);
//--- установим шрифт текста
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
//--- установим размер шрифта
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10);
   /*
   //--- установим цвет текста
      ObjectSetInteger(0,name,OBJPROP_COLOR,Red);
   //--- установим цвет фона
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR,White);
   //--- установим цвет границы
      ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,Blue);
   */
  }

//+------------------------------------------------------------------+ 
//| Cоздает равноудаленный канал по заданным координатам             | 
//+------------------------------------------------------------------+ 
bool ChannelCreate(const long            chart_ID=0,        // ID графика 
                   const string          name="Channel",    // имя канала  
                   const int             sub_window=0,      // номер подокна  
                   datetime              time1=0,           // время первой точки 
                   double                price1=0,          // цена первой точки 
                   datetime              time2=0,           // время второй точки 
                   double                price2=0,          // цена второй точки 
                   datetime              time3=0,           // время третьей точки 
                   double                price3=0,          // цена третьей точки 
                   const color           clr=clrRed,        // цвет канала  
                   const ENUM_LINE_STYLE style=STYLE_SOLID, // стиль линий канала 
                   const int             width=1,           // толщина линий канала 
                   const bool            fill=false,        // заливка канала цветом 
                   const bool            back=false,        // на заднем плане 
                   const bool            selection=true,    // выделить для перемещений 
                   const bool            ray_right=true,    // продолжение канала вправо 
                   const bool            hidden=false,      // скрыт в списке объектов 
                   const long            z_order=0)         // приоритет на нажатие мышью 
 //                  bool                  type_channel=false)    // тип канала (верхний/нижний)
  { 
//--- установим координаты точек привязки, если они не заданы 
   //ChangeChannelEmptyPoints("вправо",Bars-4,time1,price1,time2,price2,time3,price3); 

//--- сбросим значение ошибки 
   ResetLastError(); 
//--- создадим канал по заданным координатам 
//   if(!ObjectCreate(chart_ID,name,OBJ_CHANNEL,sub_window,time1,price1,time2,price2,time3,price3))
//   string название=type_channel? InpName1 : InpName2;
//   if(!ObjectCreate(chart_ID,название,OBJ_CHANNEL,sub_window,time1,price1,time2,price2,time3,price3)){ 
   if(!ObjectCreate(chart_ID,name,OBJ_CHANNEL,sub_window,time1,price1,time2,price2,time3,price3)){
      Print(__FUNCTION__, 
            ": не удалось создать равноудаленный канал! (",name,") Код ошибки = ",GetLastError()); 
      return(false); 
   } 
//--- установим цвет канала 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- установим стиль линий канала 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- установим толщину линий канала 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- отобразим на переднем (false) или заднем (true) плане 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- включим (true) или отключим (false) режим выделения канала для перемещений 
//--- при создании графического объекта функцией ObjectCreate, по умолчанию объект 
//--- нельзя выделить и перемещать. Внутри же этого метода параметр selection 
//--- по умолчанию равен true, что позволяет выделять и перемещать этот объект 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- включим (true) или отключим (false) режим продолжения отображения канала вправо 
   //ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right); 
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов 
   //ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- установим приоритет на получение события нажатия мыши на графике 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 

//--- успешное выполнение 
   return(true); 
  }

//+------------------------------------------------------------------+ 
//| Создает линию тренда по заданным координатам                     | 
//+------------------------------------------------------------------+ 
bool TrendCreate(const long            chart_ID=0,        // ID графика 
                 const string          name="TrendLine",  // имя линии 
                 const int             sub_window=0,      // номер подокна 
                 datetime              time1=0,           // время первой точки 
                 double                price1=0,          // цена первой точки 
                 datetime              time2=0,           // время второй точки 
                 double                price2=0,          // цена второй точки 
                 const color           clr=clrRed,        // цвет линии 
                 const ENUM_LINE_STYLE style=STYLE_DOT,   // стиль линии 
                 const int             width=1,           // толщина линии 
                 const bool            back=false,        // на заднем плане 
                 const bool            selection=true,    // выделить для перемещений 
                 const bool            ray_right=true,   // продолжение линии вправо 
                 const bool            hidden=true,       // скрыт в списке объектов 
                 const long            z_order=0)         // приоритет на нажатие мышью 
  { 
//--- установим координаты точек привязки, если они не заданы 
//   ChangeTrendEmptyPoints(time1,price1,time2,price2); 

//--- сбросим значение ошибки 
   ResetLastError(); 
//--- создадим трендовую линию по заданным координатам 
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось создать линию тренда! (",name,") Код ошибки = ",GetLastError()); 
      return(false); 
     } 
//--- установим цвет линии 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- установим стиль отображения линии 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- установим толщину линии 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- отобразим на переднем (false) или заднем (true) плане 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- включим (true) или отключим (false) режим перемещения линии мышью 
//--- при создании графического объекта функцией ObjectCreate, по умолчанию объект 
//--- нельзя выделить и перемещать. Внутри же этого метода параметр selection 
//--- по умолчанию равен true, что позволяет выделять и перемещать этот объект 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- включим (true) или отключим (false) режим продолжения отображения линии вправо 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right); 
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- установим приоритет на получение события нажатия мыши на графике 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- успешное выполнение 
   return(true); 
  } 

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---удаление созданных объектов   
   ObjectDelete(0,"Кнопка1");
   ObjectDelete(0,"Кнопка2");
   ObjectDelete(0,"Поле1");
   ObjectDelete(0,"Поле2");
   
   Comment("");
   
   ObjectsDeleteAll(0, OBJ_CHANNEL);
   ObjectsDeleteAll(0, OBJ_TREND);

//--- удаление всех объектов в окне индикатора   
//   ObjectsDeleteAll(0);
/*   
   wind_ex=WindowFind(short_name);
   if(wind_ex>0)
      ObjectsDeleteAll(wind_ex);
*/  
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
   if(старт){
      //Проверка соответствия графика заданному периоду и выбранной валютной паре 
/*      if(Symbol()!=Символ || Period()!=Период){
         OnInit();
         return(rates_total);
      }
*/      
      if (Старт()) 
         старт=false;
      
   }

//--- Проверка на обновление истории   
   if(текущийТаймфрейм!=Time[0]){
      //таймфрейм 0-го бара изменился 
      текущийТаймфрейм=Time[0];  //присваиваем текущему таймфрейму таймфрейм 0-го бара
      //---проверка для каналов     
      if(!ПоискБлижайшихЭкстремумовДляКаналов(int((баровПроверки+1)/2),true))
         return(rates_total);
      
      ПерестроениеКаналов(true);
            
   }
   
//   Comment(short_name+"\r\n"+Т+"\r\n"+Т1);   
   
   ChartRedraw(); // принудительно перерисуем все объекты на графике
      
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Старт()
  {
   maxКанала.точка1=Time[Bars-1];
   maxКанала.точка2=Time[Bars-1];
   maxКанала.точка1Знач=0.0;
   maxКанала.точка2Знач=0.0;
   
   minКанала=maxКанала;
   maxКаналаДляПроверки=maxКанала;
   minКаналаДляПроверки=maxКанала;
  
   //---Поиск эскстримумов для каналов
   if(!ПоискБлижайшихЭкстремумовДляКаналов(int((баровПроверки+1)/2),true))
      return false;
   
   //---Создание каналов
   if(!ChannelCreate(0,InpNameC1,0,maxКанала.точка1,maxКанала.точка1Знач,maxКанала.точка2,maxКанала.точка2Знач,minКанала.точка2,minКанала.точка2Знач,
         InpColor1,InpStyle,1,false,false,true,true,false)){ 
      Print("Неудалось создать основной верхний канал ", InpNameC1);
    }
   if(!ChannelCreate(0,InpNameC2,0,minКанала.точка1,minКанала.точка1Знач,minКанала.точка2,minКанала.точка2Знач,maxКанала.точка2,maxКанала.точка2Знач,
         InpColor2,InpStyle,1,false,false,true,true,false)){        
      Print("Неудалось создать основной нижний канал ", InpNameC2);
    }
   if(!ChannelCreate(0,InpNameC3,0,maxКанала.точка1,maxКанала.точка1Знач,maxКанала.точка2,maxКанала.точка2Знач,minКанала.точка2,minКанала.точка2Знач,
         InpColor3,InpStyle,1,false,false,true,true,false)){ 
      Print("Неудалось создать проверочный верхний канал ", InpNameC3);
    }
   if(!ChannelCreate(0,InpNameC4,0,minКанала.точка1,minКанала.точка1Знач,minКанала.точка2,minКанала.точка2Знач,maxКанала.точка2,maxКанала.точка2Знач,
         InpColor4,InpStyle,1,false,false,true,true,false)){        
      Print("Неудалось создать проверочный нижний канал ", InpNameC4);
    }
   
   //Создание средних линий каналов
   int shiftMax1=iBarShift(NULL,0,maxКанала.точка1,false); 
   int shiftMax2=iBarShift(NULL,0,maxКанала.точка2,false); 
   int shiftMin1=iBarShift(NULL,0,minКанала.точка1,false); 
   int shiftMin2=iBarShift(NULL,0,minКанала.точка2,false); 
   double priceLine1=NormalizeDouble((maxКанала.точка1Знач+minКанала.точка2Знач-(maxКанала.точка2Знач-maxКанала.точка1Знач)/(shiftMax1-shiftMax2)*(shiftMax1-shiftMin2))/2,Digits);
   double priceLine2=NormalizeDouble((maxКанала.точка2Знач+minКанала.точка2Знач-(maxКанала.точка2Знач-maxКанала.точка1Знач)/(shiftMax1-shiftMax2)*(shiftMax2-shiftMin2))/2,Digits);
   if(!TrendCreate(0,InpNameL1,0,maxКанала.точка1,priceLine1,maxКанала.точка2,priceLine2,InpColor1,InpStyleL,1,false,true,true,false,0)) 
      Print("Неудалось создать среднюю линию верхнего канала ", InpNameL1);
   if(!TrendCreate(0,InpNameL3,0,maxКанала.точка1,priceLine1,maxКанала.точка2,priceLine2,InpColor3,InpStyleL,1,false,false,true,false,0)) 
      Print("Неудалось создать проверочную среднюю линию верхнего канала ", InpNameL3);

   priceLine1=NormalizeDouble((minКанала.точка1Знач+maxКанала.точка2Знач-(minКанала.точка2Знач-minКанала.точка1Знач)/(shiftMin1-shiftMin2)*(shiftMin1-shiftMax2))/2,Digits);
   priceLine2=NormalizeDouble((minКанала.точка2Знач+maxКанала.точка2Знач-(minКанала.точка2Знач-minКанала.точка1Знач)/(shiftMin1-shiftMin2)*(shiftMin2-shiftMax2))/2,Digits);
   if(!TrendCreate(0,InpNameL2,0,minКанала.точка1,priceLine1,minКанала.точка2,priceLine2,InpColor2,InpStyleL,1,false,false,true,false,0)) 
      Print("Неудалось создать среднюю линию нижнего канала ", InpNameL2);
   if(!TrendCreate(0,InpNameL4,0,minКанала.точка1,priceLine1,minКанала.точка2,priceLine2,InpColor4,InpStyleL,1,false,false,true,false,0)) 
      Print("Неудалось создать проверочную среднюю линию нижнего канала ", InpNameL4);
   
   текущийТаймфрейм=Time[1];

   ChartRedraw();
/*   
//   string T = maxИнд.точка1+"; "+ minИнд.точка1+"; "+maxИнд.точка2+"; "+ minИнд.точка2+"; "+"\r\n";
  // string T2 = maxИнд.точка1+"; "+ minИнд.точка1+"; "+maxИнд.точка2+"; "+ minИнд.точка2+"; "+"\r\n";
   Comment(StringConcatenate("max1=", maxИнд.точка1, "; max2=", minИнд.точка1, "; min1=", maxИнд.точка2, "; min2=",  minИнд.точка2, "\r\n", 
           "max1=", maxИнд.точка1Знач, "; max2=", minИнд.точка1Знач, "; min1=", maxИнд.точка2Знач, "; min2=",  minИнд.точка2Знач, "\r\n" , 
           "max1=", maxИндДляПроверки.точка1, "; max2=", minИндДляПроверки.точка1, "; min1=", maxИндДляПроверки.точка2, "; min2=",  minИндДляПроверки.точка2, "\r\n", 
           "max1=", maxИндДляПроверки.точка1Знач, "; max2=", minИндДляПроверки.точка1Знач, "; min1=", maxИндДляПроверки.точка2Знач, "; min2=",  minИндДляПроверки.точка2Знач));
 */ 
   
   return true;
  }


//+------------------------------------------------------------------+
//| Поиск ближайших экстремумов для каналов                          |
//+------------------------------------------------------------------+
bool ПоискБлижайшихЭкстремумовДляКаналов(int проверяемыйБар,bool типКаналов)
  {
   char точекMin=0, точекMax=0;
   double значMin=-1.0, значMax=-1.0;
   bool flagMin=false,flagMax=false;

   if(типКаналов && !старт){
      if(!ПроверкаНаMax(проверяемыйБар) && !ПроверкаНаMin(проверяемыйБар))
         return false;
   }
   
   for(int bar=проверяемыйБар;bar<Bars-баровПроверки;bar++){      
      if(ПроверкаНаMax(bar)){
         if(типКаналов){
            if(значMax > 0 && ind2 >= значMax){  //поднимание
               if(точекMax == 0){
                  maxКанала.точка2=Time[bar];
                  maxКанала.точка2Знач=NormalizeDouble(ind2,Digits);
                  flagMax=true;
               } else if(точекMax == 1){
                  maxКанала.точка1=Time[bar];
                  maxКанала.точка1Знач=NormalizeDouble(ind2,Digits);
                  flagMax=true;
               }
            } else if(flagMax){
               точекMax++;
               flagMax=false;
            }
         } else {
            if(значMax > 0 && ind2 >= значMax){  //поднимание
               if(точекMax == 0){
                  maxКаналаДляПроверки.точка2=Time[bar];
                  maxКаналаДляПроверки.точка2Знач=NormalizeDouble(ind2,Digits);
                  flagMax=true;
               } else if(точекMax == 1){
                  maxКаналаДляПроверки.точка1=Time[bar];
                  maxКаналаДляПроверки.точка1Знач=NormalizeDouble(ind2,Digits);
                  flagMax=true;
               }
            } else if(flagMax){
               точекMax++;
               flagMax=false;
            }
         }
         
         значMax=ind2;
      }     
      
      if(ПроверкаНаMin(bar)){
         if(типКаналов){
            if(значMin > 0 && ind2 <= значMin){  //опускание
               if(точекMin == 0){
                  minКанала.точка2=Time[bar];
                  minКанала.точка2Знач=NormalizeDouble(ind2,Digits);
                  flagMin=true;
               } else if(точекMin == 1){
                  minКанала.точка1=Time[bar];
                  minКанала.точка1Знач=NormalizeDouble(ind2,Digits);
                  flagMin=true;
               }
            } else if(flagMin){
               точекMin++;
               flagMin=false;
            }
         } else {
            if(значMin > 0 && ind2 <= значMin){  //опускание
               if(точекMin == 0){
                  minКаналаДляПроверки.точка2=Time[bar];
                  minКаналаДляПроверки.точка2Знач=NormalizeDouble(ind2,Digits);
                  flagMin=true;
               } else if(точекMin == 1){
                  minКаналаДляПроверки.точка1=Time[bar];
                  minКаналаДляПроверки.точка1Знач=NormalizeDouble(ind2,Digits);
                  flagMin=true;
               }
            } else if(flagMin){
               точекMin++;
               flagMin=false;
            }
         }
         
         значMin=ind2;
      }
      
      if(точекMin>1 && точекMax>1) 
         break;   
   }   
  
   if(точекMin>1 && точекMax>1) 
      return true;
   else return false;
  }

//+------------------------------------------------------------------+
//| Проверка на максимум графика                                     |
//+------------------------------------------------------------------+
bool ПроверкаНаMax(int проверяемыйБар)
  {
   ind2 = High[проверяемыйБар];

   for(int i=0;i<(баровПроверки-1)/2;i++){
      if(High[проверяемыйБар] <= High[проверяемыйБар-1-i])
          return(false);
   }

   for(int i=проверяемыйБар+1;i<Bars;i++){
      if(High[проверяемыйБар] < High[i] || (High[проверяемыйБар]==High[i] && i==Bars-1))
         return(false);
      
      if(High[проверяемыйБар]!=High[i] && i>=проверяемыйБар+(баровПроверки-1)/2)
         break;
   }
   
   return(true);   
  }

//+------------------------------------------------------------------+
//| Проверка на минимум графика                                      |
//+------------------------------------------------------------------+
bool ПроверкаНаMin(int проверяемыйБар)
  {
   ind2 = Low[проверяемыйБар];
   for(int i=0;i<(баровПроверки-1)/2;i++)
      if(Low[проверяемыйБар] >= Low[проверяемыйБар-1-i])
          return(false);
      
   for(int i=проверяемыйБар+1;i<Bars;i++){
      if(Low[проверяемыйБар] > Low[i] || (Low[проверяемыйБар]==Low[i] && i==Bars-1))
         return(false);
      
      if(Low[проверяемыйБар]!=Low[i] && i>=проверяемыйБар+(баровПроверки-1)/2)
         break;
   }
   
   return(true);
  }

//+------------------------------------------------------------------+
//| Перестроение каналов                                             |
//+------------------------------------------------------------------+
void ПерестроениеКаналов(bool типКанала)
  {  
   //--- сдвигаем точки
   if(типКанала){
      ПерестроениеКанала(InpNameC1,InpNameL1,maxКанала.точка1,maxКанала.точка1Знач,maxКанала.точка2,maxКанала.точка2Знач,minКанала.точка2,minКанала.точка2Знач);  //max 
      ПерестроениеКанала(InpNameC2,InpNameL2,minКанала.точка1,minКанала.точка1Знач,minКанала.точка2,minКанала.точка2Знач,maxКанала.точка2,maxКанала.точка2Знач);  //min
   
   } else{
      ПерестроениеКанала(InpNameC3,InpNameL3,maxКаналаДляПроверки.точка1,maxКаналаДляПроверки.точка1Знач,maxКаналаДляПроверки.точка2,maxКаналаДляПроверки.точка2Знач,minКаналаДляПроверки.точка2,minКаналаДляПроверки.точка2Знач);   
      ПерестроениеКанала(InpNameC4,InpNameL4,minКаналаДляПроверки.точка1,minКаналаДляПроверки.точка1Знач,minКаналаДляПроверки.точка2,minКаналаДляПроверки.точка2Знач,maxКаналаДляПроверки.точка2,maxКаналаДляПроверки.точка2Знач);
   }
  }
  
//+------------------------------------------------------------------+
//| Перестроение каналов                                             |
//+------------------------------------------------------------------+
void ПерестроениеКанала(string name,string nameL,datetime time1,double price1,datetime time2,double price2,datetime time3,double price3)
  {  
   //--- сдвигаем точки 
   
   if(!ИзменениеТочкиКанала(0,name,0,time1,price1)) 
      Print("(Канал ",name,", точка 1)"); 
   if(!ИзменениеТочкиКанала(0,name,1,time2,price2)) 
      Print("(Канал ",name,", точка 2)");
   if(!ИзменениеТочкиКанала(0,name,2,time3,price3)) 
      Print("(Канал ",name,", точка 3)");
   
   int shiftPoint1=iBarShift(NULL,0,time1,false); 
   int shiftPoint2=iBarShift(NULL,0,time2,false); 
   int shiftPoint3=iBarShift(NULL,0,time3,false); 
   double priceLine=NormalizeDouble((price1+price3-(price2-price1)/(shiftPoint1-shiftPoint2)*(shiftPoint1-shiftPoint3))/2,Digits);
   if(!ИзменениеТочкиСреднейЛинии(0,nameL,0,time1,priceLine))
      Print("(Средняя линия канала ",nameL,", точка 1)");
   
   priceLine=NormalizeDouble((price2+price3-(price2-price1)/(shiftPoint1-shiftPoint2)*(shiftPoint2-shiftPoint3))/2,Digits);
   if(!ИзменениеТочкиСреднейЛинии(0,nameL,1,time2,priceLine))
      Print("(Средняя линия канала ",nameL,", точка 2)");

   //--- проверим факт принудительного завершения 
   // if(IsStopped()) 
      // return; 
  }

//+------------------------------------------------------------------+ 
//| Перемещает точку привязки канала                                 | 
//+------------------------------------------------------------------+ 
bool ИзменениеТочкиКанала(const long   chart_ID=0,     // ID графика 
                        const string name="Channel", // имя канала 
                        const int    point_index=0,  // номер точки привязки 
                        datetime     time=0,         // координата времени точки привязки 
                        double       price=0)        // координата цены точки привязки 
  { 
//--- если координаты точки не заданы, то перемещаем ее на текущий бар с ценой Bid 
   if(!time) 
      time=TimeCurrent(); 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- сбросим значение ошибки 
   ResetLastError(); 
//--- переместим точку привязки 
   if(!ObjectMove(chart_ID,name,point_index,time,price)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось переместить точку привязки! (",name," точка ",point_index,") Код ошибки = ",GetLastError()); 
      return(false); 
     } 
//--- успешное выполнение 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Перемещает точку привязки линии тренда                           | 
//+------------------------------------------------------------------+ 
bool ИзменениеТочкиСреднейЛинии(const long   chart_ID=0,       // ID графика 
                      const string name="TrendLine", // имя линии 
                      const int    point_index=0,    // номер точки привязки 
                      datetime     time=0,           // координата времени точки привязки 
                      double       price=0)          // координата цены точки привязки 
  { 
//--- если координаты точки не заданы, то перемещаем ее на текущий бар с ценой Bid 
   if(!time) 
      time=TimeCurrent(); 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- сбросим значение ошибки 
   ResetLastError(); 
//--- переместим точку привязки линии тренда 
   if(!ObjectMove(chart_ID,name,point_index,time,price)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось переместить точку привязки линии ",name,"! Код ошибки = ",GetLastError()); 
      return(false); 
     } 
//--- успешное выполнение 
   return(true); 
  } 

//+------------------------------------------------------------------+
//|События                                                           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   int i,i1;
   datetime d;
//--- проверим событие на нажатие кнопки мышки
   if(id==CHARTEVENT_OBJECT_CLICK){
      string НажатыйОбъект=sparam;
      long handle=ChartID();
      if(НажатыйОбъект=="Кнопка1"){
         //--- если нажатие на объекте с именем "Кнопка1"
         i=StrToInteger(ObjectGetString(0,"Поле1",OBJPROP_TEXT));
         d=StrToTime(ObjectGetString(0,"Поле2",OBJPROP_TEXT));
         i1=iBarShift(NULL,0,d);
         if(i1+i<Bars-19){
            //--- изменим текст в текстовом поле
            ObjectSetString(0,"Поле2",OBJPROP_TEXT,TimeToStr(Time[i+i1]));
            //--- прокрутим на i1+i баров влево от правого края графика и сместим на 20 к центру
            i=-(i1+i-19);
            ChartNavigate(ChartID(),CHART_END,i);
            //ChartNavigate(handle,CHART_BEGIN,Bars-(i1+i));
         } else if(i1+i<Bars){
            //--- изменим текст в текстовом поле
            ObjectSetString(0,"Поле2",OBJPROP_TEXT,TimeToStr(Time[i+i1]));
            //--- прокрутим к 0-му бару влево от правого края графика и сместим на 20 к центру
            ChartNavigate(handle,CHART_BEGIN,0);
         } else{
            //--- изменим текст в текстовом поле
            ObjectSetString(0,"Поле2",OBJPROP_TEXT,TimeToStr(Time[Bars-1]));
            //--- прокрутим к 0-му бару влево от правого края графика и сместим на 20 к центру
            ChartNavigate(handle,CHART_BEGIN,0);
         }
         
         ДействиеПоНажатиюКнопки();
      }

      if(НажатыйОбъект=="Кнопка2"){
         //--- если нажатие на объекте с именем "Кнопка2"
         i=StrToInteger(ObjectGetString(0,"Поле1",OBJPROP_TEXT));
         d=StrToTime(ObjectGetString(0,"Поле2",OBJPROP_TEXT));
         i1=iBarShift(NULL,0,d);
         if(i1-i>19){
            //--- изменим текст в текстовом поле
            ObjectSetString(0,"Поле2",OBJPROP_TEXT,TimeToStr(Time[i1-i]));
            //--- прокрутим на i1-i баров влево от правого края графика и сместим на 20 к центру
            i=-(i1-i-19);
            ChartNavigate(handle,CHART_END,i);
         } else if(i1-i>=0){
            //--- изменим текст в текстовом поле
            ObjectSetString(0,"Поле2",OBJPROP_TEXT,TimeToStr(Time[i1-i]));
            //--- прокрутим на i1-i баров влево от правого края графика и сместим на 20 к центру            
            ChartNavigate(handle,CHART_END,0);
         } else{
            //--- изменим текст в текстовом поле
            ObjectSetString(0,"Поле2",OBJPROP_TEXT,TimeToStr(Time[0]));
            //--- прокрутим к 0-му бару влево от правого края графика и сместим на 20 к центру
            ChartNavigate(handle,CHART_END,0);
         }

         ДействиеПоНажатиюКнопки();
      }

      if(НажатыйОбъект=="Поле2"){
         //--- изменим текст в текстовом поле
         string str= ObjectGetString(0,"Поле2",OBJPROP_TEXT);
         
         d=StrToTime(ObjectGetString(0,"Поле2",OBJPROP_TEXT));
         if(!datetime(d))
            d=Time[0];
 /*           {
            d=Time[0];
           
                        //--- выведем сообщение об ошибке в журнал "Эксперты"
                        Print(__FUNCTION__+", Error Code = ",GetLastError());
                        MessageBoxA(0,"an message","Message",MB_OK);
                        Alert("Значение в поле даты не является датой.");
            
           }
*/       //--- изменим текст в текстовом поле  
         ObjectSetString(0,"Поле2",OBJPROP_TEXT,TimeToStr(d));
      }

      ChartRedraw(); // принудительно перерисуем все объекты на графике
     }
  }

//+-------------------------------------------------------------------------+
//| Построение линий по нажатию кнопки                                      |
//+-------------------------------------------------------------------------+
void ДействиеПоНажатиюКнопки()
  {//--- считывание данных поля и переход с перестроением
   datetime d=StrToTime(ObjectGetString(0,"Поле2",OBJPROP_TEXT));
   int проверяемыйБар=iBarShift(NULL,0,d,false)+2; 

   //---перестановка каналов
   if(проверяемыйБар>0 && проверяемыйБар<Bars-2)
//      for(int bar=проверяемыйБар;bar<Bars-баровПроверки;bar++)
         if(ПоискБлижайшихЭкстремумовДляКаналов(проверяемыйБар,false))
            ПерестроениеКаналов(false);

   Print("");
/*   
//   Comment(short_name+"\r\n"+Т+"\r\n"+Т1);
   Comment(StringConcatenate("max1=", maxИнд.точка1, "; max2=", minИнд.точка1, "; min1=", maxИнд.точка2, "; min2=",  minИнд.точка2, "\r\n", 
           "max1=", maxИнд.точка1Знач, "; max2=", minИнд.точка1Знач, "; min1=", maxИнд.точка2Знач, "; min2=",  minИнд.точка2Знач, "\r\n" , 
           "max1=", maxИндДляПроверки.точка1, "; max2=", minИндДляПроверки.точка1, "; min1=", maxИндДляПроверки.точка2, "; min2=",  minИндДляПроверки.точка2, "\r\n", 
           "max1=", maxИндДляПроверки.точка1Знач, "; max2=", minИндДляПроверки.точка1Знач, "; min1=", maxИндДляПроверки.точка2Знач, "; min2=",  minИндДляПроверки.точка2Знач));
*/   
   ChartRedraw();

  }

//+------------------------------------------------------------------+
