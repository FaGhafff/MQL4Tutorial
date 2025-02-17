//+------------------------------------------------------------------+
//|                                                 MQL4Tutorial.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input int checkFrom = 2;
input int checkUntil = 100;
input double scoreVolumeMin =1;
input double scoreVolumeMax =100;
input int priceChunkCount = 10;


//--- structures

struct Price {
   double open;
   double close;
   double high;
   double low;
};

Price add(Price &first,Price &second){
   Price r;
   r.open   = first.open   + second.open;
   r.close  = first.close  + second.close;
   r.high   = first.high   + second.high;
   r.low    = first.low    + second.low;
   return r;
}

Price minues(Price &first,Price &second){
   Price r;
   r.open   = first.open   - second.open;
   r.close  = first.close  - second.close;
   r.high   = first.high   - second.high;
   r.low    = first.low    - second.low;
   return r;
}
Price devide(Price &first,int divition){
   Price r;
   r.open   = first.open   / divition;
   r.close  = first.close  / divition;
   r.high   = first.high   / divition;
   r.low    = first.low    / divition;
   return r;
}
Price multiply(Price &first,int multiplier){
   Price r;
   r.open   = first.open   * multiplier;
   r.close  = first.close  * multiplier;
   r.high   = first.high   * multiplier;
   r.low    = first.low    * multiplier;
   return r;
}

enum PivotType {
   TO_HIGH=1,
   NOTHING=0,
   TO_LOW=-1
};
struct PivotPoint {
   Price price;
   datetime time;
   int TimeFrame;
   PivotType pivotType;
   double volScore;
   double FormerVolScore;

};
PivotPoint initPivotPoint(int index, int timeFrame, double volScore, PivotType type){
PivotPoint pp;
pp.price=initPrice(index);
pp.time = Time[index];
pp.TimeFrame=timeFrame;
pp.volScore = volScore;
return pp;
};
string PivotPointToString(PivotPoint &p){
return "PivotPoint:{"+PriceToString(p.price)+" ,"+TimeToString(p.time)+"}";
}
struct PriceChunk {
   Price from;
   Price until;
   int countPivotPoints;
};
string PriceChunkToString(PriceChunk &priceChunk){
   return "PriceChunk: {"+PriceToString(priceChunk.from)+", "+PriceToString(priceChunk.until)+", count: "+priceChunk.countPivotPoints+"}";
}


PriceChunk initPriceChunk(Price &from, Price &until,int countPivotPint){
PriceChunk r;
r.from = from;
r.until = until;
r.countPivotPoints = countPivotPint;
return r;
}
//--- global variables

Price minPrice;
Price maxPrice;
PivotPoint pivotPointArray[];
int indexPivotTypeArray=0;

PriceChunk priceChunkArray[];
int indexPriceChunkArray=0;



void appendPivotPointToArray(PivotPoint &pivotPoint){
ArrayResize(pivotPointArray,ArraySize(pivotPointArray)+1);
pivotPointArray[indexPivotTypeArray++]=pivotPoint;
}

void appendPriceChunkToArray(PriceChunk &priceChunk){
ArrayResize(priceChunkArray,ArraySize(priceChunkArray)+1);
priceChunkArray[indexPriceChunkArray++]=priceChunk;
}


datetime ArrayTime[], LastTime;
int lastIndex;
int limit =0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Print(__FUNCTION__);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void init() {
   Print(__FUNCTION__);
   //ArrayResize(pivotPointArray,checkUntil-checkFrom);
   //Print("new Array Size: "+IntegerToString(ArraySize(pivotPointArray)));
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Price initPrice(int index) {
   Price p;
   p.close=Close[index];
   p.open = Open[index];
   p.high = High[index];
   p.low = Low[index];
   return p;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PriceToString(Price &price) {
   return "Price:{Open:"+DoubleToString(price.open)+" ,High:"+DoubleToString(price.high)+" ,Low:"+DoubleToString(price.low)+" ,Close:"+DoubleToString(price.close)+"}";
}

Price getSpreadPrice(Price &minPrice, Price &maxPrice, int count,int indexfromCount){
Price diff = minues(maxPrice,minPrice);

Price part = devide(diff,count);

return add(minPrice,multiply(part,(indexfromCount)));

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   VLineCreate(0,StringConcatenate("Vline ","Start from :"+IntegerToString(checkFrom)),0,Time[checkFrom],clrWhite);
   VLineCreate(0,StringConcatenate("Vline ","until: "+ IntegerToString(checkUntil)),0,Time[checkUntil],clrWhite);
   // if(NewBar(_Period)) {


   maxPrice = initPrice(iHighest(IntegerToString(0),NULL,MODE_HIGH,checkUntil-checkFrom+1,checkFrom));
   minPrice = initPrice(iLowest(IntegerToString(0),NULL,MODE_LOW,checkUntil-checkFrom+1,checkFrom));
   

   int indexHighestVolume = getHighestLowestVolumeIndex(checkFrom,checkUntil,1);
   int indexLowestVolume  = getHighestLowestVolumeIndex(checkFrom,checkUntil,0);

   //VLineCreate(0,StringConcatenate("Vline ","until: "+ IntegerToString(indexHighestVolume)),0,Time[indexHighestVolume],clrRed);
   //VLineCreate(0,StringConcatenate("Vline ","until: "+ IntegerToString(indexLowestVolume)),0,Time[indexLowestVolume],clrBlue);

   // getVolumeInsideRange(indexHighestVolume,indexLowestVolume,2,1,10);

   for(int i=checkFrom; i<checkUntil-1; i++) {
      // check is it a pivot with type top or bottom
      //Print("price for candle index : "+IntegerToString(i)+" is "+DoubleToStr(getVolumeScore(i,indexLowestVolume,indexHighestVolume)));

      int type = getPivotPointType(i);
      if(type ==TO_HIGH) {
         appendPivotPointToArray(initPivotPoint(i,_Period,getVolumeScore(i,indexLowestVolume,indexHighestVolume),TO_HIGH));
         //VLineCreate(0,StringConcatenate("Vline ",IntegerToString(i)),0,Time[i],clrRed);
         ObjectCreate(IntegerToString(i), OBJ_TEXT, 0, Time[i],High[i]+2);
         ObjectSetDouble(0,IntegerToString(i),OBJPROP_ANGLE,90);
         ObjectSetText(IntegerToString(i),"i:"+IntegerToString(i)+" "+ DoubleToStr(getVolumeScore(i,indexLowestVolume,indexHighestVolume),2), 11, "Arial", clrRed);
      } else if(type ==-1) {
         //VLineCreate(0,StringConcatenate("Vline ",IntegerToString(i)),0,Time[i],clrBlue);
         appendPivotPointToArray(initPivotPoint(i,_Period,getVolumeScore(i,indexLowestVolume,indexHighestVolume),TO_LOW));
         ObjectCreate(IntegerToString(i), OBJ_TEXT, 0, Time[i],Low[i]-2);
         ObjectSetDouble(0,IntegerToString(i),OBJPROP_ANGLE,90);
         ObjectSetText(IntegerToString(i),"i:"+IntegerToString(i)+" "+ DoubleToStr(getVolumeScore(i,indexLowestVolume,indexHighestVolume),2), 11, "Arial", clrGreenYellow);
      }

   }
   // seperate chunks and initilize them
   
   for(int i=0;i<priceChunkCount;i++)
     {
      appendPriceChunkToArray(initPriceChunk(getSpreadPrice(minPrice,maxPrice,priceChunkCount,i),getSpreadPrice(minPrice,maxPrice,priceChunkCount,i+1),0));
     } 
   
   //check pivot points and place in currect position inside chunks
   
   
   Print("Price Chuank Array size : "+IntegerToString(ArraySize(priceChunkArray)));
for(int i=0;i<ArraySize(priceChunkArray);i++)
  {
   Print(PriceChunkToString(priceChunkArray[i]));
  }


   // }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BankersRound(double value, int precision) {
   value = value * MathPow(10, precision);
   if (MathCeil(value) - value == 0.5 && value - MathFloor(value) == 0.5) {   // also could use: MathCeil(value) - value == value - MathFloor(value)
      if (MathMod(MathCeil(value), 2) == 0) {
         return (MathCeil(value) / MathPow(10, precision));
      } else {
         return (MathFloor(value) / MathPow(10, precision));
      }
   }
   return (MathRound(value) / MathPow(10, precision));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getVolumeScore(int index, int indexMin, int indexMax) {
   long volMin = Volume[indexMin];
   long volMax = Volume[indexMax];
   long vol = Volume[index];
   double RatioVol = (double)(vol - volMin)/(volMax-volMin);
   RatioVol *= (scoreVolumeMax-scoreVolumeMin);
   RatioVol += scoreVolumeMin;

   return RatioVol;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getHighestLowestVolumeIndex(int from, int until,int MODE) {
   long vol = Volume[from];
   int index=from;
   for(int i=from; i<=until; i++) {
      if(MODE == 1 && Volume[i]>=vol) {
         vol = Volume[i];
         index = i;
      } else if(MODE == 0 && Volume[i]<=vol) {
         vol = Volume[i];
         index = i;
      }
   }
   return index;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//double getVolumeInsideRange(int indexHigh, int indexLow, int indexCurrent, double rangeMin, double rangeMax) {
//   double volumeCurrent = Volume[indexCurrent];
//   double volumeHigh = Volume[indexHigh];
//   double volumeLowest = Volume[indexLow];
//   double volInRange = NormalizeDouble(rangeMin,4) + NormalizeDouble(((rangeMax - rangeMin)*(volumeCurrent - volumeLowest))/(volumeHigh-volumeLowest),4);
//
//   return volInRange;
//}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PivotType getPivotPointType(int indexOfCandle) {
   double open = Open[indexOfCandle];
   double close = Close[indexOfCandle];
   double openNext = Open[indexOfCandle-1];
   double closeNext = Close[indexOfCandle-1];
   double openPast = Open[indexOfCandle+1];
   double closePast = Close[indexOfCandle+1];

   if(closeNext<close && closePast<close) {
      return TO_HIGH;
   } else if(close<closeNext && close<closePast) {
      return TO_LOW;
   } else {
      return NOTHING;
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NewBar(int period) {
   bool firstRun = false, newBar = false;

   ArraySetAsSeries(ArrayTime,true);
   CopyTime(Symbol(),period,0,2,ArrayTime);

   if(LastTime == 0)
      firstRun = true;
   if(ArrayTime[0] > LastTime) {
      if(firstRun == false)
         newBar = true;
      LastTime = ArrayTime[0];
   }
   return newBar;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool VLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="VLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 datetime              time=0,            // line time
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0) {       // priority for mouse click
//--- if the line time is not set, draw it via the last bar
   if(!time)
      time=TimeCurrent();
//--- reset the error value
   ResetLastError();
   ResetLastError();
//--- create a vertical line
   if(!ObjectCreate(chart_ID,name,OBJ_VLINE,sub_window,time,0)) {
      Print(__FUNCTION__,
            ": failed to create a vertical line! Error code = ",GetLastError());
      return(false);
   }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
//| Move the vertical line                                           |
//+------------------------------------------------------------------+
bool VLineMove(const long   chart_ID=0,   // chart's ID
               const string name="VLine", // line name
               datetime     time=0) {     // line time
//--- if line time is not set, move the line to the last bar
   if(!time)
      time=TimeCurrent();
//--- reset the error value
   ResetLastError();
//--- move the vertical line
   if(!ObjectMove(chart_ID,name,0,time,0)) {
      Print(__FUNCTION__,
            ": failed to move the vertical line! Error code = ",GetLastError());
      return(false);
   }
//--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
//| Delete the vertical line                                         |
//+------------------------------------------------------------------+
bool VLineDelete(const long   chart_ID=0,   // chart's ID
                 const string name="VLine") { // line name
//--- reset the error value
   ResetLastError();
//--- delete the vertical line
   if(!ObjectDelete(chart_ID,name)) {
      Print(__FUNCTION__,
            ": failed to delete the vertical line! Error code = ",GetLastError());
      return(false);
   }
//--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
//| Create the horizontal line                                       |
//+------------------------------------------------------------------+
bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 const int             sub_window=0,      // subwindow index
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0) {       // priority for mouse click
//--- if the price is not set, set it at the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- create a horizontal line
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price)) {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
   }
//--- set line color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse
//--- when creating a graphical object using ObjectCreate function, the object cannot be
//--- highlighted and moved by default. Inside this method, selection parameter
//--- is true by default making it possible to highlight and move the object
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
//| Move horizontal line                                             |
//+------------------------------------------------------------------+
bool HLineMove(const long   chart_ID=0,   // chart's ID
               const string name="HLine", // line name
               double       price=0) {    // line price
//--- if the line price is not set, move it to the current Bid price level
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value
   ResetLastError();
//--- move a horizontal line
   if(!ObjectMove(chart_ID,name,0,0,price)) {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return(false);
   }
//--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
//| Delete a horizontal line                                         |
//+------------------------------------------------------------------+
bool HLineDelete(const long   chart_ID=0,   // chart's ID
                 const string name="HLine") { // line name
//--- reset the error value
   ResetLastError();
//--- delete a horizontal line
   if(!ObjectDelete(chart_ID,name)) {
      Print(__FUNCTION__,
            ": failed to delete a horizontal line! Error code = ",GetLastError());
      return(false);
   }
//--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
