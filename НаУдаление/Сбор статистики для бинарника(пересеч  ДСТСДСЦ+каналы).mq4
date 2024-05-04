//+------------------------------------------------------------------+
//|                                              Сбор статистики.mq4 |
//|                                                                Я |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Я"
#property link      ""
#property version   "1.00"
#property strict
#include <MovingAverages.mqh>
#include <WinUser32.mqh>

#property description "Запись статистики в файл для анализа пресечений линий индикатора ДСТСДСЦ и каналов"
//--- input parameters
input string InpFileName0="Cтатистика для пересеч ТЛ ДСТСДСЦ и каналов";      // Имя файла .csv
input string InpDirectoryName="Мои данные";     // Имя каталога
//extern bool  РасширОтчёт=false;    //Вывод расширенного отчёта 
extern bool  РасширОтчёт=true;    //Вывод расширенного отчёта 

extern int   Нач = 7;            //8 Начало работы (часы) // 0 - круглосуточно
extern int   Кон = 22;           //22 Конец работы (часы) // 24 - круглосуточно
extern int   КолБаров = 2;        //Кол-во баров в эспирации //1
extern int   КолЭспираций = 1;    //Кол-во проверяемых эспираций //1
extern char  баровПроверки = 3;   //Кол-во проверяемых баров для макс/мин //5
string       Символ;              //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)

/*
extern string Символ = "EURUSDb";    //Валютная пара графика (GBPUSDb,USDJPYb,USDCHFb,AUDUSDb...)
extern int Период    = PERIOD_M1;    //Время исполнения
/*
string   Символ;
int      Период;
*/
string InpFileName;
int    file_handle;

struct структураЛинии {
   datetime точка1;
   datetime точка2;
   double точка1Знач;
   double точка2Знач;
};
структураЛинии верхнийКанал, нижнийКанал, maxИнд, minИнд;

struct наборДанных {
   string  направлМА;                  // "В" - вверх, "Н" - вниз, "="
   char    колПересечОснЛинКаналов;    // Кол-во пересеч. основных линий каналов перед 1-м баром
   char    колПересечДопЛинКаналов;    // Кол-во пересеч. дополнтельных линий каналов перед 1-м баром
   
   string  перестроениеТЛ;             // "Д" - да, "?Н" - кол-во нет + нет
   string  положТочПересечТЛ;          // "П" - после бара последней точки, "М" - между последней точкой и 1-м баром, "Д" - до 1-го бара
   char    колПересечТЛ;               // Кол-во пересеч. трендовых линий перед 1-м баром
   string  МаксОтносМин;               // "В" - выше, "Н" - ниже на проверяемом баре (ТЛ-трендовая линия индикатора)
   string  положЗначИндОтносТЛ;        // "В" - выше, "М" - между, "Н" - ниже на проверяемом баре
   string  пробойТЛ;                   // "В" - вверх, "Н" - вниз, 0 - нет пробоя
   string  направлЛинииИнд;            // "В" - вверх, "Н" - вниз, "="
   
   string  направлПредБара;            // "В" - вверх, "Н" - вниз, "=" (Кол-во предыдущих баров для проверки = КолБаров)
   string  направлТекБара;             // "В" - вверх, "Н" - вниз, "=" (Кол-во текущих баров для проверки = КолБаров)
};
наборДанных статстика[];
/*
struct структураПересеч {
   int сумма=0;
   string тип="";
};
структураПересеч  пересечКаналов[], пересечИнд[];
*/
struct структурапересечКаналов {
   char суммаОсн;
   char суммаДоп;
};
структурапересечКаналов  пересечКаналов[];
//double      пересечКаналов[];
char      пересечИнд[];
double    индBuffer[];
string    типЛинийКанала="_";

struct структураИтоги {
   string код;
   int    вверх;
   int    вниз;
   int    всего;
};
структураИтоги таблицаКодов[];

double ind2;


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {/*
   for(int i=0; i<5;i++)
      if(Symbol()!=Символ || Period()!=Период)
         НастройкаГрафика();
      else 
         {i=5; Старт=True;}
   
   if(!Старт) 
      {Comment("Скрипт не выполнен. Не удалось настроить график.");
       Print("Скрипт не выполнен. Не удалось настроить график.");
       return;
      }
 */  
   Comment("");
   if(Нач<0 || Нач>23) Нач=0;
   if(Кон<=Нач || Кон>24) Кон=24;
   if(КолБаров<1) КолБаров=1;
   if(КолЭспираций<1) КолЭспираций=1;
   if(баровПроверки<3) баровПроверки=3;
   else if(MathMod(баровПроверки,2)==0) баровПроверки++;
   
   Statistic();
  
  } 

//+------------------------------------------------------------------+
//| Настройка Графика                                                |
//+------------------------------------------------------------------+
int НастройкаГрафика()
  {
//--- получение handle текущего графика
   long handle=ChartID();
   if(handle>0){ // если получилось, дополнительно настроим
     IndicatorDigits(Digits);

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
     
   } else 
      return(-1);
      
//---
   return(1);
  
  }

//+------------------------------------------------------------------+
//| Запись шапки в файл                                              |
//+------------------------------------------------------------------+
char File_Write()
  {
   FileDelete(InpDirectoryName+"//"+InpFileName,FILE_READ|FILE_WRITE|FILE_CSV);
   file_handle=FileOpen(InpDirectoryName+"//"+InpFileName,FILE_READ|FILE_WRITE|FILE_CSV); 
   if(file_handle!=INVALID_HANDLE){ 
      PrintFormat("Файл %s открыт для записи",InpFileName); 
      PrintFormat("Путь к файлу: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH)); 
//--- сначала запишем количество сигналов, создадим шапку и запишем в файл
      FileWrite(file_handle,"Баров для обработки:",Bars,"Период:",Period()," мин","Дата начала:",Time[Bars-1]);

      if(!РасширОтчёт){
         FileWrite(file_handle,"Расшифровка кода: НаправлМА,колПересечОснЛинКаналов, колПересечДопЛинКаналов, перестроениеТЛ, положТочПересечТЛ, колПересечТЛ, МаксОтносМин, положЗначИндОтносТЛ, пробойТЛ, направлЛинииИнд, направлПредБара, направлТекБара");
         FileWrite(file_handle,"","","","|Для Откр/Закр","","","","","","|Для Закр/Закр");
         FileWrite(file_handle,"№ п/п","Код в табл. ''Коды''","Вверх","Вниз","Ноль","Всего","% Вверх","% Вниз","% Ноль","%Вверх/Вниз");
      } else{
         FileWrite(file_handle,"","","|По каналам","","","|По Инд ДСТСДСЦ","","","","","","","","|По бару","|");
         FileWrite(file_handle,"№ п/п","Дата",StringConcatenate("Направл.МА",КолБаров),"колПересечОснЛинКаналов","колПересечДопЛинКаналов","перестроениеТЛ","Полож.точки пересеч.ТЛ баров",
                  "пересеч.ТЛ Инд баров","МаксОтносМин","Полож.линии Инд.к ТЛ","пробойТЛ","Направл.линии Инд","Направл.пред.бара","Направл.тек.бара");
      }
   } else{
      PrintFormat("Не удалось открыть файл %s, Код ошибки = %d",InpFileName,GetLastError()); 
      return(1);
   }
//---  
   return(-1);
  }

//+------------------------------------------------------------------+
//| Статистика                                                       |
//+------------------------------------------------------------------+
void Statistic()  
  {int Счётчик=0;
   char счётчикНет=0;
   
   //string положТочПересечТЛ="_";   
   
   //ArraySetAsSeries(пересечКаналов,True);
   //ArraySetAsSeries(пересечИнд,True);   
   ArraySetAsSeries(индBuffer,True);
   //ArraySetAsSeries(статстика,True);
   
   верхнийКанал.точка1=Time[Bars-1];
   верхнийКанал.точка2=Time[Bars-1];
   верхнийКанал.точка1Знач=0.0;
   верхнийКанал.точка2Знач=0.0;
   
   нижнийКанал=верхнийКанал;
   maxИнд=верхнийКанал;
   minИнд=верхнийКанал;
   
   ArrayResize(статстика,Bars);
   ArrayResize(пересечКаналов,Bars);
   ArrayResize(пересечИнд,Bars);
   
   for(int bar=Bars-1; bar>0; bar--){      
/*     
if(bar==2032)
   int a=0;     
*/    
      //if(TimeHour(Time[bar])<Нач  || TimeHour(Time[bar])>Кон)
        // continue;
      // Расчёт индикатора
      if(bar<Bars-КолБаров*(КолЭспираций+1)){
         if(ArraySize(индBuffer)<Bars)
            ArrayResize(индBuffer,Bars);

         индBuffer[bar]=NormalizeDouble((СредняяVolume(bar,КолБаров)-СредняяVolume(bar+КолБаров,КолБаров*КолЭспираций))*(Close[bar]-Close[bar+КолБаров]*(1+1/КолЭспираций)+Close[bar+КолБаров*(КолЭспираций+1)]/КолЭспираций)/КолБаров,Digits);
         
         if(ПроверкаИнд_НаЭкстримумы(bar+2)){
            int точкаПересеч=ПоискПересеченийЛиний(bar,"");
            if(точкаПересеч<1){
               // точка пересечения (точкаПересеч) правее или на тек. баре (bar)
               if(ArraySize(пересечИнд)<Bars-bar-точкаПересеч+1)
                  ArrayResize(пересечИнд,Bars-bar-точкаПересеч+1);
               
               //пересечИнд[Bars-1-bar-точкаПересеч]--;
               пересечИнд[Bars-1-bar-точкаПересеч]++;
               статстика[bar].положТочПересечТЛ="Д";
               //положТочПересечТЛ="Д";
            } else{
               int т1=iBarShift(NULL,0,maxИнд.точка1,false);
               int т2=iBarShift(NULL,0,minИнд.точка1,false);
               if(точкаПересеч>т1 && точкаПересеч>т2){
                  статстика[bar].положТочПересечТЛ="П";
                  //положТочПересечТЛ="П";
               }
               else{
                  статстика[bar].положТочПересечТЛ="М";
                  //положТочПересечТЛ="М";
               }
            }
            счётчикНет=0;
            статстика[bar].перестроениеТЛ="Д";
         } else{
            счётчикНет++;
            статстика[bar].перестроениеТЛ=StringConcatenate(счётчикНет,"Н");
            статстика[bar].положТочПересечТЛ=статстика[bar+1].положТочПересечТЛ;
            //статстика[bar].положТочПересечТЛ=положТочПересечТЛ;
            статстика[bar].колПересечТЛ=0;
            статстика[bar].МаксОтносМин="_";
            статстика[bar].положЗначИндОтносТЛ="_";
            статстика[bar].пробойТЛ="_";
            статстика[bar].направлЛинииИнд="_";
         }
      } else{
         статстика[bar].перестроениеТЛ="_";
         статстика[bar].положТочПересечТЛ="_";
         статстика[bar].колПересечТЛ=0;
         статстика[bar].МаксОтносМин="_";
         статстика[bar].положЗначИндОтносТЛ="_";
         статстика[bar].пробойТЛ="_";
         статстика[bar].направлЛинииИнд="_";
      }

      // Расчёт каналов
      if(bar<Bars-1-баровПроверки){
         if(ПроверкаКаналовНаЭкстремумы(bar+int((баровПроверки-1)/2))){
            int точкаПересеч=ПоискПересеченийЛиний(bar,"канал");
            if(точкаПересеч<=0){
               // точка пересечения (точкаПересеч) правее или на тек. баре (bar)
               if(ArraySize(пересечКаналов)<Bars-bar-точкаПересеч+1)
                  ArrayResize(пересечКаналов,Bars-bar-точкаПересеч+1);
            
               if(типЛинийКанала=="О")
                  пересечКаналов[Bars-1-bar-точкаПересеч].суммаОсн++;
               else if(типЛинийКанала=="Д")
                  пересечКаналов[Bars-1-bar-точкаПересеч].суммаДоп++;            
            }
            //статстика[bar].типЛинииКанала=типЛинийКанала;                     
         } else{
            пересечКаналов[Bars-1-bar].суммаОсн=0;
            пересечКаналов[Bars-1-bar].суммаДоп=0;
         } 
      } else{
         пересечКаналов[Bars-1-bar].суммаОсн=0;
         пересечКаналов[Bars-1-bar].суммаДоп=0;
      }
      
      if(bar<Bars-КолБаров*2){
/*         double m1=iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar+2);
         double m2=iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar+3);
         double m3=iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar);
         double m4=iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,Bars-КолБаров);
         double m5=iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,Bars-КолБаров-1);
*/         
 //        статстика[bar].направлМА=iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar+1)-iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar+КолБаров+1)>0 ? "В" : 
   //                            iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar+1)-iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar+КолБаров+1)<0 ? "Н" : "=";
         статстика[bar].направлМА=iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar+2)-iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar+3)>0 ? "В" : 
                               iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar+2)-iMA(NULL,0,КолБаров,0,MODE_SMA,PRICE_CLOSE,bar+3)<0 ? "Н" : "=";
                      
      
      } else 
         статстика[bar].направлМА="_"; 
      
      if(ArraySize(пересечКаналов)>Bars-1-bar){
         статстика[bar].колПересечОснЛинКаналов=пересечКаналов[Bars-1-bar].суммаОсн;
         статстика[bar].колПересечДопЛинКаналов=пересечКаналов[Bars-1-bar].суммаДоп;
      }else{
         статстика[bar].колПересечОснЛинКаналов=0;
         статстика[bar].колПересечДопЛинКаналов=0;
      }
      
      if(ArraySize(пересечИнд)>Bars-1-bar)
         статстика[bar].колПересечТЛ=пересечИнд[Bars-1-bar];
      else
         статстика[bar].колПересечТЛ=0;
      
      if(bar+КолБаров+1<Bars)
         статстика[bar].направлПредБара=Close[bar+КолБаров+1]>Close[bar+1] ? "Н" : Close[bar+КолБаров+1]<Close[bar+1] ? "В" : "=";
      else
         статстика[bar].направлПредБара="_";
      
      if(bar-КолБаров+1>0 && bar+КолБаров-1<Bars)
         статстика[bar].направлТекБара=Close[bar+КолБаров-1]>Close[bar-КолБаров+1] ? "Н" : Close[bar+КолБаров-1]<Close[bar-КолБаров+1] ? "В" : "=";
      else статстика[bar].направлТекБара="_";
/*   
      string код=StringConcatenate(статстика[bar].направлМА,статстика[bar].колПересечОснЛинКаналов,статстика[bar].колПересечДопЛинКаналов,статстика[bar].перестроениеТЛ,
                     статстика[bar].положТочПересечТЛ,статстика[bar].колПересечТЛ,статстика[bar].МаксОтносМин,статстика[bar].положЗначИндОтносТЛ,
                     статстика[bar].пробойТЛ,статстика[bar].направлЛинииИнд,статстика[bar].направлПредБара,статстика[bar].направлТекБара);
   
      if((StringLen(код)<12 && счётчикНет<10) || (StringLen(код)<13 && счётчикНет>9))
         bool s=true;
*/   
   }    

//--- Запись в файл  
   string tt="";
   if(РасширОтчёт)
      InpFileName=StringConcatenate(InpFileName0,"(",Symbol(),"(",Period(),")).csv" );
   else
      InpFileName=StringConcatenate(InpFileName0,"(",Symbol(),"(",Period(),")(ИТОГИ)).csv" );
   
   if(File_Write()>0){
      tt=StringConcatenate("Не удалось записать данные в файл ",InpFileName,"!");
      Comment(tt);
      return;
   }   

   if(РасширОтчёт)
      for(int bar=Bars-1; bar>0; bar--){
         Счётчик++;
         FileWrite(file_handle,Счётчик,Time[bar],статстика[bar].направлМА,статстика[bar].колПересечОснЛинКаналов,статстика[bar].колПересечДопЛинКаналов,статстика[bar].перестроениеТЛ,
                     статстика[bar].положТочПересечТЛ,статстика[bar].колПересечТЛ,статстика[bar].МаксОтносМин,статстика[bar].положЗначИндОтносТЛ,
                     статстика[bar].пробойТЛ,статстика[bar].направлЛинииИнд,статстика[bar].направлПредБара,статстика[bar].направлТекБара,Open[bar],Close[bar]);
      }
   else{
      string код="";
      for(int i=ArraySize(статстика)-1;i>=0; i--){
         if(TimeHour(Time[i])<Нач  || TimeHour(Time[i])>Кон)
            continue;
         
         код=StringConcatenate(статстика[i].направлМА,статстика[i].колПересечОснЛинКаналов,статстика[i].колПересечДопЛинКаналов,статстика[i].перестроениеТЛ,
                     статстика[i].положТочПересечТЛ,статстика[i].колПересечТЛ,статстика[i].МаксОтносМин,статстика[i].положЗначИндОтносТЛ,
                     статстика[i].пробойТЛ,статстика[i].направлЛинииИнд,статстика[i].направлПредБара);
      //-- Записькода
         int  позиция=0;
         if(ArraySize(таблицаКодов)==0 || код>таблицаКодов[ArraySize(таблицаКодов)-1].код){
            ArrayResize(таблицаКодов,ArraySize(таблицаКодов)+1);
            позиция=ArraySize(таблицаКодов)-1;
            //таблицаКодов[позиция].код=код;            
         } else if(код==таблицаКодов[0].код)
            позиция=0;
         else if(код==таблицаКодов[0].код || код==таблицаКодов[ArraySize(таблицаКодов)-1].код)
            позиция=ArraySize(таблицаКодов)-1;
         else if(код<таблицаКодов[0].код){
            ArrayResize(таблицаКодов,ArraySize(таблицаКодов)+1);
            позиция=0;
            for(int i1=ArraySize(таблицаКодов)-1; i1>позиция;i1--){
               таблицаКодов[i1].код=таблицаКодов[i1-1].код;
               таблицаКодов[i1].вверх=таблицаКодов[i1-1].вверх;
               таблицаКодов[i1].вниз=таблицаКодов[i1-1].вниз;
               таблицаКодов[i1].всего=таблицаКодов[i1-1].всего;
            }
         } else {
            bool поиск=true;
            позиция=int(MathFloor((ArraySize(таблицаКодов)-1)/2));
            int мин=0, макс=ArraySize(таблицаКодов)-1;
            
            while(поиск) {
               if(таблицаКодов[позиция].код==код)
                  поиск=false;
               else if(таблицаКодов[позиция].код>код){
                  if(таблицаКодов[позиция-1].код<код){
                     ArrayResize(таблицаКодов,ArraySize(таблицаКодов)+1);                  
                     for(int i1=ArraySize(таблицаКодов)-1; i1>позиция;i1--){
                        таблицаКодов[i1].код=таблицаКодов[i1-1].код;
                        таблицаКодов[i1].вверх=таблицаКодов[i1-1].вверх;
                        таблицаКодов[i1].вниз=таблицаКодов[i1-1].вниз;
                        таблицаКодов[i1].всего=таблицаКодов[i1-1].всего;
                     }
                     поиск=false;
                  } else if(таблицаКодов[позиция-1].код==код){
                     позиция--;
                     поиск=false;
                  } else{
                     макс=позиция;
                     позиция=int(MathFloor((макс+мин)/2));
                  }
               } else if(таблицаКодов[позиция].код<код){
                  if(таблицаКодов[позиция+1].код>код){
                     ArrayResize(таблицаКодов,ArraySize(таблицаКодов)+1);                  
                     for(int i1=ArraySize(таблицаКодов)-1; i1>позиция;i1--){
                        таблицаКодов[i1].код=таблицаКодов[i1-1].код;
                        таблицаКодов[i1].вверх=таблицаКодов[i1-1].вверх;
                        таблицаКодов[i1].вниз=таблицаКодов[i1-1].вниз;
                        таблицаКодов[i1].всего=таблицаКодов[i1-1].всего;
                     }
                     позиция++;
                     поиск=false;
                  } else if(таблицаКодов[позиция+1].код==код){
                     позиция++;
                     поиск=false;
                  } else{
                     мин=позиция;
                     позиция=int(MathFloor((макс+мин)/2));
                  }
               }
            }
         }
         
         таблицаКодов[позиция].код=код;
         
         if(статстика[i].направлПредБара=="В")
            таблицаКодов[позиция].вверх++;
         else if(статстика[i].направлПредБара=="Н")
            таблицаКодов[позиция].вниз++;
         
         таблицаКодов[позиция].всего++;
      }
      
      double d,d1,d2,d3;
      for(int i=0;i<ArraySize(таблицаКодов);i++){
         Счётчик++;
         if(таблицаКодов[i].всего==0){
            d=0; d1=0; d2=0;
         } else{
            d=NormalizeDouble(таблицаКодов[i].вверх/таблицаКодов[i].всего,2);
            d1=NormalizeDouble(таблицаКодов[i].вниз/таблицаКодов[i].всего,2);
            d2=NormalizeDouble((таблицаКодов[i].всего-таблицаКодов[i].вверх-таблицаКодов[i].вниз)/таблицаКодов[i].всего,2);
         }
         if(таблицаКодов[i].вниз==0)
            d3=1;
         else if(таблицаКодов[i].вверх>таблицаКодов[i].вниз)
            d3=NormalizeDouble(таблицаКодов[i].вверх/таблицаКодов[i].вниз,2);
         else if(таблицаКодов[i].вверх<таблицаКодов[i].вниз){
            if(таблицаКодов[i].вверх==0)
               d3=1;
            else
               d3=NormalizeDouble(таблицаКодов[i].вниз/таблицаКодов[i].вверх,2);
         }
      
         FileWrite(file_handle,Счётчик,таблицаКодов[i].код,таблицаКодов[i].вверх,таблицаКодов[i].вниз,NormalizeDouble(таблицаКодов[i].всего-таблицаКодов[i].вверх-таблицаКодов[i].вниз,0),таблицаКодов[i].всего,d,d1,d2,d3);
      }
   }
   
   //--- закрытие файла 
   FileClose(file_handle); 
   PrintFormat("Данные записаны, файл %s закрыт",InpFileName);
   tt=StringConcatenate("Данные записаны, файл ",InpFileName," закрыт");
   Comment(tt); 
   
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
   
   double ind1 = индBuffer[ПроверяемыйБар-1];
   ind2 = индBuffer[ПроверяемыйБар];
   double ind3 = индBuffer[ПроверяемыйБар+1];
   
   for(int i1=ПроверяемыйБар+3;i1<Bars-2-КолБаров*(КолЭспираций+1) && ind2==ind3;i1++)
      if(ind3 != индBuffer[i1]){
          ind3 = индBuffer[i1];
          break;
      }
   
   if(ПроверяемыйБар>Bars-2-КолБаров*(КолЭспираций+1))
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
   for(int i=0;i<(баровПроверки-1)/2;i++)
      if(High[ПроверяемыйБар] <= High[ПроверяемыйБар-1-i])
          return(false);
      
   for(int i=ПроверяемыйБар+1;i<Bars-баровПроверки+1;i++)
      if(High[ПроверяемыйБар] < High[i])
          return(false);
      else if(High[ПроверяемыйБар] > High[i])
         break;
      else if(i == Bars-баровПроверки)
         return(false);
   
   return(true);   
  }

//+------------------------------------------------------------------+
//| Проверка на минимум                                              |
//+------------------------------------------------------------------+
bool ПроверкаНаMin(int ПроверяемыйБар)
  {
   for(int i=0;i<(баровПроверки-1)/2;i++)
      if(Low[ПроверяемыйБар] >= Low[ПроверяемыйБар-1-i])
          return(false);
      
   for(int i=ПроверяемыйБар+1;i<Bars-баровПроверки+1;i++)
      if(Low[ПроверяемыйБар] > Low[i])
          return(false);
      else if(Low[ПроверяемыйБар] < Low[i])
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
     
   double C1=NormalizeDouble(A1y-A1x*m,8);
   double C2=NormalizeDouble(A2y-A2x*n,8);
   
//---Запись статистики
   if(тип==""){
      статстика[проверяемыйБар].МаксОтносМин= C1>C2 ? "В" : "Н";
      статстика[проверяемыйБар].положЗначИндОтносТЛ=индBuffer[проверяемыйБар]>C1 && индBuffer[проверяемыйБар]>C2 ? "В" : индBuffer[проверяемыйБар]<C1 && индBuffer[проверяемыйБар]<C2 ?"Н" : "М";
      
      статстика[проверяемыйБар].пробойТЛ= 2*m+C1<индBuffer[проверяемыйБар+2] && m+C1>индBuffer[проверяемыйБар+2] ? "В" : 
                                                  2*m+C1<индBuffer[проверяемыйБар+2] && m+C1>индBuffer[проверяемыйБар+2] ? "Н" : "0";
      статстика[проверяемыйБар].направлЛинииИнд= индBuffer[проверяемыйБар+2]<индBuffer[проверяемыйБар+1] ? "В" : индBuffer[проверяемыйБар+2]>индBuffer[проверяемыйБар+1] ? "Н" : "=" ;
   }

   
   if(m!=n){
      double Mx=(C2-C1)/(m-n);   //Координата Х в точке пересеч.  
      
      точкаПересеч=StrToInteger(DoubleToStr(MathFloor(Mx)));
      
      if(тип=="канал")
         типЛинийКанала="О";
      
/*      if(Mx<1)
         точкаПересеч=StrToInteger(DoubleToStr(MathFloor(Mx)));
      else if(тип=="канал") {
*/      
      if(Mx>=1 && тип=="канал") {
         C1=NormalizeDouble(B2y-B2x*m,8);
         C2=NormalizeDouble(B1y-B1x*n,8);
         Mx=(C2-C1)/(m-n);   //Координата Х в точке пересеч.
      
         //if(MathAbs(Mx)>1000) return точкаПересеч;
         if(Mx<1)
            точкаПересеч=StrToInteger(DoubleToStr(MathFloor(Mx)));
         
         типЛинийКанала="Д";
      }
      
//      if(тип=="")
  //       статстика[проверяемыйБар].положТочПересечТЛ=Mx>A1x && Mx>A2x ? "П" : Mx<1 ? "Д" : "М";      
   } else if(тип=="")
     статстика[проверяемыйБар].положТочПересечТЛ="_";

   return точкаПересеч;
  } 

//+------------------------------------------------------------------+
  