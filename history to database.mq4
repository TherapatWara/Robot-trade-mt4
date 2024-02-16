// กำหนดค่า EMA
input int emaPeriod1 = 50;
input int emaPeriod2 = 200;

// กำหนดค่าการเปิด Order
input double lotSize = 0.1; // ขนาด lot
input double takeProfitAmount = 3.0; // กำไรเป้าหมาย (USD)
input double stopLossPercent = 10.0; // Stop Loss (%)

// ตัวแปรสำหรับเก็บค่า EMA
double emaCurrent1, emaPrevious1;
double emaCurrent2, emaPrevious2;

double profit = OrderProfit();
double sum = 0;
double loss =0;
double accountEquity = AccountEquity(); // เพิ่มบรรทัดนี้เพื่อดึงข้อมูล equity ปัจจุบัน

double tob = 0;

int keepbuy =0;

// ฟังก์ชั่น OnInit ทำงานครั้งเดียวทันทีที่ Expert Advisor ถูกเรียกใช้
int OnInit()
{
    // คำนวณ EMA ในระหว่าง Initializtion
    emaCurrent1 = iMA(NULL, 0, emaPeriod1, 0, MODE_EMA, PRICE_CLOSE, 0);
    emaPrevious1 = iMA(NULL, 0, emaPeriod1, 0, MODE_EMA, PRICE_CLOSE, 1);

    emaCurrent2 = iMA(NULL, 0, emaPeriod2, 0, MODE_EMA, PRICE_CLOSE, 0);
    emaPrevious2 = iMA(NULL, 0, emaPeriod2, 0, MODE_EMA, PRICE_CLOSE, 1);

    return(INIT_SUCCEEDED);
}

// ฟังก์ชั่น OnTick ทำงานทุกครั้งที่มีการเปลี่ยนแปลงราคา
void OnTick()
{
    // คำนวณ EMA ในทุก Tick
    emaCurrent1 = iMA(NULL, 0, emaPeriod1, 0, MODE_EMA, PRICE_CLOSE, 0);
    emaPrevious1 = iMA(NULL, 0, emaPeriod1, 0, MODE_EMA, PRICE_CLOSE, 1);

    emaCurrent2 = iMA(NULL, 0, emaPeriod2, 0, MODE_EMA, PRICE_CLOSE, 0);
    emaPrevious2 = iMA(NULL, 0, emaPeriod2, 0, MODE_EMA, PRICE_CLOSE, 1);

    // เปิด Order ตามเงื่อนไข
    if (emaCurrent1 > emaCurrent2 && emaPrevious1 <= emaPrevious2 && keepbuy <= 1)
    {
        // เปิด Order Buy

            Print("keepbuy : ", keepbuy);
            OrderSend(Symbol(), OP_BUY, lotSize+tob, Ask, 3, 0, 0, "Buy Order", 0, 0, Green);
            keepbuy = keepbuy + 1;
        

    }
    else if (emaCurrent1 < emaCurrent2 && emaPrevious1 >= emaPrevious2 && keepbuy <= 1)
    {
     // เปิด Order Sell
        
            Print("keepbuy : ", keepbuy);
            OrderSend(Symbol(), OP_SELL, lotSize+tob, Bid, 3, 0, 0, "Sell Order", 0, 0, Red);
            keepbuy = keepbuy + 1;
        
    }

    // ตรวจสอบทุกรายการ Order ที่เปิด

   for (int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if (OrderSymbol() == _Symbol && OrderCloseTime() == 0)
         {
            double profit = OrderProfit();
            if (profit >= 2.0)
            {
               
               bool result = OrderClose(OrderTicket(), OrderLots(), Bid, 3, Red);
               result = OrderClose(OrderTicket(), OrderLots(), Ask, 3, Red);
               keepbuy = 0;
               
               sendclose();
               if (result)
               {
                  Print("Order closed with profit +2. Ticket: ", OrderTicket());
                  sum = sum + profit;
                  Print("SUM Profit: ", sum);
               }
               else
               {
                  Print("Failed to close Order. Error: ", GetLastError());
               }
            }
            if(profit < -13.0)
            {
               //tob = tob + 1;
               result = OrderClose(OrderTicket(), OrderLots(), Bid, 3, Red);
               result = OrderClose(OrderTicket(), OrderLots(), Ask, 3, Red);
               keepbuy = 0;
               if (result)
               {
                  Print("Order closed with profit -10. Ticket: ", OrderTicket());
                  loss = loss + profit;
                  Print("loss Profit: ", loss);
               }
               else
               {
                  Print("Failed to close Order. Error: ", GetLastError());
               }
            }
         }
      }
         
  }
}

void sendclose(){
    closee();
}


int lastorderstotal;
void closee()
{  
         string sender = "";
         double com = OrderProfit()*0.1;
         // สร้างข้อมูลเพื่อส่งไปยังเว็บไซต์ ตามต้องการ
         sender += StringFormat("%s,%d,%.2f,%.2f,%d|", OrderSymbol(), OrderTicket(), OrderProfit(), com, 0);
         Print(sender);
                    
                
            
        
        // ส่งข้อมูลไปยังเว็บไซต์
        Print(httpGET("http://localhost/mt4/insert.php?order=" + sender));

        // อัปเดตค่า lastorderstotal เพื่อให้เป็นค่าปัจจุบัน
        lastorderstotal = OrdersTotal();
    
  
  }



//+------------------------------------------------------------------+
#import "wininet.dll"
int InternetOpenW(string sAgent,int lAccessType,string sProxyName="",string sProxyBypass="",int lFlags=0);
int InternetOpenUrlW(int hInternetSession,string sUrl,string sHeaders="",int lHeadersLength=0,int lFlags=0,int lContext=0);
int InternetReadFile(int hFile,uchar &sBuffer[],int lNumBytesToRead,int &lNumberOfBytesRead);
int InternetCloseHandle(int hInet);
#import
int hSession_IEType;
int hSession_Direct;
int Internet_Open_Type_Preconfig=0;
int Internet_Open_Type_Direct=1;

int hSession(bool Direct){
   string InternetAgent="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; Q312461)";
   if(Direct){
      if(hSession_Direct==0){
         hSession_Direct=InternetOpenW(InternetAgent,Internet_Open_Type_Direct,"0","0",0);
      }
   return(hSession_Direct);
   } else {
   if(hSession_IEType==0){
      hSession_IEType=InternetOpenW(InternetAgent,Internet_Open_Type_Preconfig,"0","0",0);
   }
   return(hSession_IEType);
   }
}
string httpGET(string strUrl){
   int handler=hSession(false);
   int response= InternetOpenUrlW(handler,strUrl);
   if(response == 0)return("0");
   uchar ch[100000]; string toStr=""; int dwBytes,h=-1;
   while(InternetReadFile(response,ch,100000,dwBytes)){
      if(dwBytes<=0) break; toStr=toStr+CharArrayToString(ch,0,dwBytes);
   }
   InternetCloseHandle(response);
   return(toStr);
}