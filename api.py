import zmq
import mysql.connector
import csv
import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
from tensorflow.keras.models import load_model
import pickle
# ฟังก์ชันสำหรับเขียนข้อมูลลงใน MySQL
'''
def write_to_mysql(account_number, account_balance, account_equity):
    # เชื่อมต่อ MySQL
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="bot01"
    )
    cursor = connection.cursor()

    # เขียนข้อมูลลงในฐานข้อมูล
    sql = "INSERT INTO profit (profit_id, portnumber, profit_date, equity, balance) VALUES (NULL, %s, NOW(), %s, %s)"
    val = (account_number, account_equity, account_balance)
    cursor.execute(sql, val)
    connection.commit()
    
    print("Data written to MySQL successfully.")


def write_to_history(price, account_number, ticket):
    # เชื่อมต่อ MySQL
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="bot01"
    )
    cursor = connection.cursor()

    # เขียนข้อมูลลงในฐานข้อมูล
    sql = "INSERT INTO history (his_id, date, money, stats, portnumber,ticket) VALUES (NULL, NOW(), %s, 0, %s , %s)"
    val = (price, account_number,ticket)
    cursor.execute(sql, val)
    connection.commit()
    
    print("Data written to MySQL successfully.")
'''
model = load_model("model_v1_h4_3input.h5")
with open('model.pkl', 'wb') as model_file:
    pickle.dump(model, model_file)
with open('model.pkl', 'rb') as model_file:
    loaded_model = pickle.load(model_file)    


def main():
    # สร้าง Socket ประเภท REP (Reply) เพื่อรอรับข้อมูล
    context = zmq.Context()
    socket = context.socket(zmq.REP)
    socket.bind("tcp://*:5555")
    print("Waiting for incoming messages...")
    
    while True:
        # รับข้อมูลจาก MQL4
        message = socket.recv_string()
        print(f"Received message: {message}")


        # แยกข้อมูลจากข้อความ
        parts = message.split('|')
        if parts[0].strip() == "profit":
            account_number = parts[1].strip().split(':')[1].strip()
            account_balance = float(parts[2].strip().split(':')[1].strip())
            account_equity = float(parts[3].strip().split(':')[1].strip())
            write_to_mysql(account_number, account_balance, account_equity)
        elif parts[0].strip() == "history":
            price = float(parts[1].strip().split(':')[1].strip())
            account_number = parts[2].strip().split(':')[1].strip()
            ticket = parts[3].strip().split(':')[1].strip()
            write_to_history(price, account_number, ticket)
        elif parts[0].strip() == "data":
            data_rows = parts[0:]
            with open("data.csv", "w", newline='') as csvfile:
                writer = csv.writer(csvfile)
                
                # Write header row
                # writer.writerow(['Time', 'Close'])
                
                for row in data_rows:
                    # Remove the "data|" prefix
                    row = row.strip().replace("data|", "")
                    # Split each row into columns
                    row = row.replace("data", "")
                    columns = row.split(',')
                    # Write only time and close price to CSV
                    writer.writerow(columns)
            #print("CSV file created successfully.")
            input_data = pd.read_csv("data.csv")
            input_data = np.array(input_data)
            input_data = np.reshape(input_data, (1, 3))
            #print(input_data)
            result = loaded_model.predict(input_data)
            #print(result)
            result1 = str(result)
            result2 = result1.strip('[]')
            print(result2)
            socket.send_string(result2)

if __name__ == "__main__":
    main()
