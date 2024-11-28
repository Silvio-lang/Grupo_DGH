//+------------------------------------------------------------------+
//|                                          Indicador Tres BDRs.mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//#property indicator_separate_window
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3
//--- plot Vermelha
#property indicator_label1  "LinhaAzul"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "LinhaVermelha"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_label3  "LinhaAmarela"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrYellow
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

#include <LineLabelButton.mqh>

//--- indicator buffers
input string ATIVO1="IVVB11";//Primeiro Ativo (azul):
input string ATIVO2="M1TA34";//Segundo Ativo  (verm):
input string ATIVO3="MELI34";//Terceiro Ativo (amarela):
input double VALORPADRAO=10000;
input double OFS1=0;//Offset1 azul:
input double OFS2=0;//Offset2 verm:
input double OFS3=-20000;//Offset3 amarelo:
input double TETO=12000;
input double BASE=8000;
input bool  COMENTA=false;

input int    T=600;//Tempo entre alertas (Segundos):
input int    N=0;//Referencia quantos dias atrás (máx.9):


int i,n,k1,k2,k3,cor1,cor2,cor3,rates,pos_medida,pos=10,ref_tempo,m;
color corlinha,cordelta;
bool up_fast,dw_fast,pressionado,horario_ok;
string agora,agora_ant,str_lote1;
datetime ultima_hora,hr_[500],tempo[10000],dia[100],t_ant;
double ativo1[],ativo2[],ativo3[],L,
       Linha1Buffer[],Linha2Buffer[],Linha3Buffer[],Linha4Buffer[],BufferDelta[],fechD1[11],fechD2[11],fechD3[11],fechD4[11],
       ult_neg1,ult_neg2,ult_neg2_ant,ult_neg3,ult_neg3_ant,ult_neg4,ult_neg4_ant,delta12,delta13,delta23,
       media1_[1],media2_[1],valor_indic2,valor_indic2_ant,valor_indic3,valor_indic3_ant,valor_indic4,valor_indic4_ant,posicao_at1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,Linha1Buffer,INDICATOR_DATA); //Ativo1 - Azul
   SetIndexBuffer(1,Linha2Buffer,INDICATOR_DATA); //Ativo2 - Verm
   SetIndexBuffer(2,Linha3Buffer,INDICATOR_DATA); //Ativo3 - Amarelo
   
   IndicatorSetString(INDICATOR_SHORTNAME,"Indicador 3 Ativos");
   ult_neg1=SymbolInfoDouble(ATIVO1,SYMBOL_LAST);
   ChartSetInteger(0,CHART_MODE,CHART_LINE);
   
   ChartSetInteger(0,CHART_SCALEFIX,true);
   ChartSetDouble(0,CHART_FIXED_MAX,VALORPADRAO*1.2);
   ChartSetDouble(0,CHART_FIXED_MIN,VALORPADRAO*0.8);
   
   ult_neg1=SymbolInfoDouble(ATIVO1,SYMBOL_LAST);
   ult_neg2=SymbolInfoDouble(ATIVO2,SYMBOL_LAST);
   ult_neg3=SymbolInfoDouble(ATIVO3,SYMBOL_LAST);
   
   k1=int(round(VALORPADRAO/ult_neg1));
   k2=int(round(VALORPADRAO/ult_neg2));
   k3=int(round(VALORPADRAO/ult_neg3));
   
   corlinha=color(ChartGetInteger(0,CHART_COLOR_CHART_LINE));
   TextCreate(0,"name1",0,TimeCurrent()+3600,0," "+ATIVO1,"Arial",6,corlinha); ObjectSetInteger(0,"name1",OBJPROP_ANCHOR,ANCHOR_LEFT);
   TextCreate(0,"name2",0,TimeCurrent()+3600,0,"         "+ATIVO2,"Arial",6,C'0,0,150'); ObjectSetInteger(0,"name2",OBJPROP_ANCHOR,ANCHOR_LEFT);
   TextCreate(0,"name3",0,TimeCurrent()+3600,0,"                 "+ATIVO3,"Arial",6,C'150,0,0'); ObjectSetInteger(0,"name3",OBJPROP_ANCHOR,ANCHOR_LEFT);
   TextCreate(0,"delta12",0,TimeCurrent()+0000,0,"         "+DoubleToString(100*delta12,2)+"%","Arial",12,C'90,90,250',0,ANCHOR_LEFT); 
   TextCreate(0,"delta13",0,TimeCurrent()+0000,0,"         "+DoubleToString(100*delta13,2)+"%","Arial",12,C'90,90,250',0,ANCHOR_LEFT); 
//   LabelCreate(0,"lote2",0,20,0,CORNER_LEFT_LOWER,"TESTE","Arial",12,C'200,200,0',0,ANCHOR_LEFT_LOWER); 
   
   ObjectSetInteger(0,"medida",OBJPROP_COLOR,clrViolet);
   ObjectSetInteger(0,"medida",OBJPROP_WIDTH,2);
   ObjectSetInteger(0,"medida",OBJPROP_SELECTABLE,true); 
   ObjectSetInteger(0,"medida",OBJPROP_SELECTED,true);
   
   ref_tempo=int(TimeLocal()+60);
    
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0); 
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0); 
 
   EventSetMillisecondTimer(200);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
   ArrayFree(ativo2);
   ChartSetInteger(0,CHART_MODE,CHART_CANDLES);

   ObjectDelete(0,"name1");
   ObjectDelete(0,"name2");
   ObjectDelete(0,"name2");
   ObjectDelete(0,"delta");
   ObjectDelete(0,"marco");
   ObjectDelete(0,"reais");
   ObjectDelete(0,"lucroRS");
   ObjectDelete(0,"textoativo2");
//   ChartSetSymbolPeriod(0,ATIVO1,PERIOD_CURRENT); 
   
  }//+---------------------------------------------------------------+
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
   
//----------------------------------------------------------------------------
//                     PREV CALCULATED
//----------------------------------------------------------------------------
if(prev_calculated==0)//  || agora<agora_ant
   {
   ArrayResize(ativo2,500);
   ArrayResize(ativo3,500);
   CopyClose(ATIVO1,PERIOD_CURRENT,0,500,ativo1);
   CopyClose(ATIVO2,PERIOD_CURRENT,0,500,ativo2);
   CopyClose(ATIVO3,PERIOD_CURRENT,0,500,ativo3);
   
   CopyClose(ATIVO1,PERIOD_D1,0,11,fechD1);
   CopyClose(ATIVO2,PERIOD_D1,0,11,fechD2);
   CopyClose(ATIVO3,PERIOD_D1,0,11,fechD3);
   

//   for(int x=10-N; x<11; x++)
//     {soma1=soma1+fechD1[x]; soma2=soma2+fechD2[x];}
//   relacaobase = soma1/soma2;
   
   CopyTime(_Symbol,PERIOD_D1,0,100,dia);
   ObjectSetInteger(0,"marco",OBJPROP_TIME,dia[98]);
   
   
//   Comenta(rates_total);
   
   int j=rates_total-500;
    for (i=j; i<rates_total-1; i++)
      {
          // converte para a escala da Horizontal + (fechD[0]-ativo2[i-j-1])+RECUO; 
       Linha1Buffer[fmax(0,i)]=ativo1[fmax(0,fmin(rates_total-1,i-j))]*k1+OFS1;
       Linha2Buffer[fmax(0,i)]=ativo2[fmax(0,fmin(rates_total-1,i-j))]*k2+OFS2;
       Linha3Buffer[fmax(0,i)]=ativo3[fmax(0,fmin(rates_total-1,i-j))]*k3+OFS3;



      }        
       ultima_hora=time[rates_total-2];
       
     cor1=clrBlue;
     cor2=clrRed; 
     cor3=clrYellow;
     HLineCreate(0,"compra ativo2",0,PositionGetDouble(POSITION_PRICE_OPEN)*k2,clrLightBlue,STYLE_DOT);
       
       rates=rates_total;
   }
// até aqui prev_calculated==0


//==========================================================================================
//    valores atualizados a cada tick
//==========================================================================================   
   
   i=rates_total-1;

     CopyClose(ATIVO1,PERIOD_D1,0,11,fechD1);
     CopyClose(ATIVO2,PERIOD_D1,0,11,fechD2);
     CopyClose(ATIVO3,PERIOD_D1,0,11,fechD3);
     CopyTime(_Symbol,PERIOD_D1,0,11,dia);

     PositionSelect(_Symbol); posicao_at1=PositionGetDouble(POSITION_VOLUME);
     

     if(fechD1[10]>0)  ult_neg1=fechD1[10];
     if(fechD2[10]>0)  ult_neg2=fechD2[10];
     if(fechD3[10]>0)  ult_neg3=fechD3[10];

     ObjectSetInteger(0,"marco",OBJPROP_TIME,dia[10]);
     
     Linha1Buffer[i]=ult_neg1*k1+OFS1;//
     Linha2Buffer[i]=ult_neg2*k2+OFS2;//
     Linha3Buffer[i]=ult_neg3*k3+OFS3;//
     
     agora_ant=agora; agora=TimeToString(time[i],TIME_DATE);

     cor1=clrBlue;
     cor2=clrRed; 
     cor3=clrYellow;
     HLineCreate(0,"compra ativo2",0,PositionGetDouble(POSITION_PRICE_OPEN)*k2+OFS2,clrLightBlue,STYLE_DOT);
     ObjectSetInteger(0,"name1",OBJPROP_COLOR,cor1);
     ObjectSetInteger(0,"name2",OBJPROP_COLOR,cor2);
     ObjectSetInteger(0,"name3",OBJPROP_COLOR,cor3);
     
     ultima_hora=time[i];
     delta12=(Linha1Buffer[i]-Linha2Buffer[i]);
     delta13=(Linha1Buffer[i]-Linha3Buffer[i]);
     
   valor_indic2_ant=valor_indic2;
   valor_indic2=Linha2Buffer[i]; if(valor_indic2==0) valor_indic2=valor_indic2_ant;
   
   valor_indic3_ant=valor_indic3;
   valor_indic3=Linha3Buffer[i]; if(valor_indic3==0) valor_indic3=valor_indic3_ant;

   cordelta=clrLime; 
     ObjectSetInteger(0,"delta",OBJPROP_COLOR,cordelta);

   ObjectSetInteger(0,"delta2",OBJPROP_TIME,ultima_hora); 
   ObjectSetInteger(0,"delta3",OBJPROP_TIME,ultima_hora); 
   ObjectSetDouble(0,"delta2",OBJPROP_PRICE,(valor_indic2+ult_neg1)/2);
   ObjectSetDouble(0,"delta3",OBJPROP_PRICE,(valor_indic3+ult_neg1)/2);
   ObjectSetString(0,"delta2",OBJPROP_TEXT,"                         "+DoubleToString(delta12,2)+"%");
   ObjectSetString(0,"delta3",OBJPROP_TEXT,"                         "+DoubleToString(delta13,2)+"%");

   
   if(COMENTA) 
     Comenta(rates_total);
   
   return(rates_total);
   
  }

void OnTimer()  // BOTOES
  {


   agora_ant=agora;
   agora=TimeToString(TimeCurrent(),TIME_MINUTES);

   
   delta12=(Linha1Buffer[i]-Linha2Buffer[i]);
   delta13=(Linha1Buffer[i]-Linha3Buffer[i]);
   delta23=delta13-delta12;
   
   ObjectSetInteger(0,"delta",OBJPROP_TIME,ultima_hora);
   ObjectSetInteger(0,"name1",OBJPROP_TIME,ultima_hora);
   ObjectSetInteger(0,"name2",OBJPROP_TIME,ultima_hora);
   ObjectSetInteger(0,"name3",OBJPROP_TIME,ultima_hora);
   ObjectSetInteger(0,"delta12",OBJPROP_TIME,ultima_hora);
   ObjectSetInteger(0,"delta13",OBJPROP_TIME,ultima_hora);
   ObjectSetDouble(0,"delta12",OBJPROP_PRICE,(valor_indic2+ult_neg1)/2);
   ObjectSetDouble(0,"delta13",OBJPROP_PRICE,(valor_indic3+ult_neg1)/2);
   ObjectSetString(0,"delta12",OBJPROP_TEXT,"                         "+DoubleToString(delta12,2)+"%");
   ObjectSetString(0,"delta13",OBJPROP_TEXT,"                         "+DoubleToString(delta13,2)+"%");
   ObjectSetString(0,"name1",OBJPROP_TOOLTIP,DoubleToString(Linha1Buffer[i],2)+" : "+DoubleToString(Linha2Buffer[i],2)+" )");
   ObjectSetDouble(0,"name1",OBJPROP_PRICE,Linha1Buffer[i]);
   ObjectSetString(0,"name1",OBJPROP_TEXT,"      "+ATIVO1+" ( "+DoubleToString(ult_neg1,2)+" : "+DoubleToString(Linha1Buffer[i],2)+" )");
   ObjectSetDouble(0,"name2",OBJPROP_PRICE,Linha2Buffer[i]);
   ObjectSetString(0,"name2",OBJPROP_TEXT,"      "+ATIVO2+" ( "+DoubleToString(ult_neg2,2)+" : "+DoubleToString(Linha2Buffer[i],2)+" )");
   ObjectSetDouble(0,"name3",OBJPROP_PRICE,Linha3Buffer[i]);
   ObjectSetString(0,"name3",OBJPROP_TEXT,"      "+ATIVO3+" ( "+DoubleToString(ult_neg3,2)+" : "+DoubleToString(Linha3Buffer[i],2)+" )");
   
   
   horario_ok=(agora>"09:00" && agora<"18:00");
   
   
     
   if(COMENTA)
   Comenta(i);
   return;
  }
  
void Comenta(int rates_)
  {
     Comment("\n",TimeLocal(),
             "\n TIMER: ",fmax(0,ref_tempo-int(TimeLocal())),"\n",
           "\n ",
           "\n Ativo1: ",ATIVO1,"(Az)",
           "\n Ativo2: ",ATIVO2,"(Vm)",
           "\n Ativo3: ",ATIVO3,"(Am)",
           "\n",
             "\n ","Delta12: ",DoubleToString(delta12,2),
             "\n ","Delta13: ",DoubleToString(delta13,2),
             "\n ","Delta23: ",DoubleToString(delta23,2),
//             "\n DeltaLocal: ",DoubleToString(DeltaLocal())," ",DoubleToString(L)," media1: "," m: ",m,
             "\n\n Relação12 atual:",DoubleToString(fechD1[10]/fechD2[10],5),
             "\n RelacaoBase12: ",DoubleToString(k2,5),  //DoubleToString(media1[0],2),
             "\n\n Relação13 atual:",DoubleToString(fechD1[10]/fechD3[10],5),
             "\n RelacaoBase13: ",DoubleToString(k3,5),  //DoubleToString(media1[0],2),

             "\n\n Relação23 atual:",DoubleToString(fechD2[10]/fechD3[10],5),

//             "\n\n ARQSOM1: ",StringSubstr(ARQSOM12,0,14),
//             "\n ARQSOM2: ",StringSubstr(ARQSOM13,0,14),
//             "\n ARQSOM3: ",StringSubstr(ARQSOM23,0,14),
//             "\n HORA_OK: ",horario_ok,
            "");
  }
//+------------------------------------------------------------------+

  
double DeltaLocal()
  {double at1[1],at2[1],deltalocal;
   datetime t=datetime(ObjectGetInteger(0,"medida",OBJPROP_TIME));
   m=PosicaoVline(t);
   CopyClose(_Symbol,PERIOD_CURRENT,t,1,at1);
   at2[0]=Linha2Buffer[m]; L=at2[0];
   deltalocal=at2[0]/at1[0]-1;
   return(deltalocal);
  }


int PosicaoVline(datetime t)
  {
   if(t_ant<t) {do {pos++; t_ant=tempo[pos];} while (t_ant<t); if(t_ant>=t) return(pos);} //if(pos>9950) Print(rates," ",tempo[pos]);
   if(t_ant>t) {do {pos--; t_ant=tempo[pos];} while (t_ant>t); if(t_ant>=t) return(pos);}
   return(0);
  }
