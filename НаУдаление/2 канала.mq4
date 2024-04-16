//+------------------------------------------------------------------+
//|                                                     2 канала.mq4 |
//|                                                                Я |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Я"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window

extern string символ = "EURUSDb";    //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
extern string          InpName1="ВерхнийКанал";   // Имя канала 
extern string          InpName2="НижнийКанал";   // Имя канала
input color           InpColor1=clrRed;     // Цвет 1-го канала 
input color           InpColor2=clrBlue;     // Цвет 2-го канала
input ENUM_LINE_STYLE InpStyle=STYLE_SOLID; // Стиль линий канала 
//input int             InpWidth=1;          // Толщина линий канала 
input bool            InpBack=false;       // Канал на заднем плане 
//input bool            InpFill=false;       // Заливка канала цветом 
//input bool            InpSelection=true;   // Выделить для перемещений 
//input bool            InpRayRight=false;   // Продолжение канала вправо 
input bool            InpRayRight=true;   // Продолжение канала вправо
//input bool            InpHidden=true;      // Скрыт в списке объектов 
//input long            InpZOrder=0;         // Приоритет на нажатие мышью 


int      период;    //Время исполнения 
bool     старт;
//int      Bar;
datetime текущийТаймфрейм=0;

datetime maxMinДата[2][2];       //maxMinДата[0-Макс, 1-Мин][0-Max1/Min1, 1-Max2/Min2]
datetime maxMinДата1[2][2];      //старые значения maxMinДата
double   maxMinЗначение[2][2];   //МаксМинЗначение[0-Макс, 1-Мин][0-Max1/Min1, 1-Max2/Min2]
int      точкиПересеченийБары[];    //массив смещений в барах от даты отсчёта до точек пересечений
int      точкиПересеченийБарыДоп[];    //массив смещений в барах от даты отсчёта до точек пересечений для доп. линий
//datetime точкиПересеченийДата[];    //массив баров создания точки пересечений
datetime датаОтсчёта;
double   ind1, ind2, ind3;      //Значения индикатора(ind1 - 1-й бар, ind2 - 2-й бар, ...)
string   short_name;
bool     КаналMaxИзменён=false, КаналMinИзменён=false;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
////--- indicator buffers mapping
  // SetIndexBuffer(0,Индик);

//   short_name=WindowExpertName()+"("+string(b1)+")";
   short_name=WindowExpertName();
   IndicatorShortName(short_name);
   
   long handle=ChartID();
   if(handle>0) // если получилось, дополнительно настроим
     {IndicatorDigits(Digits);
      //--- Установка периода графика
      //ChartSetSymbolPeriod(0,NULL,Период);
      if (!ChartSetSymbolPeriod(0,символ,период)) 
         ChartSetSymbolPeriod(0,NULL,период);
      
      //--- сброс значения ошибки
      ResetLastError();
      //--- установка значения приближеня/отдаления графика (дальше(0)-ближе(5))
      ChartSetInteger(handle,CHART_SCALE,0,5);

      //--- сброс значения ошибки
      ResetLastError();
      //--- отображение в виде свечей
      ChartSetInteger(handle,CHART_MODE,CHART_CANDLES);
     }
   
/*   
   СозданиеОбъекта("Кнопка1",132,10,"<",25,20); //создание кнопки "Кнопка1"(имя кнопки1,координата по Х,координата по Y,отображаемый текст,длина,высота)
   СозданиеОбъекта("Кнопка2",52,10,">",25,20);  //создание кнопки "Кнопка2"(имя кнопки2,координата по Х,координата по Y,отображаемый текст,длина,высота)
   СозданиеОбъекта("Поле1",104,10,"1",50,20);   //создание поля1 (число) (имя поля1,координата по Х,координата по Y,отображаемый текст,длина,высота)
   СозданиеОбъекта("Поле2",160,35,TimeToStr(Time[0]),150,20);   //создание поля2 (дата) (имя поля1,координата по Х,координата по Y,отображаемый текст,длина,высота)
*/   
   старт=true;
   
//---
   return(INIT_SUCCEEDED);
  }
/*
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
 // }
  
//+------------------------------------------------------------------+ 
//| Cоздает равноудаленный канал по заданным координатам             | 
//+------------------------------------------------------------------+ 
bool ChannelCreate(const long            chart_ID=0,        // ID графика 
                   const string          name="Channel",    // имя канала 
 //                  string                name=InpName1,    // имя канала 
                   const int             sub_window=0,      // номер подокна  
                   datetime              time1=0,           // время первой точки 
                   double                price1=0,          // цена первой точки 
                   datetime              time2=0,           // время второй точки 
                   double                price2=0,          // цена второй точки 
                   datetime              time3=0,           // время третьей точки 
                   double                price3=0,          // цена третьей точки 
                   const color           clr=clrRed,        // цвет канала 
 //                  color                 clr=clrRed,        // цвет канала 
                   const ENUM_LINE_STYLE style=STYLE_SOLID, // стиль линий канала 
                   const int             width=1,           // толщина линий канала 
                   const bool            fill=false,        // заливка канала цветом 
                   const bool            back=false,        // на заднем плане 
                   const bool            selection=true,    // выделить для перемещений 
 //                  const bool            selection=false,   // выделить для перемещений
 //                  const bool            ray_right=false,   // продолжение канала вправо 
 //                  const bool            hidden=true,       // скрыт в списке объектов  
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
/*
//+------------------------------------------------------------------+ 
//| Проверяет значения точек привязки канала и для пустых значений   | 
//| устанавливает значения по умолчанию                              | 
//+------------------------------------------------------------------+ 
void ChangeChannelEmptyPoints(string направление,int проверяемыйБар, datetime &time1,double &price1,datetime &time2, 
                              double &price2,datetime &time3,double &price3) 
  { 
   if(направление=="вправо"){
      for(int bar=проверяемыйБар; bar>0; bar++)
      ПоискБлижайшихМаксМин(1,true);
   } else{
   
   }


//--- если время второй (правой) точки не задано, то она будет на текущем баре 
   if(!time2) 
      time2=TimeCurrent(); 
//--- если цена второй точки не задана, то она будет иметь значение Bid 
   if(!price2) 
      price2=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- если время первой (левой) точки не задано, то она лежит на 9 баров левее второй 
   if(!time1) 
     { 
      //--- массив для приема времени открытия 10 последних баров 
      datetime temp[10]; 
      CopyTime(Symbol(),Period(),time2,10,temp); 
      //--- установим первую точку на 9 баров левее второй 
      time1=temp[0]; 
     } 
//--- если цена первой точки не задана, то сдвинем ее на 300 пунктов выше второй 
   if(!price1) 
      price1=price2+300*SymbolInfoDouble(Symbol(),SYMBOL_POINT); 
//--- если время третьей точки не задано, то оно совпадает с временем первой точки 
   if(!time3) 
      time3=time1; 
//--- если цена третьей точки не задана, то она совпадает с ценой второй точки 
   if(!price3) 
      price3=price2; 
  }  
*/  
//+------------------------------------------------------------------+ 
//| Удаляет канал                                                    | 
//+------------------------------------------------------------------+ 
bool ChannelDelete(const long   chart_ID=0,     // ID графика 
                   const string name="Channel") // имя канала
  { 
//--- сбросим значение ошибки 
   ResetLastError(); 
//--- удалим канал 
   if(!ObjectDelete(chart_ID,name)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось удалить канал ",name,"! Код ошибки = ",GetLastError()); 
      return(false); 
     } 
//--- успешное выполнение 
   return(true); 
  }   

//+------------------------------------------------------------------+
//| Удаление всех объектов при закрытии индикатора                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
    ObjectsDeleteAll(0, OBJ_CHANNEL);
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
//---Проверка достаточного количества баров в истории   
   if(Bars<3)  
      return(rates_total);
      
//---Проверка соответствия графика заданному периоду и выбранной валютной паре   
   if(Symbol()!=символ || Period()!=период){
      символ=Symbol();
      период=Period();
      OnInit();
      return(rates_total);
   }
      
   if(старт){
      //Проверка соответствия графика заданному периоду и выбранной валютной паре 
      if(Symbol()!=символ || Period()!=период){
         OnInit();
         return(rates_total);
      }
       
      if (Старт()) старт=false;
      else {
         Print("Недостаточно данных в истории.");
         return(rates_total);
      }
   }

//--- Проверка на обновление истории   
   if(текущийТаймфрейм!=Time[0]){
      //таймфрейм 0-го бара изменился      
      int последнийБар=iBarShift(NULL,0,текущийТаймфрейм,false);  //Определяем последний известный бар
      if(последнийБар>0)         
         //---Поиск пересечений каналов
         for(int bar=последнийБар; bar>=0; bar--)   //заполняем индикатор пропущеннами барами
            //---Поиск эскстримумов для каналов
            if(ПоискБлижайшихЭкстремумов(bar) && ПроверкаНаИзменениеMaxMin())
               ПоискПересеченийКаналов(bar);
      
      ПерестроениеКаналов();
      текущийТаймфрейм=Time[0];  //присваиваем текущему таймфрейму таймфрейм 0-го бара     
   }
      
//--- перерисуем график 
   ChartRedraw();         
   
//--- возвращаем значение prev_calculated для следующего вызова
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Расчёт начальных параметров                                      |
//+------------------------------------------------------------------+
bool Старт()
  {
   датаОтсчёта=Time[Bars-1];
   ArrayFill(maxMinДата,0,ArraySize(maxMinДата),Time[Bars-1]);
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
   if(maxMinДата[0][0]<Time[Bars-1] || maxMinДата[0][1]<Time[Bars-1] || maxMinДата[1][0]<Time[Bars-1] || maxMinДата[1][1]<Time[Bars-1])
      return false;
   if(!ChannelCreate(0,InpName1,0,maxMinДата[0][0],maxMinЗначение[0][0],maxMinДата[0][1],maxMinЗначение[0][1],maxMinДата[1][1],maxMinЗначение[1][1],InpColor1, 
       InpStyle,1,false,InpBack,true,InpRayRight,false)){ 
       Print("Неудалось создать канал ", InpName1);
//      return false; 
    }
   if(!ChannelCreate(0,InpName2,0,maxMinДата[1][0],maxMinЗначение[1][0],maxMinДата[1][1],maxMinЗначение[1][1],maxMinДата[0][1],maxMinЗначение[0][1],InpColor2, 
       InpStyle,1,false,InpBack,true,InpRayRight,false)){        
       Print("Неудалось создать канал ", InpName2);
//      return false; 
    }
    
//--- перерисуем график    
   ChartRedraw();
   
   return true;
  }
  
//+------------------------------------------------------------------+
//| Поиск ближайших экстремумов                                      |
//+------------------------------------------------------------------+
bool ПоискБлижайшихЭкстремумов(int проверяемыйБар)
  {
   char точекMin=0, точекMax=0;
   
   for(int bar=проверяемыйБар;bar<Bars-3;bar++){
      if(ПроверкаНаMax(bar)){
         maxMinДата[0][1]=maxMinДата[0][0];
         maxMinДата[0][0]=Time[bar+1];
         maxMinЗначение[0][1]=maxMinЗначение[0][0];
         maxMinЗначение[0][0]=NormalizeDouble(ind2,Digits);
         точекMax++;
      }
      if(ПроверкаНаMin(bar)){
         maxMinДата[1][1]=maxMinДата[1][0];
         maxMinДата[1][0]=Time[bar+1];
         maxMinЗначение[1][1]=maxMinЗначение[1][0];
         maxMinЗначение[1][0]=NormalizeDouble(ind2,Digits);
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
   if(maxMinДата1[0][0]==maxMinДата[0][0] && maxMinДата1[0][1]==maxMinДата[0][1])
      КаналMaxИзменён=false;
   else КаналMaxИзменён=true;
   if(maxMinДата1[0][0]!=maxMinДата[0][0])
      maxMinДата1[0][0]=maxMinДата[0][0];
   if(maxMinДата1[0][1]!=maxMinДата[0][1])
      maxMinДата1[0][1]=maxMinДата[0][1]; 
   
   if(maxMinДата1[1][0]==maxMinДата[1][0] && maxMinДата1[1][1]==maxMinДата[1][1])
      КаналMinИзменён=false;
   else КаналMinИзменён=true;
   if(maxMinДата1[1][0]!=maxMinДата[1][0])
      maxMinДата1[1][0]=maxMinДата[1][0];
   if(maxMinДата1[1][1]!=maxMinДата[1][1])
      maxMinДата1[1][1]=maxMinДата[1][1];
   
   if(КаналMaxИзменён || КаналMinИзменён)
      return(true);
   else return(false);
/*   if(maxMinДата[0][0]==maxMinДата1[0][0] && maxMinДата[0][1]==maxMinДата1[0][1] &&
        maxMinДата[1][0]==maxMinДата1[1][0] && maxMinДата[1][1]==maxMinДата1[1][1])
      return(false);
   else {
      ArrayCopy(maxMinДата1,maxMinДата,0,0,WHOLE_ARRAY);
      return(true);
   }
*/ 
  }
  
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
   int A1x=iBarShift(NULL,0,maxMinДата[0][0],false);
   int A2x=iBarShift(NULL,0,maxMinДата[0][1],false);
   double A1y=NormalizeDouble(maxMinЗначение[0][0],Digits);
   double A2y=NormalizeDouble(maxMinЗначение[0][1],Digits);
   //для нахождения m подставим значения в формулу прямой и вычтем значения, для избавления от С
   double m =NormalizeDouble((A2y-A1y)/(A2x-A1x),8);
   
   int B1x=iBarShift(NULL,0,maxMinДата[1][0],false);
   int B2x=iBarShift(NULL,0,maxMinДата[1][1],false);
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
  
//+------------------------------------------------------------------+
//| Перестроение каналов                                             |
//+------------------------------------------------------------------+
void ПерестроениеКаналов()
  {  
   //--- сдвигаем точки 
   if(КаналMaxИзменён){
      ПерестроениеКанала(InpName1,maxMinДата[0][0],maxMinЗначение[0][0],maxMinДата[0][1],maxMinЗначение[0][1],maxMinДата[1][1],maxMinЗначение[1][1]);
 /*     if(!ChannelPointChange(0,InpName1,1,maxMinДата[0][0],maxMinЗначение[0][0])) 
         Print("(Канал ",InpName1,", точка 1)"); 
      if(!ChannelPointChange(0,InpName1,2,maxMinДата[0][1],maxMinЗначение[0][1])) 
         Print("(Канал ",InpName1,", точка 2)");
      if(!ChannelPointChange(0,InpName1,3,maxMinДата[1][1],maxMinЗначение[1][1])) 
         Print("(Канал ",InpName1,", точка 3)");
*/   
   }
   if(КаналMinИзменён){      
      ПерестроениеКанала(InpName2,maxMinДата[1][0],maxMinЗначение[1][0],maxMinДата[1][1],maxMinЗначение[1][1],maxMinДата[0][1],maxMinЗначение[0][1]);
/*      if(!ChannelPointChange(0,InpName2,1,maxMinДата[1][0],maxMinЗначение[1][0])) 
         Print("(Канал ",InpName2,", точка 1)"); 
      if(!ChannelPointChange(0,InpName2,2,maxMinДата[1][1],maxMinЗначение[1][1])) 
         Print("(Канал ",InpName2,", точка 2)");
      if(!ChannelPointChange(0,InpName2,3,maxMinДата[0][1],maxMinЗначение[0][1])) 
         Print("(Канал ",InpName2,", точка 3)");   
*/   
   }
   //--- проверим факт принудительного завершения 
   // if(IsStopped()) 
      // return; 
  }
  
//+------------------------------------------------------------------+
//| Перестроение каналов                                             |
//+------------------------------------------------------------------+
void ПерестроениеКанала(string name,datetime time1,double price1,datetime time2,double price2,datetime time3,double price3)
  {  
   //--- сдвигаем точки 
   
   if(!ChannelPointChange(0,name,0,time1,price1)) 
      Print("(Канал ",name,", точка 1)"); 
   if(!ChannelPointChange(0,name,1,time2,price2)) 
      Print("(Канал ",name,", точка 2)");
   if(!ChannelPointChange(0,name,2,time3,price3)) 
      Print("(Канал ",name,", точка 3)");
   
   //--- проверим факт принудительного завершения 
   // if(IsStopped()) 
      // return; 
  }

//+------------------------------------------------------------------+ 
//| Перемещает точку привязки канала                                 | 
//+------------------------------------------------------------------+ 
bool ChannelPointChange(const long   chart_ID=0,     // ID графика 
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
