# compiler
This repository contains all project I made on the compiler class
# Train:
執行環境:windows 10 python 3.8.5

執行前先確認
修改python檔中dataset路徑確認是否正確，在轉成csv後要將資料集的所有csv檔放在dataset資料夾下，dataset.csv包含了良性和惡意flow，用於訓練模型，dataset_test.csv可用於測試單一flow，dataset.csv不包含dataset_test.csv內流量

安裝套件:
$pip install pandas
$pip install xgboost
$pip install lightgbm
$pip install catboost
$pip install scikit-learn
$pip install matplotlib
$apt-get install python-tk
$pip install seaborn
## 執行的方式有兩種：
### 第一種是將自己產生好的pcap轉成csv
$./easy.sh [要轉換的pcap]//要轉換的pcap請輸入字串

//請在github下載一個開源軟件，名稱為TCPDUMP_and_CICFlowMeter，會用到裡面的一個執行檔，名稱為convert_pcap_csv.sh
//github網址:https://github.com/iPAS/TCPDUMP_and_CICFlowMeter

$python auto_label.py [要label的csv] [種類]//要label的csv請輸入字串，種類請輸入數字，良性給0
//ex. python auto_label.py Geodo.pcap_Flow.csv 3  其結果將會輸出Geodo.pcap_Flow_with_label.csv

### 第二種是去以下連結下載USTC-TFC2016 與recorded_ransomware資料集中的csv檔當作訓練資料
https://drive.google.com/drive/folders/1LnjFAS6huEs7wYqhzlT34YosBixgpVzN?usp=sharing

最後
$python gen_dataset_malicious.py //產生dataset.csv與dataset_test.csv
$python xgb_classfier.py //使用dataset.csv訓練並建構出xgb模型malicious.bin

# Test(即時預測):

執行環境:ubuntu18.04 python 3.9以上
執行前先將auto_predict.sh, auto_test_label.py, xgbmodel_predict.py, malicious.bin放在TCPDUMP_and_CICFlowMeter資料夾下
## 開兩個視窗，分別執行以下兩個指令：
$./capture_interface_pcap.sh [網卡名稱] [目的資料夾][授權使用者] 
//大約每過一分鐘產生1個pcap檔案，自動呼叫專案內另一個執行檔案convert_pcap_csv.sh，將剛剛產生的pcap檔案轉為csv檔案，使用者可在capture_interface_pcap.sh中控制csv產生的速度
$./run.sh
//自動抓取./csv資料夾下的csv進行整理並且將整理好的csv放入xgb模型malicious.bin進行預測，預測完會將csv檔刪除，使用者可以自行調整抓取csv的時間(調整run.sh中sleep的秒速)
