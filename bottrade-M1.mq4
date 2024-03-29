

// กำหนดค่า EMA
input int emaPeriod1 = 50;
input int emaPeriod2 = 200;

// กำหนดค่าการเปิด Order
input double lotSize = 0.01; // ขนาด lot
input double takeProfitAmount = 3.0; // กำไรเป้าหมาย (USD)
input double stopLossPercent = 10.0; // Stop Loss (%)

// ตัวแปรสำหรับเก็บค่า EMA
double emaCurrent1, emaPrevious1;
double emaCurrent2, emaPrevious2;

double profit = OrderProfit();
double sum = 0;
double loss =0;
double accountEquity = AccountEquity(); // เพิ่มบรรทัดนี้เพื่อดึงข้อมูล equity ปัจจุบัน
double prekeep = 0;

int keepbuy = 0;


#include <Zmq/Zmq.mqh>

// Global Variables
int ZMQ_SOCKET_TIMEOUT = 1000; // Timeout for socket operations in milliseconds

double Predict()
{
    // Create a context for ZeroMQ
    Context context("price_volume_time_publisher");
    double receivedDouble;
    // Create a PUB socket
    Socket socket(context, ZMQ_REQ);

    // Connect the socket to Python server
    if (!socket.connect("tcp://localhost:5555")) {
        Print("Failed to connect to Python server. Error code: ", zmq_errno());
        return "fail to connect";
    }
    /*
    string priceVolumeTimeData = """,";
    // Prepare price, volume, and time data
    for (int i = 0; i < 3; i++) {
        // Get price data for the i-th bar
        double close = iClose("EURUSDz", PERIOD_D1, i);

        // Format the price, volume, and time data and add it to the string
        if(i != 2)
        {
            string barData = StringFormat("%.5f,", close);
            priceVolumeTimeData += barData;
        }
        else if(i==2)
        {
            string barData = StringFormat("%.5f", close);
            priceVolumeTimeData += barData;
        }
        

    }
    */
    string priceVolumeTimeData;
    for (int i = 0; i < 3; i++) {
        double close = iClose("EURUSDz", PERIOD_H4, i);
        string barData = StringFormat("data|%.5f\n", close);
        priceVolumeTimeData += barData;
    }
    string priceVolumeTimeData1 = priceVolumeTimeData;

    // Publish price, volume, and time data
    ZmqMsg message(priceVolumeTimeData1);
    if (!socket.send(message)) {
        Print("Failed to send price, volume, and time data to Python. Error code: ", zmq_errno());
        return "fail to send price";
    }

    Print("Price, volume, and time data sent to Python successfully.");
    // รอรับข้อความตอบกลับจาก Server
    
    ZmqMsg reply;
    if (!socket.recv(reply)) {
        Print("Failed to receive reply from ZeroMQ Server. Error code: ", zmq_errno());
        return "fail to receive reply from zeromq";
    }

    // ตรวจสอบว่าได้รับข้อความตอบกลับจาก Server หรือไม่
    string receivedMessage = reply.getData();
    Print("Received reply from ZeroMQ Server: ", receivedMessage);
    receivedDouble = StringToDouble(receivedMessage);
    //Print("Predict: ", receivedDouble);
    return receivedDouble;
}


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
int st = 0;
int cc = 0;
double keep=0;
double pre = 0;
void OnTick()
{
    if(st != 1)
    {
      pre = Predict();
      Print(pre);
      st = 1;
    }

   
    // คำนวณ EMA ในทุก Tick
    emaCurrent1 = iMA(NULL, 0, emaPeriod1, 0, MODE_EMA, PRICE_CLOSE, 0);
    emaPrevious1 = iMA(NULL, 0, emaPeriod1, 0, MODE_EMA, PRICE_CLOSE, 1);

    emaCurrent2 = iMA(NULL, 0, emaPeriod2, 0, MODE_EMA, PRICE_CLOSE, 0);
    emaPrevious2 = iMA(NULL, 0, emaPeriod2, 0, MODE_EMA, PRICE_CLOSE, 1);
    
    // เปิด Order ตามเงื่อนไข
    if (emaCurrent1 > emaCurrent2 && emaPrevious1 <= emaPrevious2 )//&& keepbuy <= 1)
    {
         Print("hell");

        // เปิด Order Buy
        //Print(keep);
        double bid = MarketInfo(_Symbol,MODE_BID);
        
        if(bid <= pre)
        {   //Print(keep + " ,bidBUY:" + bid);
            OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, 0, 0, "Buy Order", 0, 0, Green);
            keepbuy = keepbuy + 1;      
        }



    }
    else if (emaCurrent1 < emaCurrent2 && emaPrevious1 >= emaPrevious2 )//&& keepbuy <= 1)
    {
     // เปิด Order Sel
        //Print(keep);
            double bid = MarketInfo(_Symbol,MODE_BID);
            
            if(bid > pre)
            {  //Print(keep + " ,bidSELL:" + bid);
               OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, 0, 0, "Sell Order", 0, 0, Red);
               keepbuy = keepbuy + 1;   
            }


    }

    // ตรวจสอบทุกรายการ Order ที่เปิด

int maxRetries = 3;
for (int i = OrdersTotal() - 1; i >= 0; i--)
{
    if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
    {
        if (OrderSymbol() == _Symbol && OrderCloseTime() == 0)
        {
            double profit = OrderProfit();
            int ticket = OrderTicket(); // Get the ticket number
            
            if (profit >= 13)
            {
                bool result = false;
                int attempts = 0;
                while (!result && attempts < maxRetries)
                {
                    result = OrderClose(ticket, OrderLots(), Bid, 3, Red);st=0;keepbuy=0;
                    if (result)
                    {
                        Print("Order closed with profit +2. Ticket: ", ticket);
                        sum = sum + profit;
                        Print("SUM Profit: ", sum);
                    }
                    else
                    {
                        int error = GetLastError();
                        if (error == 138) {
                            // Retry order closure
                            attempts++;
                            Print("Retry attempt ", attempts, " for OrderClose. Error: ", error);
                        }
                        else {
                            Print("Failed to close Order. Error: ", error);
                            break; // Exit the loop for other errors
                        }
                    }
                }
                if (!result) {
                    Print("Failed to close Order after maximum retries.");
                }
            }
            
            if(profit < -25.0)
            {
                bool result = false;
                int attempts = 0;
                while (!result && attempts < maxRetries)
                {
                    result = OrderClose(ticket, OrderLots(), Bid, 3, Red);st=0;keepbuy=0;
                    if (result)
                    {
                        Print("Order closed with profit -10. Ticket: ", ticket);
                        loss = loss + profit;
                        Print("Loss Profit: ", loss);
                    }
                    else
                    {
                        int error = GetLastError();
                        if (error == 138) {
                            // Retry order closure
                            attempts++;
                            Print("Retry attempt ", attempts, " for OrderClose. Error: ", error);
                        }
                        else {
                            Print("Failed to close Order. Error: ", error);
                            break; // Exit the loop for other errors
                        }
                    }
                }
                if (!result) {
                    Print("Failed to close Order after maximum retries.");
                }
            }
        }
    }
}
}



//+------------------------------------------------------------------+


/*
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
*/