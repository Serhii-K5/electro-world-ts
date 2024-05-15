//+------------------------------------------------------------------+
//|                                                  ДСТДСЦ+КНОП.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
//выводит разницу тиков между текущим и прошлым баром с построением трендогвых линий (ТЛ)
//строит верхний и нижний равноудалённйе каналы
//имеет панель перемещения по графику для анализа
//ДвижСмещТиковСДвижСмещЦен = ДСТСДСЦ
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict
#property indicator_separate_window
//#property indicator_buffers 2
//#property indicator_plots   2
#property indicator_buffers 1
#property indicator_plots   1
//--- plot индикатора1
#property indicator_label1  "ДСТСДСЦ+каналы с кнопками"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWheat
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Направление
#property indicator_label2  "Направление"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrMediumSeaGreen   // clrWheat
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- Запрашиваемые входные начальные параметры индикатора
//extern string Символ = "EURUSDb";    //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
string                Символ;    //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
extern string         InpName1="ВерхнийКанал";   // Имя канала 
extern string         InpName2="НижнийКанал";   // Имя канала
input color           InpColor1=clrRed;         // Цвет 1-го канала 
input color           InpColor2=clrBlue;        // Цвет 2-го канала
input color           InpColor3=clrOrange;      // Цвет 1-го канала для проверки 
input color           InpColor4=clrDodgerBlue;  // Цвет 2-го канала для проверки
input ENUM_LINE_STYLE InpStyle=STYLE_SOLID;     // Стиль линий канала 
//input int             InpWidth=1;             // Толщина линий канала 
input bool            InpBack=false;            // Канал на заднем плане 
//input bool            InpFill=false;          // Заливка канала цветом 
//input bool            InpSelection=true;      // Выделить для перемещений 
//input bool            InpRayRight=false;      // Продолжение канала вправо 
//input bool            InpRayRight=true;       // Продолжение канала вправо
//input bool            InpHidden=true;         // Скрыт в списке объектов 
//input long            InpZOrder=0;            // Приоритет на нажатие мышью 

int         Период;    //Время исполнения
extern int     КолБаров = 2;    //Кол-во баров в эспирации //1
extern int     КолЭспираций = 1;    //Кол-во проверяемых эспираций //1
string   InpName3, InpName4;   // Имя канала для проверки

//--- indicator buffers
double   БуферИндикатора[];  
//double   НаправлениеBuffer[];
 
struct структураЛинии {
   datetime точка1;
   datetime точка2;
   double точка1Знач;
   double точка2Знач;  
};
структураЛинии maxКанала, minКанала, maxКаналаДляПроверки, minКаналаДляПроверки;
структураЛинии maxИнд, minИнд, maxИндДляПроверки, minИндДляПроверки;

bool     старт;
datetime текущийТаймфрейм=0;
string   short_name,НазваниеЛиний[2],НазваниеЛинийДляПроверки[2];
//bool     Стоп, sМаксМинЛок[2][2], sМаксМинГлоб[2][2];   //, Лок, Глоб   //Массив для контроля заполненности точек тренд. линий
double   ind1, ind2, ind3;      //Значения индикатора(ind1 - 1-й бар, ind2 - 2-й бар, ...)
string   Отчёт;

int      wind_ex; //переменная хранит номер подокна индикатора
//double   РазницаКоэфициентов=0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,БуферИндикатора);   
   //SetIndexBuffer(1,НаправлениеBuffer);
   
//---Зададим отображаемое имя индикатору    
   short_name=WindowExpertName()+"("+string(КолБаров)+"/"+string(КолЭспираций)+"+)";
   IndicatorShortName(short_name);

   
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

   ArraySetAsSeries(БуферИндикатора,True);
   //ArraySetAsSeries(НаправлениеBuffer,True);
   
   СозданиеОбъекта("Кнопка1",132,10,"<",25,20); //создание кнопки "Кнопка1"(имя кнопки1,координата по Х,координата по Y,отображаемый текст,длина,высота)
   СозданиеОбъекта("Кнопка2",52,10,">",25,20);  //создание кнопки "Кнопка2"(имя кнопки2,координата по Х,координата по Y,отображаемый текст,длина,высота)
   СозданиеОбъекта("Поле1",104,10,"1",50,20);   //создание поля1 (число) (имя поля1,координата по Х,координата по Y,отображаемый текст,длина,высота)
   СозданиеОбъекта("Поле2",160,35,TimeToStr(Time[0]),150,20);   //создание поля2 (дата) (имя поля1,координата по Х,координата по Y,отображаемый текст,длина,высота)
   
   InpName3=StringConcatenate(InpName1,"Проверка");
   InpName4=StringConcatenate(InpName2,"Проверка");
   
//   Print("баров в истории = ",Bars);
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
 //                  const bool            selection=true,    // выделить для перемещений 
                   const bool            selection=false,   // выделить для перемещений
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

//--- удаление всех объектов в окне индикатора   
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
/*   
//---Проверка соответствия графика заданному периоду и выбранной валютной паре   
   if(Symbol()!=Символ || Period()!=Период){
      Символ=Symbol();
      Период=Period();
      OnInit();
      return(rates_total);
   }
*/
   if(старт){
      //Проверка соответствия графика заданному периоду и выбранной валютной паре 
/*      if(Symbol()!=Символ || Period()!=Период){
         OnInit();
         return(rates_total);
      }
*/      
      //Старт();
      if (Старт()) старт=false;
      
      if(wind_ex<0)  //проверка создания индикатора
         return(rates_total);
      //старт=False;
   }

//---Проверка достаточного количества баров в истории   
   //if(Bars<p1+2)  //p1- параметр индикатора
   if(Bars<КолБаров*(КолЭспираций+1)+2)
      return(rates_total);

//--- Проверка на обновление истории   
   if(текущийТаймфрейм!=Time[0]){
      //таймфрейм 0-го бара изменился 
      //---проверка для каналов     
      if(!ПоискБлижайшихЭкстремумовДляКаналов(2,true))
         return(rates_total);
      ПерестроениеКаналов(true);
      
      //---проверка для индикатора
      int последнийБар=iBarShift(NULL,0,текущийТаймфрейм,false);  //Определяем последний известный бар
      //заполняем индикатор пропущеннами барами 
      for(int bar=последнийБар; bar>=0; bar--){
         //БуферИндикатора[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(КолБаров,КолБаров*КолЭспираций))*(Close[bar]-Close[bar+КолБаров]*(1+1/КолЭспираций)-Close[bar+КолБаров*(КолЭспираций+1)]/КолЭспираций/КолБаров),Digits);    
         БуферИндикатора[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(bar+КолБаров,КолБаров*КолЭспираций))*(Close[bar]-Close[bar+КолБаров]*(1+1/КолЭспираций)+Close[bar+КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);
/*         
         int c=РасчётЛокДанных(bar);
         if(c>1){
            ПоискБлижайшихМаксМинИнд(bar+1,true);
            if(maxИнд.точка1>Time[Bars-1] && minИнд.точка1>Time[Bars-1])
               НаправлениеBuffer[bar+1]=ПоискРазницыКоэфициентов(bar+1);
         }else 
            НаправлениеBuffer[bar+1]=НаправлениеBuffer[bar+2];
*/      }      
      
      ПоискБлижайшихМаксМинИнд(2,true);
      ПереносТрендовыхЛинийИнд();
      
      текущийТаймфрейм=Time[0];  //присваиваем текущему таймфрейму таймфрейм 0-го бара
   } else
      //таймфрейм 0-го бара не изменялся (нужно чтобы индикатор изменялся при каждом тике)
      //БуферИндикатора[0]=NormalizeDouble((СредняяVolume(0,КолБаров)-СредняяVolume(КолБаров,КолБаров*КолЭспираций))*(Close[0]-Close[КолБаров]*(1+1/КолЭспираций)-Close[КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);    
      БуферИндикатора[0]=NormalizeDouble((СредняяVolume(0,КолБаров)-СредняяVolume(КолБаров,КолБаров*КолЭспираций))*(Close[0]-Close[КолБаров]*(1+1/КолЭспираций)+Close[КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);
   //bar=0;
   
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
//поиск окна  индикатора   
   wind_ex=WindowFind(short_name);
//----
   if(wind_ex<0)
      return false;

   //ArrayFill(maxMinДата,0,ArraySize(maxMinДата),Time[Bars-1]);
   maxКанала.точка1=Time[Bars-1];
   maxКанала.точка2=Time[Bars-1];
   maxКанала.точка1Знач=0.0;
   maxКанала.точка2Знач=0.0;
   
   minКанала=maxКанала;
   maxКаналаДляПроверки=maxКанала;
   minКаналаДляПроверки=maxКанала;
  
   //---Поиск эскстримумов для каналов
   if(!ПоискБлижайшихЭкстремумовДляКаналов(2,true))
      return false;
   //---Создание каналов
   if(!ChannelCreate(0,InpName1,0,maxКанала.точка1,maxКанала.точка1Знач,maxКанала.точка2,maxКанала.точка2Знач,minКанала.точка2,minКанала.точка2Знач,InpColor1, 
       InpStyle,1,false,InpBack,true,true,false)){ 
       Print("Неудалось создать основной верхний канал ", InpName1);
    }
   if(!ChannelCreate(0,InpName2,0,minКанала.точка1,minКанала.точка1Знач,minКанала.точка2,minКанала.точка2Знач,maxКанала.точка2,maxКанала.точка2Знач,InpColor2, 
       InpStyle,1,false,InpBack,true,true,false)){        
       Print("Неудалось создать основной нижний канал ", InpName2);
    }
   if(!ChannelCreate(0,InpName3,0,maxКанала.точка1,maxКанала.точка1Знач,maxКанала.точка2,maxКанала.точка2Знач,minКанала.точка2,minКанала.точка2Знач,InpColor3, 
       InpStyle,1,false,InpBack,true,true,false)){ 
       Print("Неудалось создать проверочный верхний канал ", InpName1);
    }
   if(!ChannelCreate(0,InpName4,0,minКанала.точка1,minКанала.точка1Знач,minКанала.точка2,minКанала.точка2Знач,maxКанала.точка2,maxКанала.точка2Знач,InpColor4, 
       InpStyle,1,false,InpBack,true,true,false)){        
       Print("Неудалось создать проверочный нижний канал ", InpName2);
    }
   
   //---Заполнение массива индикатора
   for(int bar=Bars-1-КолБаров*(КолЭспираций+1); bar>0; bar--)
      БуферИндикатора[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(bar+КолБаров,КолБаров*КолЭспираций))*(Close[bar]-Close[bar+КолБаров]*(1+1/КолЭспираций)+Close[bar+КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);
/*      
   maxИнд.точка1=Time[Bars-1];
   minИнд.точка1=Time[Bars-1];
   
   //---Заполнение массива индикатора
   for(int bar=Bars-КолБаров*(КолЭспираций+1)-2; bar>0; bar--){
      int c=РасчётЛокДанных(bar);
      if(c>1){
         ПоискБлижайшихМаксМинИнд(bar+1,true);
         if(maxИнд.точка1>Time[Bars-1] && minИнд.точка1>Time[Bars-1])
            НаправлениеBuffer[bar]=ПоискРазницыКоэфициентов(bar);
      }else 
         НаправлениеBuffer[bar]=НаправлениеBuffer[bar+1];
   }
*/   
   //---Создание линий индикатора
   for(int i=0;i<ArraySize(НазваниеЛиний);i++)
      switch(i){
         case 0:
            if(ObjectsTotal()>0) НазваниеЛиний[0]="МаксДСТСДСЦ"+string(ObjectsTotal());
            else НазваниеЛиний[0]="МаксДСТСДСЦ";
         case 1: 
            if(ObjectsTotal()>1) НазваниеЛиний[1]="МинДСТСДСЦ"+string(ObjectsTotal()-1);
            else НазваниеЛиний[1]="МинДСТСДСЦ";
      } 
   
   for(int i=0;i<ArraySize(НазваниеЛиний);i++){
      //--- сбросим значение ошибки 
      ResetLastError(); 
      if(НазваниеЛиний[i]=="")
         НазваниеЛиний[i]=StringConcatenate("Линия",i);
         
      if(!ObjectCreate(0,НазваниеЛиний[i],OBJ_TREND,wind_ex,Time[i+5],БуферИндикатора[i+5],Time[i+3],БуферИндикатора[i+3])){
         Print("Ошибка создания линии ",НазваниеЛиний[i],": code #",GetLastError());
      } else if(i<2)
         //--- установим цвет пары линий 
         ObjectSetInteger(0,НазваниеЛиний[i],OBJPROP_COLOR,clrOrange);  //clrRed
   } 
    
   for(int i=0;i<ArraySize(НазваниеЛинийДляПроверки);i++)
      switch(i){
         case 0:
            if(ObjectsTotal()>0) НазваниеЛинийДляПроверки[0]="МаксДСТСДЦ_проверка"+string(ObjectsTotal());
            else НазваниеЛинийДляПроверки[0]="МаксДСТСДЦ_проверка";
         case 1: 
            if(ObjectsTotal()>1) НазваниеЛинийДляПроверки[1]="МинДСТСДЦ_проверка"+string(ObjectsTotal()-1);
            else НазваниеЛинийДляПроверки[1]="МинДСТСДЦ_проверка";
      } 
   
   for(int i=0;i<ArraySize(НазваниеЛинийДляПроверки);i++){
      //--- сбросим значение ошибки 
      ResetLastError();      
      if(НазваниеЛинийДляПроверки[i]=="") 
         НазваниеЛинийДляПроверки[i]=StringConcatenate("ЛинияПроверочная",i);
         
      if(!ObjectCreate(0,НазваниеЛинийДляПроверки[i],OBJ_TREND,wind_ex,Time[i+5],БуферИндикатора[i+5],Time[i+3],БуферИндикатора[i+3])){
         Print("Ошибка создания проверочной линии ",НазваниеЛинийДляПроверки[i],": code #",GetLastError());
      } else if(i<2)
         //--- установим цвет пары линий 
         ObjectSetInteger(0,НазваниеЛинийДляПроверки[i],OBJPROP_COLOR,clrBlue);  //clrRed
   }
   
   текущийТаймфрейм=Time[1];
   
   //ArrayFill(МаксМинДатаИнд,0,ArraySize(МаксМинДатаИнд),Time[Bars-1]);
   //---поиск ближайших 2-х минимумов и 2-х максимумов
   ПоискБлижайшихМаксМинИнд(2,true);
   
//   ArrayCopy(МаксМинДатаИндДляПроверки,МаксМинДатаИнд,0,0,WHOLE_ARRAY);
   maxИндДляПроверки=maxИнд;
   minИндДляПроверки=minИнд;
   
   ПереносТрендовыхЛинийИнд();
   ПереносПроверочныхТрендовыхЛинийИнд();
      
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
   
   for(int bar=проверяемыйБар;bar<Bars-1;bar++){
      if(ПроверкаНаMax(bar)){
         if(типКаналов){
            if(точекMax==0){
               maxКанала.точка2=Time[bar];
               maxКанала.точка2Знач=NormalizeDouble(ind2,Digits);
            } else if(точекMax==1){
               maxКанала.точка1=Time[bar];
               maxКанала.точка1Знач=NormalizeDouble(ind2,Digits);
            }
         } else{
            if(точекMax==0){
               maxКаналаДляПроверки.точка2=Time[bar];
               maxКаналаДляПроверки.точка2Знач=NormalizeDouble(ind2,Digits);
            }else if(точекMax==1){
               maxКаналаДляПроверки.точка1=Time[bar];
               maxКаналаДляПроверки.точка1Знач=NormalizeDouble(ind2,Digits);
            }
         }
         точекMax++;
      }     
      if(ПроверкаНаMin(bar)){
         if(типКаналов){
            if(точекMin==0){
               minКанала.точка2=Time[bar];
               minКанала.точка2Знач=NormalizeDouble(ind2,Digits);
            }else if(точекMin==1){
               minКанала.точка1=Time[bar];
               minКанала.точка1Знач=NormalizeDouble(ind2,Digits);
            }
         } else {
            if(точекMin==0){
               minКаналаДляПроверки.точка2=Time[bar];
               minКаналаДляПроверки.точка2Знач=NormalizeDouble(ind2,Digits);
            }else if(точекMin==1){
               minКаналаДляПроверки.точка1=Time[bar];
               minКаналаДляПроверки.точка1Знач=NormalizeDouble(ind2,Digits);
            }
         }
         точекMin++;
      }
      
      if(точекMin>1 && точекMax>1) break;   
   }   
  
   if(точекMin>1 && точекMax>1) return true;
   else return false;
  }

//+------------------------------------------------------------------+
//| Проверка на максимум графика                                     |
//+------------------------------------------------------------------+
bool ПроверкаНаMax(int проверяемыйБар)
  {
   ind1 = High[проверяемыйБар-1];
   ind2 = High[проверяемыйБар];
   ind3 = High[проверяемыйБар+1];
      
   for(int i1=проверяемыйБар+1;i1<Bars;i1++)
      if(ind2 != High[i1]){
          ind3 = High[i1];
          break;
      }
   
   if(ind2==ind3) //не хватает баров для проверки
      return(false);
   
   if(ind2>ind1 && ind2>ind3) 
      return(true);
   
   return(false);  
  }

//+------------------------------------------------------------------+
//| Проверка на минимум графика                                      |
//+------------------------------------------------------------------+
bool ПроверкаНаMin(int проверяемыйБар)
  {
   ind1 = Low[проверяемыйБар-1];
   ind2 = Low[проверяемыйБар];
   ind3 = Low[проверяемыйБар+1];
      
   for(int i1=проверяемыйБар+1;i1<Bars;i1++)
      if(ind2 != Low[i1]){
          ind3 = Low[i1];
          break;
      }
   
   if(ind2==ind3) //не хватает баров для проверки
      return(false);
   
   if(ind2<ind1 && ind2<ind3) 
      return(true);
   
   return(false); 
  }

//+------------------------------------------------------------------+
//| Перестроение каналов                                             |
//+------------------------------------------------------------------+
void ПерестроениеКаналов(bool типКанала)
  {  
   //--- сдвигаем точки
   if(типКанала){
      ПерестроениеКанала(InpName1,maxКанала.точка1,maxКанала.точка1Знач,maxКанала.точка2,maxКанала.точка2Знач,minКанала.точка2,minКанала.точка2Знач);  //max 
      ПерестроениеКанала(InpName2,minКанала.точка1,minКанала.точка1Знач,minКанала.точка2,minКанала.точка2Знач,maxКанала.точка2,maxКанала.точка2Знач);  //min
   } else{
      ПерестроениеКанала(InpName3,maxКаналаДляПроверки.точка1,maxКаналаДляПроверки.точка1Знач,maxКаналаДляПроверки.точка2,maxКаналаДляПроверки.точка2Знач,minКаналаДляПроверки.точка2,minКаналаДляПроверки.точка2Знач);   
      ПерестроениеКанала(InpName4,minКаналаДляПроверки.точка1,minКаналаДляПроверки.точка1Знач,minКаналаДляПроверки.точка2,minКаналаДляПроверки.точка2Знач,maxКаналаДляПроверки.точка2,maxКаналаДляПроверки.точка2Знач);
   }
  }
  
//+------------------------------------------------------------------+
//| Перестроение каналов                                             |
//+------------------------------------------------------------------+
void ПерестроениеКанала(string name,datetime time1,double price1,datetime time2,double price2,datetime time3,double price3)
  {  
   //--- сдвигаем точки 
   
   if(!ИзменениеТочкиКанала(0,name,0,time1,price1)) 
      Print("(Канал ",name,", точка 1)"); 
   if(!ИзменениеТочкиКанала(0,name,1,time2,price2)) 
      Print("(Канал ",name,", точка 2)");
   if(!ИзменениеТочкиКанала(0,name,2,time3,price3)) 
      Print("(Канал ",name,", точка 3)");
   
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
//|                                                                  |
//+------------------------------------------------------------------+
void ПоискБлижайшихМаксМинИнд(int проверяемыйБар, bool типЛиний)
  {
   char c, точекMin=0, точекMax=0;
   
   //for(int bar=проверяемыйБар;bar<Bars-3-КолБаров*(КолЭспираций+1);bar++){      
   for(int bar=проверяемыйБар;bar<Bars-2;bar++){   
      c=РасчётЛокДанных(bar);
      if(c<0){
          Отчёт="Недостаточно данных в истории.";
          Print(Отчёт);
          return;
      } else if(c==2){
          if(типЛиний){
            if(точекMax==0){  // для максимумов основных линий
               maxИнд.точка2=Time[bar];
               maxИнд.точка2Знач=ind2;
             } else if(точекMax==1){
               maxИнд.точка1=Time[bar];
               maxИнд.точка1Знач=ind2;
             } 
          } else{ // для максимумов проверочных линий
            if(точекMax==0){
               maxИндДляПроверки.точка2=Time[bar];
               maxИндДляПроверки.точка2Знач=ind2;
             } else if(точекMax==1){
               maxИндДляПроверки.точка1=Time[bar];
               maxИндДляПроверки.точка1Знач=ind2;
             }
          } 
          точекMax++;
      } else if(c==3){ 
          if(типЛиний){ // для минимумов основных линий
            if(точекMin==0){
               minИнд.точка2=Time[bar];
               minИнд.точка2Знач=ind2;
             } else if(точекMin==1){
               minИнд.точка1=Time[bar];
               minИнд.точка1Знач=ind2;
             }
          } else{ // для минимумов проверочных линий
             if(точекMin==0){
               minИндДляПроверки.точка2=Time[bar];
               minИндДляПроверки.точка2Знач=ind2;
             } else if(точекMin==1){
               minИндДляПроверки.точка1=Time[bar];
               minИндДляПроверки.точка1Знач=ind2;
             }
          }
          точекMin++;
      }
         
      if(точекMin>1 && точекMax>1) break;   
   }   
  }
 
//+------------------------------------------------------------------+
//| Расчёт локальных экстримумов                                     |
//+------------------------------------------------------------------+
//bool РасчётДанных(int Предел)
char РасчётЛокДанных(int проверяемыйБар)
  {
   ind1 = БуферИндикатора[проверяемыйБар-1];
   ind2 = БуферИндикатора[проверяемыйБар];
   ind3 = БуферИндикатора[проверяемыйБар+1];
      
   //for(int i1=проверяемыйБар+3;i1<Bars-2-p1 && ind2==ind3;i1++)
   for(int i1=проверяемыйБар+1;i1<Bars;i1++)
      if(ind2 != БуферИндикатора[i1]){
          ind3 = БуферИндикатора[i1];
          break;
      }
   
   if(ind2==ind3 || ind3>2147483646.0) //не хватает баров для проверки
      return(-1);
         
   if(ind2>ind1 && ind2>ind3) // максимум по 3-м барам
      return(2);
             
   if(ind2<ind1 && ind2<ind3) // минимум по 3-м барам
      return(3);
        
//---  
   return(1);  
  }

//+------------------------------------------------------------------+
//| Перенос трендовых линий                                          |
//+------------------------------------------------------------------+
void ПереносТрендовыхЛинийИнд()
  {
   for(int i=0;i<ArraySize(НазваниеЛиний);i++){
      //--- сбросим значение ошибки 
      ResetLastError(); 
      if(i==0){
         if(!ObjectMove(0,НазваниеЛиний[i],1,maxИнд.точка2,maxИнд.точка2Знач)) 
            Print(__FUNCTION__, 
               ": не удалось переместить 2-ю точку привязки линии ",НазваниеЛиний[i],"! Код ошибки = ",GetLastError());
            
         ResetLastError();
         if(!ObjectMove(0,НазваниеЛиний[i],0,maxИнд.точка1,maxИнд.точка1Знач)) 
            Print(__FUNCTION__, 
                     ": не удалось переместить 1-ю точку привязки линии ",НазваниеЛиний[i],"! Код ошибки = ",GetLastError());
      } else if(i==1){
         if(!ObjectMove(0,НазваниеЛиний[i],1,minИнд.точка2,minИнд.точка2Знач)) 
            Print(__FUNCTION__, 
               ": не удалось переместить 2-ю точку привязки линии ",НазваниеЛиний[i],"! Код ошибки = ",GetLastError());
            
         ResetLastError();
         if(!ObjectMove(0,НазваниеЛиний[i],0,minИнд.точка1,minИнд.точка1Знач)) 
            Print(__FUNCTION__, 
               ": не удалось переместить 1-ю точку привязки линии ",НазваниеЛиний[i],"! Код ошибки = ",GetLastError());
       }
   }
  } 
//+------------------------------------------------------------------+
//| Перенос проверочных трендовых линий                              |
//+------------------------------------------------------------------+
void ПереносПроверочныхТрендовыхЛинийИнд()
  {
   for(int i=0;i<ArraySize(НазваниеЛинийДляПроверки);i++){
       //--- сбросим значение ошибки 
       ResetLastError(); 
       if(i==0){
          if(!ObjectMove(0,НазваниеЛинийДляПроверки[i],1,maxИндДляПроверки.точка2,maxИндДляПроверки.точка2Знач)) 
               Print(__FUNCTION__, 
                     ": не удалось переместить 2-ю точку привязки линии ",НазваниеЛинийДляПроверки[i],"! Код ошибки = ",GetLastError());
            
          ResetLastError();
          if(!ObjectMove(0,НазваниеЛинийДляПроверки[i],0,maxИндДляПроверки.точка1,maxИндДляПроверки.точка1Знач)) 
               Print(__FUNCTION__, 
                     ": не удалось переместить 1-ю точку привязки линии ",НазваниеЛинийДляПроверки[i],"! Код ошибки = ",GetLastError());
       } else if(i==1){
          if(!ObjectMove(0,НазваниеЛинийДляПроверки[i],1,minИндДляПроверки.точка2,minИндДляПроверки.точка2Знач)) 
               Print(__FUNCTION__, 
                     ": не удалось переместить 2-ю точку привязки линии ",НазваниеЛинийДляПроверки[i],"! Код ошибки = ",GetLastError());
            
          ResetLastError();
          if(!ObjectMove(0,НазваниеЛинийДляПроверки[i],0,minИндДляПроверки.точка1,minИндДляПроверки.точка1Знач)) 
               Print(__FUNCTION__, 
                     ": не удалось переместить 1-ю точку привязки линии ",НазваниеЛинийДляПроверки[i],"! Код ошибки = ",GetLastError());
       }
   }
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
   int проверяемыйБар=iBarShift(NULL,0,d,false)+1; 
/*   
if(проверяемыйБар==67)   
   int s=0;
/*
if(Time[проверяемыйБар]=="2024.04.26 20:45")   
   int s=0;
 */       
   //---перестановка линий индикатора
   if(проверяемыйБар>0 && проверяемыйБар<Bars-2){
      ПоискБлижайшихМаксМинИнд(проверяемыйБар+1,false);
      
      ПереносПроверочныхТрендовыхЛинийИнд();
   }
   //---перестановка каналов
   if(проверяемыйБар>0 && проверяемыйБар<Bars-2){
      if(ПоискБлижайшихЭкстремумовДляКаналов(проверяемыйБар+1,false)){
         ПерестроениеКаналов(false);
         
//         ПереносПроверочныхТрендовыхЛинийИнд();
      }
   }
/*   
//   Comment(short_name+"\r\n"+Т+"\r\n"+Т1);
   Comment(StringConcatenate("max1=", maxИнд.точка1, "; max2=", minИнд.точка1, "; min1=", maxИнд.точка2, "; min2=",  minИнд.точка2, "\r\n", 
           "max1=", maxИнд.точка1Знач, "; max2=", minИнд.точка1Знач, "; min1=", maxИнд.точка2Знач, "; min2=",  minИнд.точка2Знач, "\r\n" , 
           "max1=", maxИндДляПроверки.точка1, "; max2=", minИндДляПроверки.точка1, "; min1=", maxИндДляПроверки.точка2, "; min2=",  minИндДляПроверки.точка2, "\r\n", 
           "max1=", maxИндДляПроверки.точка1Знач, "; max2=", minИндДляПроверки.точка1Знач, "; min1=", maxИндДляПроверки.точка2Знач, "; min2=",  minИндДляПроверки.точка2Знач));
*/   
   ChartRedraw();

  }
/*
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
   
   //return NormalizeDouble(m-n,5);
   return NormalizeDouble((m+n)*(-1),5);
   
  } 
*/
//+------------------------------------------------------------------+
