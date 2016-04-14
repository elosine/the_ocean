
#define nb 11

//pot
//pot 4 broken
int np = 5; //number of pots
int p[] = { A0, A1, A2, A3, A7 }; //analog input pins
int pv[5];//pot value
int ppv[] = {0, 0, 0, 0, 0}; //previous pot value

//buttons
//int nb = 12;
int b[] = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 }; //digital input pins
boolean bg[] = {true, true, true, true, true, true, true, true, true, true, true, true}; //momentary button gates
////button toggle
int btv[] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}; //toggle button current value
int btamt[] = { 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2 }; //number of toggles
boolean btg[] = {true, true, true, true, true, true, true, true, true, true, true}; //toggle button gates

//fsrs
int numsens = 2;
int fsr[] = {A5, A6};
int val[2];
int thresh[] = {100, 230};
boolean peakgate[] = {true, true};
int pval[] = {0, 0};

void setup() {
  Serial.begin(9600);
  //sets the digital pins for the buttons to input and pulls resistor high
  for (int i = 0; i < nb; i++) {
    pinMode(b[i], INPUT_PULLUP);
  } //end for (int i = 0; i < nb; i++) loop thru all buttons
} //end setup


void loop() {
  //FSRs
  for (int i = 0; i < numsens; i++) {
    val[i] = analogRead(fsr[i]);
    //Peak Detection
    if (val[i] > thresh[i]) {
      Serial.print("fsr");
      Serial.print(i);
      Serial.print(":");
      Serial.println(val[i]);
      if (val[i] > pval[i]) { //is it going up?
        pval[i] = val[i];
      }
      else { //its going down i.e., val<pval
        if (peakgate[i]) { //if gate is open
          Serial.print("fsp");
          Serial.print(i);
          Serial.print(":");
          Serial.println(pval[i]); //this is our peak
          peakgate[i] = false; //close gate
        }
      }
    }
    else { //is below thresh
      if (!peakgate[i]) {
        peakgate[i] = true;
        pval[i] = 0;
        Serial.print("fsr");
        Serial.print(i);
        Serial.print(":");
        Serial.print(0);
      }
    }
  }

  //POTS
  for (int i = 0; i < np; i++) { //loop thru all pots
    pv[i] = analogRead(p[i]); //read analog pin
    //Send out values only when pot changes
    if ( pv[i] < (ppv[i] - 2) || pv[i] > (ppv[i] + 2) ) {
      //Action
      Serial.print( "p" + String(i) + ":");
      Serial.println(pv[i]); //send value to serial bus
    }
    //Update previous value
    ppv[i] = pv[i];


  }//end loop thru all pots


  //BUTTONS

  for (int i = 0; i < nb; i++) { //loop thru all buttons

    //if button is pressed (reads LOW)
    if ( digitalRead(b[i]) == LOW ) { //button on

      ////Momentary
      if (bg[i]) {
        bg[i] = false;
        Serial.print( "b" + String(i) + ":");
        Serial.println(1);
      }

      ////Toggles
      if (btg[i]) {
        btg[i] = false; //CLOSE GATE
        btv[i] = btv[i] + 1; //INC VALUE
        btv[i] = btv[i] % btamt[i]; //MOD VALUE
        Serial.print( "bt" + String(i) + ":"); //PRINT HEADER
        Serial.println(btv[i]); //PRINT VAL
      }

    } //end if button pressed

    //if button is released (reads HIGH)
    if ( digitalRead(b[i]) == HIGH ) { //button off

      ////Momentary
      if (!bg[i]) {
        bg[i] = true;
        Serial.print( "b" + String(i) + ":");
        Serial.println(0);
      }

      ////Toggles
      if (!btg[i]) {
        btg[i] = true;
      }

    } //end if button released


  } //end loop all buttons
  delay(15);

} //end void loop


