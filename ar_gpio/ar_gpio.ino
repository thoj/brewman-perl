int command = 0; // 'H' = Set Digital Output High
// 'L' = Set Digital Output Low
// 'R' = Read Digital Input, RA = Read All
// 'S' = Read Digital Output Staus
// 'A' = Read Analog Input
// 'O' = Set Analog Output

char parameter = 0;
char parameter2 = 0;

int state = 0;

void setup() {
  Serial.begin(115200);
  Serial.println("READY\n");
}

void run_command(char cmd, char p1, char p2) {
  if (cmd == 'h' || cmd == 'H') {
    pinMode(p1, OUTPUT);
    digitalWrite(p1, HIGH);
    Serial.print("OK Port ");
    Serial.print((int)p1);
    Serial.println(" Set HIGH");
  } 
  else if ( cmd == 'l' || cmd == 'L') {
    pinMode(p1, OUTPUT);
    digitalWrite(p1, LOW);
    Serial.print("OK Port ");
    Serial.print((int)p1);
    Serial.println(" Set LOW");
  } 
  else if ( cmd == 'r' || cmd == 'R' ) {
    pinMode(p1, INPUT);
    state = digitalRead(p1);
    Serial.print('R');
    Serial.print(p1);
    Serial.println(state);
  } 
  else if ( cmd == 's' || cmd == 'S' ) {
    if (parameter == 'a' || parameter == 'A') {
      Serial.print("SA");
      for (int i = 1; i <= 13;i++) {
        state = digitalRead(i);
        Serial.print(state);
      }
      Serial.println();
    } 
    else {
      state = digitalRead(p1);
      Serial.print('S');
      Serial.print(p1);
      Serial.println(state);
    }
  } 
  else if ( cmd == 'a' || cmd == 'A' ) {
    state = analogRead(p1);
    Serial.print('A');
    Serial.print(p1);
    Serial.println(state);
  } 
  else if ( cmd == 'o' || cmd == 'O' ) {
    analogWrite(p1, p2);
    Serial.println("OK");
  } 
  else {
    Serial.println("FAIL");
  }  
}

void loop() {
 
}

void serialEvent() {
  pinMode(13, OUTPUT);
  digitalWrite(13, !digitalRead(13));
  char inByte = 0;
  if (Serial.available() > 0) {
    inByte = Serial.read();
    Serial.print(inByte);
    if (inByte == '\n') {
      if (command != 0 && parameter != 0) {
        run_command(command, parameter, parameter2);
      }
      //Reset commands
      command = 0;
      parameter = 0;
      parameter2 = 0;
    } 
    else if (command == 0) { // Read Command
      command = inByte;
    } 
    else if (parameter == 0) {
      parameter = inByte;
      if (parameter > 15) {
        parameter = parameter - 48;
      }
    } 
    else if (parameter2 == 0) {
      parameter2 = inByte;
    }
  } 
}



