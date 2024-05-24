//+------------------------------------------------------------------+
//|                                                       Таймер.mq4 |
//|                                                                Я |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Я"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window
//--- входные параметры скрипта 
input string            InpName="Label";         // Имя метки 
input int               InpX=10;                // Расстояние по оси X 
input int               InpY=150;                // Расстояние по оси Y 
input string            InpFont="Arial";         // Шрифт 
input int               InpFontSize=14;          // Размер шрифта 
input color             InpColor=clrRed;         // Цвет 
input double            InpAngle=0.0;            // Угол наклона в градусах 
input ENUM_ANCHOR_POINT InpAnchor=ANCHOR_RIGHT_LOWER; // Способ привязки 
input bool              InpBack=false;           // Объект на заднем плане 
input bool              InpSelection=true;       // Выделить для перемещений 
input bool              InpHidden=true;          // Скрыт в списке объектов 
input long              InpZOrder=0;             // Приоритет на нажатие мышью 

//--- input parameters
//int   Секунды;
bool  старт=true;
string текст="прошло ";
long x_distance; 
long y_distance; 

//--- indicator buffers
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
//   SetIndexBuffer(0,Label1Buffer);
   EventSetTimer(1);
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   LabelDelete(0,InpName);
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
   if(старт)
      Start();
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   текст=StringConcatenate("Прошло ",Seconds()," секунд");
   MoveAndTextChange(x_distance-5,y_distance-5,текст);
   ChartRedraw(); 
   
  }

//+------------------------------------------------------------------+ 
//| Создает текстовую метку                                          | 
//+------------------------------------------------------------------+ 
bool LabelCreate(const long              chart_ID=0,               // ID графика 
                 const string            name="Label",             // имя метки 
                 const int               sub_window=0,             // номер подокна 
                 const int               x=0,                      // координата по оси X 
                 const int               y=0,                      // координата по оси Y 
                 const ENUM_BASE_CORNER  corner=CORNER_RIGHT_LOWER, // угол графика для привязки 
                 const string            text="Label",             // текст 
                 const string            font="Arial",             // шрифт 
                 const int               font_size=10,             // размер шрифта 
                 const color             clr=clrRed,               // цвет 
                 const double            angle=0.0,                // наклон текста 
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_CENTER, // способ привязки 
                 const bool              back=false,               // на заднем плане 
                 const bool              selection=false,          // выделить для перемещений 
                 const bool              hidden=true,              // скрыт в списке объектов 
                 const long              z_order=0)                // приоритет на нажатие мышью 
  { 
//--- сбросим значение ошибки 
   ResetLastError(); 
//--- создадим текстовую метку 
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось создать текстовую метку! Код ошибки = ",GetLastError()); 
      return(false); 
     } 
//--- установим координаты метки 
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x); 
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y); 
//--- установим угол графика, относительно которого будут определяться координаты точки 
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner); 
//--- установим текст 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text); 
//--- установим шрифт текста 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font); 
//--- установим размер шрифта 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size); 
//--- установим угол наклона текста 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle); 
//--- установим способ привязки 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor); 
//--- установим цвет 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- отобразим на переднем (false) или заднем (true) плане 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- включим (true) или отключим (false) режим перемещения метки мышью 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- скроем (true) или отобразим (false) имя графического объекта в списке объектов 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- установим приоритет на получение события нажатия мыши на графике 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- успешное выполнение 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Перемещает текстовую метку                                       | 
//+------------------------------------------------------------------+ 
bool LabelMove(const long   chart_ID=0,   // ID графика 
               const string name="Label", // имя метки 
               const int    x=0,          // координата по оси X 
               const int    y=0)          // координата по оси Y 
  { 
//--- сбросим значение ошибки 
   ResetLastError(); 
//--- переместим текстовую метку 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось переместить X-координату метки! Код ошибки = ",GetLastError()); 
      return(false); 
     } 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось переместить Y-координату метки! Код ошибки = ",GetLastError()); 
      return(false); 
     } 
//--- успешное выполнение 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Изменяет угол графика для привязки метки                         | 
//+------------------------------------------------------------------+ 
bool LabelChangeCorner(const long             chart_ID=0,               // ID графика 
                       const string           name="Label",             // имя метки 
                       const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER) // угол графика для привязки 
  { 
//--- сбросим значение ошибки 
   ResetLastError(); 
//--- изменим угол привязки 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось изменить угол привязки! Код ошибки = ",GetLastError()); 
      return(false); 
     } 
//--- успешное выполнение 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Изменяет текст объекта                                           | 
//+------------------------------------------------------------------+ 
bool LabelTextChange(const long   chart_ID=0,   // ID графика 
                     const string name="Label", // имя объекта 
                     const string text="Text")  // текст 
  { 
//--- сбросим значение ошибки 
   ResetLastError(); 
//--- изменим текст объекта 
   if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось изменить текст! Код ошибки = ",GetLastError()); 
      return(false); 
     } 
//--- успешное выполнение 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Удаляет текстовую метку                                          | 
//+------------------------------------------------------------------+ 
bool LabelDelete(const long   chart_ID=0,   // ID графика 
                 const string name="Label") // имя метки 
  { 
//--- сбросим значение ошибки 
   ResetLastError(); 
//--- удалим метку 
   if(!ObjectDelete(chart_ID,name)) 
     { 
      Print(__FUNCTION__, 
            ": не удалось удалить текстовую метку! Код ошибки = ",GetLastError()); 
      return(false); 
     } 
//--- успешное выполнение 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Script program start function                                    | 
//+------------------------------------------------------------------+ 
void Start() 
  { 
//--- запомним координаты метки в локальные переменные 
   int x=InpX; 
   int y=InpY; 
//--- размеры окна графика 
//   long x_distance; 
  // long y_distance; 
//--- определим размеры окна 
   if(!ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0,x_distance)) 
     { 
      Print("Не удалось получить ширину графика! Код ошибки = ",GetLastError()); 
      return; 
     } 
   if(!ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0,y_distance)) 
     { 
      Print("Не удалось получить высоту графика! Код ошибки = ",GetLastError()); 
      return; 
     } 
//--- проверим входные параметры на корректность 
   if(InpX<0 || InpX>x_distance-1 || InpY<0 || InpY>y_distance-1) 
     { 
      Print("Ошибка! Некорректные значения входных параметров!"); 
      return; 
     } 
//--- подготовим начальный текст для метки 
//   string text; 
  // text=StringConcatenate("Левый верхний угол: ",x,",",y); 
//--- создадим текстовую метку на графике 
   if(!LabelCreate(0,InpName,0,InpX,InpY,CORNER_LEFT_UPPER,текст,InpFont,InpFontSize, 
      InpColor,InpAngle,InpAnchor,InpBack,InpSelection,InpHidden,InpZOrder)) 
     { 
      return; 
     } 
//--- перерисуем график и подождем полсекунды 
   ChartRedraw(); 
/*   
   
   
   Sleep(500); 
//--- будем перемещать метку и одновременно менять ее текст 
//--- количество итераций по осям 
   int h_steps=(int)(x_distance/2-InpX); 
   int v_steps=(int)(y_distance/2-InpY); 
//--- переместим метку вниз 
   for(int i=0;i<v_steps;i++) 
     { 
      //--- меняем координату 
      y+=2; 
      //--- перемещаем метку и меняем ее текст 
      MoveAndTextChange(x,y,"Левый верхний угол: "); 
     } 
//--- задержка в полсекунды 
   Sleep(500); 
//--- переместим метку вправо 
   for(int i=0;i<h_steps;i++) 
     { 
      //--- меняем координату 
      x+=2; 
      //--- перемещаем метку и меняем ее текст 
      MoveAndTextChange(x,y,"Левый верхний угол: "); 
     } 
//--- задержка в полсекунды 
   Sleep(500); 
//--- переместим метку вверх 
   for(int i=0;i<v_steps;i++) 
     { 
      //--- меняем координату 
      y-=2; 
      //--- перемещаем метку и меняем ее текст 
      MoveAndTextChange(x,y,"Левый верхний угол: "); 
     } 
//--- задержка в полсекунды 
   Sleep(500); 
//--- переместим метку влево 
   for(int i=0;i<h_steps;i++) 
     { 
      //--- меняем координату 
      x-=2; 
      //--- перемещаем метку и меняем ее текст 
      MoveAndTextChange(x,y,"Левый верхний угол: "); 
     } 
//--- задержка в полсекунды 
   Sleep(500); 
//--- теперь переместим точку путем изменения угла привязки 
//--- переместим в левый нижний угол 
   if(!LabelChangeCorner(0,InpName,CORNER_LEFT_LOWER)) 
      return; 
//--- изменим текст метки 
   text=StringConcatenate("Левый нижний угол: ",x,",",y); 
   if(!LabelTextChange(0,InpName,text)) 
      return; 
//--- перерисуем график и подождем две секунды 
   ChartRedraw(); 
   Sleep(2000); 
//--- переместим в правый нижний угол 
   if(!LabelChangeCorner(0,InpName,CORNER_RIGHT_LOWER)) 
      return; 
//--- изменим текст метки 
   text=StringConcatenate("Правый нижний угол: ",x,",",y); 
   if(!LabelTextChange(0,InpName,text)) 
      return; 
//--- перерисуем график и подождем две секунды 
   ChartRedraw(); 
   Sleep(2000); 
//--- переместим в правый верхний угол 
   if(!LabelChangeCorner(0,InpName,CORNER_RIGHT_UPPER)) 
      return; 
//--- изменим текст метки 
   text=StringConcatenate("Правый верхний угол: ",x,",",y); 
   if(!LabelTextChange(0,InpName,text)) 
      return; 
//--- перерисуем график и подождем две секунды 
   ChartRedraw(); 
   Sleep(2000); 
//--- переместим в левый верхний угол 
   if(!LabelChangeCorner(0,InpName,CORNER_LEFT_UPPER)) 
      return; 
//--- изменим текст метки 
   text=StringConcatenate("Левый верхний угол: ",x,",",y); 
   if(!LabelTextChange(0,InpName,text)) 
      return; 
//--- перерисуем график и подождем две секунды 
   ChartRedraw(); 
   Sleep(2000); 
//--- удалим метку 
   LabelDelete(0,InpName); 
//--- перерисуем график и подождем полсекунды 
   ChartRedraw(); 
   Sleep(500); 
//--- 
*/  
  } 
//+------------------------------------------------------------------+ 
//| Функция перемещает объект и меняет его текст                     | 
//+------------------------------------------------------------------+ 
bool MoveAndTextChange(const int x,const int y,string text) 
  { 
//--- перемещаем метку 
   if(!LabelMove(0,InpName,x,y)) 
      return(false); 
//--- изменим текст метки 
//   text=StringConcatenate(text,x,",",y); 
   if(!LabelTextChange(0,InpName,text)) 
      return(false); 
//--- проверим факт принудительного завершения скрипта 
   if(IsStopped()) 
      return(false); 
//--- перерисуем график 
   ChartRedraw(); 
// задержка в 0.01 секунды 
   Sleep(10); 
//--- выход из функции 
   return(true); 
  }
//+------------------------------------------------------------------+
