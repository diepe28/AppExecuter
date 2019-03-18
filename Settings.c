#include  "Settings.h"

const char* OUTPUT_FILE_STR = "output.log";
const char* INPUT_FILE_STR = "settings.ini";
const char* SETTING_COMMAND = "Command";
const char* SETTING_NUM_RUNS = "NumRuns";
const char* SETTING_TIMEOUT = "TimeOut";
const char* SETTING_CORRECT_RESULT = "CorrectResult";
//what to search for in output file
const char* RESULT_STR = "Final result: ";
const char* SOFT_ERROR_STR = "SOFT ERROR DETECTED";
int commandStates[5];

// Other methods
Settings * readSettings(){
	Settings* mySettings = malloc(sizeof(Settings));
	mySettings->command = (char*) malloc(sizeof(char) * 2048);
	mySettings->correctOutput = (char*) malloc(sizeof(char) * 128);

	int i;
	FILE *inputFile;
	char str[MAXCHAR];
	char* line = NULL,
		*subStr = NULL;
	size_t len = 0;
  ssize_t lineLength;

	inputFile = fopen(INPUT_FILE_STR, "r");
	if (!inputFile){
		printf("Could not open file %s",INPUT_FILE_STR);
		return NULL;
	}

	// Parsing file to setting enum
	while ((lineLength = getline(&line, &len, inputFile)) != -1) {
		char *ptr = strchr(line, '=');
		if(ptr) {
   		int index = ptr - line;
			int valueLength =  lineLength-(index+1);

			// parsing the line to name,value
  		char* settingName = (char*) malloc(sizeof(char) * index);
			char* settingValue = (char*) malloc(sizeof(char) * valueLength-1);
			memcpy(settingName, line, index);
			memcpy(settingValue, ptr+1, valueLength-1); // -1 to avoid the \n

			// switch of settings
			if (strcmp(settingName, SETTING_COMMAND) == 0) {
			  strcpy(mySettings->command, settingValue);
			}
			else if (strcmp(settingName, SETTING_CORRECT_RESULT) == 0) {
				strcpy(mySettings->correctOutput, settingValue);
			}
			else if (strcmp(settingName, SETTING_TIMEOUT) == 0) {
				mySettings->timeoutSeconds = strtol(settingValue, NULL, 10);
			}
			else if (strcmp(settingName, SETTING_NUM_RUNS) == 0) {
				mySettings->numRuns = strtol(settingValue, NULL, 10);
			}

			free(settingName);
			free(settingValue);
		}
	}

	printSettings(mySettings);

	// init array of output states to 0s
	for(i < 0; i < 5; i++){
		commandStates[i] = 0;
	}

	fclose(inputFile);
	free(line);
	return mySettings;
}

void executeSettings(Settings* this){
	int i = 0;
	State currentState;

	for(; i < this->numRuns; i++){
		char output_log[64];
	  snprintf(output_log, 64, "%d-%s", i, OUTPUT_FILE_STR);
    step1_executeCommand(this->command, output_log, this->timeoutSeconds);
		currentState = step2_classifyOutput(output_log, this->correctOutput);
		printf("Run #%d: ", i);
		printCurrentState(currentState);
		commandStates[currentState]++;
	}

	printResults(this->numRuns);
}


void freeSettings(Settings * this){
	free(this->command);
	free(this->correctOutput);
	free(this);
}

void step1_executeCommand(char * command, char * output_log, int timeoutSeconds){
	// Appending "> output.txt" to command
	static char new_buffer[2048];
  snprintf(new_buffer, 2048, "timeout %ds %s > %s",
	 timeoutSeconds, command, output_log);
  //printf("Executing command: %s\n", new_buffer);
  int status = system(new_buffer);
	//printf("Status of command: %d\n", status);
}

// returns the index of the first occurrence in text of subStr, -1 if not found
int str_indexOf(char * subStr, char* text){
	int index = -1, i = 0, j = 0,
	 textLength = strlen(text), subStrLenth = strlen(subStr);

	for(i = 0; i < textLength; i++){
		if(text[i] == subStr[j]) j++;
		else j = 0;

		if(j == subStrLenth){
			index = (i - j) + 1;
			break;
		}
	}

	return index;
}

State step2_classifyOutput(char * outputLog, char * correctOutput){
	State commandState = State_Correct;
	FILE *outputFile;
	char str[MAXCHAR];
	char* finalLine = NULL, *subStr = NULL, *currentOutput = NULL;
	int indexOf = 0;
	size_t len = 0;
  ssize_t lineLength;

	outputFile = fopen(outputLog, "r");
  // If the file does not exist is because the command did not finished
	if (outputFile == NULL){
	  return State_Crashed;
	}

	// read all lines...
	while ((lineLength = getline(&finalLine, &len, outputFile)) != -1);

	if (finalLine){
		// if it contains 'Final result: ' is either correct or corrupted
		indexOf = str_indexOf((char*)RESULT_STR, finalLine);

		if (indexOf != -1){
			int resultStrLength = strlen(RESULT_STR);
			int valueLength = -1;

			// move the char * after ':', to get the current output
			subStr = finalLine + indexOf + resultStrLength;
			valueLength = strlen(subStr) -1;
			currentOutput = (char*) malloc(sizeof(char) * valueLength);
			memcpy(currentOutput, subStr, valueLength);

			// TODO - maybe define a threshold of flexibility

			commandState = strcmp(currentOutput, correctOutput) == 0 ?
											State_Correct : State_Corrupted;

		  //printf("Comparison: %s vs %s\n", currentOutput, correctOutput);
			free(currentOutput);
		}
		else{
			// if it contains 'SOFT ERROR DETECTED: '
	    if ((subStr = strstr(finalLine, SOFT_ERROR_STR)) != NULL){
	      commandState = State_SoftErrorDetected;
	      // TODO, timeout finished
	    }else{
	      // If none of the above
	      commandState = State_Crashed;
	    }
		}
		free(finalLine);
	}

	fclose(outputFile);
	return commandState;
}

void printSettings(Settings * this){
	printf("Current Settings:\n");
	printf("  %s: %s\n", SETTING_COMMAND, this->command);
	printf("  %s: %s\n", SETTING_CORRECT_RESULT, this->correctOutput);
	printf("  %s: %d\n", SETTING_TIMEOUT, this->timeoutSeconds);
	printf("  %s: %d\n", SETTING_NUM_RUNS, this->numRuns);
	printf("\n");
}

void printResults(int numRuns){
	double corruptedP =  		((double) commandStates[State_Corrupted] / numRuns) * 100;
	double correctP = 	 		((double) commandStates[State_Correct] / numRuns) * 100;
	double hungP =  				((double) commandStates[State_Hung] / numRuns) * 100;
	double S_E_DetectedP =  ((double) commandStates[State_SoftErrorDetected] / numRuns) * 100;
	double crashedP =  			((double) commandStates[State_Crashed] / numRuns) * 100;

	printf("\n-------------- Results --------------\n");
	printf(" Corrupted:           %d -- %.5f%% \n", commandStates[State_Corrupted], corruptedP);
	printf(" Correct:             %d -- %.5f%% \n", commandStates[State_Correct], correctP);
	printf(" Hung:                %d -- %.5f%% \n", commandStates[State_Hung], hungP);
	printf(" Soft-Error Detected: %d -- %.5f%% \n", commandStates[State_SoftErrorDetected], S_E_DetectedP);
	printf(" Crashed:             %d -- %.5f%% \n", commandStates[State_Crashed], crashedP);
	printf("----------------------------------------|\n");
}

void printCurrentState(State state){
	printf("--- Current State: ");
	switch (state) {
		case State_Correct:
			printf("CORRECT");
			break;

		case State_Hung:
			printf("HUNG");
			break;

		case State_Crashed:
			printf("CRASHED");
			break;

		case State_Corrupted:
			printf("CORRUPTED!");
			break;

		case State_SoftErrorDetected:
			printf("ERROR DETECTED!");
			break;

	}

	printf(" \n");
}
