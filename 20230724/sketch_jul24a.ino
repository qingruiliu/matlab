#define PIN_LED  3
#define PIN_BTN  2

char serial_recv;
int BUTTONState = 0;
int seqID = 0;
int n = 10;
bool flag = false;
bool state = false;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  randomSeed(analogRead(0));
  
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_BTN, INPUT);
  digitalWrite(PIN_LED, LOW);
}

void loop() {
  // put your main code here, to run repeatedly:
  if (Serial.available() > 0){
    serial_recv = Serial.read(); // シリアル通信を受信
    switch(serial_recv){
    case '3':
      Serial.println('A');
      delay(5);
      seqID = Serial.read();
      state = true;
      break;
    default:
      Serial.println('B');
      delay(5);
      state = false;
    }
  }

  if (digitalRead(PIN_BTN)) {
    flag = state;
  }
  if (flag) {
    digitalWrite(PIN_LED, HIGH);
    Serial.println('lick in the RW');
    delay(200);
    for (int i = 0; i < n; i++){
    }
    delay(200);  // 不応期
    flag = false;
    digitalWrite(PIN_LED, LOW);
  }
}
