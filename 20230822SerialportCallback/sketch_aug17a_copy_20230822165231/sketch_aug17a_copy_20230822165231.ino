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
  if(digitalRead(PIN_BTN)){
    Serial.println('l');
    delay(200);
}
}