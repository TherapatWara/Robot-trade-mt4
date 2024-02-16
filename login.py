import zmq
import mysql.connector

    # เขียนข้อมูลลงในฐานข้อมูล
    
    #print("PORT NUMBER : " , cursor.execute(sql))
    #cursor.close()

def read_to_user(account_number):
    # เชื่อมต่อ MySQL
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="ai"
    )
    cursor = connection.cursor()


    # คำสั่ง SQL เพื่อดึงข้อมูล portnumber จากตาราง infouser
    sql = "SELECT cus_port FROM customer"
    cursor.execute(sql)

    # ดึงข้อมูลทั้งหมด
    portnumbers = cursor.fetchall()
    result_list = [row[0] for row in portnumbers]
    # แสดงผลลัพธ์
    for result_list in portnumbers:
        if(str(result_list[0]) == str(account_number)):
            return 1


def main():
    context = zmq.Context()
    socket = context.socket(zmq.REP)
    socket.bind("tcp://*:5555")
    print("Waiting for incoming messages...")

    account_number = socket.recv_string()
    print("Received request: ", account_number)

    if(read_to_user(account_number)==1):
        socket.send_string("1")
    else:
        socket.send_string("0")




    

if __name__ == "__main__":
    main()
    
