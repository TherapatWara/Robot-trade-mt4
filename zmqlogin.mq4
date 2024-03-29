//+------------------------------------------------------------------+
//|                                                     zmqlogin.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Zmq/Zmq.mqh>
int ZMQ_SOCKET_TIMEOUT = 1000;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+


void OnInit()
  {
//---
   Context context("price_volume_time_publisher");
   string received;
   string port = AccountNumber();
   //Print(port);
   Socket socket(context, ZMQ_REQ);
   
    if (!socket.connect("tcp://localhost:5555")) {
        Print("Failed to connect to Python server. Error code: ", zmq_errno());
    }
    
    ZmqMsg message(port);
    if (!socket.send(message)) {
        Print("Failed to send price, volume, and time data to Python. Error code: ", zmq_errno());
        return;
    }
    
    ZmqMsg reply;
    if (!socket.recv(reply)) 
    {
        Print("Failed to receive reply from ZeroMQ Server. Error code: ", zmq_errno());

    }
    // ตรวจสอบว่าได้รับข้อความตอบกลับจาก Server หรือไม่
    string receivedMessage = reply.getData();
    Print("Received reply from ZeroMQ Server: ", receivedMessage);
    if(receivedMessage == 1)
    {
      Print("Loggin Success");
      Comment("User :", port);
    }
    else{
      Print("You not my user!!");
      ExpertRemove();
    }

    
  }
//+------------------------------------------------------------------+
