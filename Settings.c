#include  "Settings.h"

const char* OUTPUT_FILE_STR = "output.log";
const char* INPUT_FILE_STR = "Settings/settings.ini";
const char* SETTING_COMMAND = "Command";
const char* SETTING_NUM_RUNS = "NumRuns";
const char* SETTING_NUM_ITERS = "NumIters";
const char* SETTING_TIMEOUT = "TimeOut";
const char* SETTING_CORRECT_RESULT = "CorrectResult";
//what to search for in output file
const char* RESULT_STR = "Final result: ";
const char* ITERATIONS_STR = "Iterations: ";
const char* SOFT_ERROR_STR = "SOFT ERROR DETECTED";
int commandStates[NUM_STATES];

// Other methods
Settings * readSettings(char * settingsFile){
	Settings* mySettings = malloc(sizeof(Settings));
	mySettings->command = (char*) malloc(sizeof(char) * 2048);
	mySettings->correctOutput = (char*) malloc(sizeof(char) * 128);

	int i;
	FILE *inputFile;
	char str[MAXCHAR];
	char* line = NULL,
		*subStr = NULL;
	size_t len = 0, lineLength;

	inputFile = fopen(settingsFile, "r");
	if (!inputFile){
		printf("Could not open file %s", settingsFile);
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
			memcpy(settingValue, ptr+1, valueLength-2); // -1 to avoid the ';' and the end of line

			// 'switch' of settings
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
			else if (strcmp(settingName, SETTING_NUM_ITERS) == 0) {
				mySettings->numIters = strtol(settingValue, NULL, 10);
			}

			free(settingName);
			free(settingValue);
		}
	}

	printSettings(mySettings);

	// init array of output states to 0s
	for(i < 0; i < NUM_STATES; i++){
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

    if(step1_executeCommand(this->command, output_log, this->timeoutSeconds)){
			currentState = step2_classifyOutput(
				output_log, this->correctOutput, this->numIters);
		}else{
			currentState = reclassifyOutput(State_Hung, wasSoftErrorDetected(output_log));
		}

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

// Returns 1 if the command was not killed by the timeout
int step1_executeCommand(char * command, char * output_log, int timeoutSeconds){
	// Appending "> output.txt" to command
	static char new_buffer[2048];
  snprintf(new_buffer, 2048, "timeout %ds %s > %s",
	 timeoutSeconds, command, output_log);
  printf("Executing command: %s\n", new_buffer);
  int status = system(new_buffer);
	printf("Status of command: %d\n", status);
	return status != KILLED_BY_TIMEOUT;
}

// returns the index of the first occurrence in text of subStr, -1 if not found
int str_indexOf(char * subStr, char* text){
	int index = -1, i = 0, j = 0,
	 textLength = strlen(text), subStrLenth = strlen(subStr);

	if(textLength > subStrLenth){
		for(i = 0; i < textLength; i++){
			if(text[i] == subStr[j]) j++;
			else j = 0;

			if(j == subStrLenth){
				index = (i - j) + 1;
				break;
			}
		}
	}

	//printf("Index: %d, %s in %s\n", index, subStr, text);

	return index;
}

int wasSoftErrorDetected(char * outputLog){
	int result = 0, indexOf = 0;
	FILE *outputFile;
	char* finalLine = NULL;
	size_t len = 0;
  ssize_t lineLength;

	outputFile = fopen(outputLog, "r");
  // If the file does not exist is because the command did not finished
	if (outputFile == NULL){
	  return 0;
	}

	// read all lines...
	while ((lineLength = getline(&finalLine, &len, outputFile)) != -1){
		// if it contains 'SOFT ERROR DETECTED: '
		indexOf = str_indexOf((char*)SOFT_ERROR_STR, finalLine);
		if(indexOf != -1){
			result = 1;
			break;
		}
	}

	if (result == 0 && finalLine){
		// if it contains 'SOFT ERROR DETECTED: '
		indexOf = str_indexOf((char*)SOFT_ERROR_STR, finalLine);
		if (indexOf != -1)
			result = 1;
	}

	fclose(outputFile);
	return result;
}

State reclassifyOutput(State state, int sofErrorDetected){
	if(sofErrorDetected){
		switch (state) {
			case State_Correct:
				return State_Correct_SED;

			case State_Correct_Extra_Iters:
				return State_Correct_Extra_Iters_SED;

			case State_Hung:
				return State_Hung_SED;

			case State_Crashed:
				return State_Crashed_SED;

			case State_Corrupted:
				return State_Corrupted_SED;
			}
		}

		return state;
}

State step2_classifyOutput(char * outputLog, char * correctOutput, int correctNumIters){
	State commandState = State_Correct;
	FILE *outputFile;
	char str[MAXCHAR];
	char* finalLine = NULL, *subStr = NULL,*currentOutput = NULL;
	int indexOf = 0, currentIters = 0, resultStrLength, valueLength = -1, sofErrorDetected = 0;
	size_t len = 0;
  ssize_t lineLength;

	outputFile = fopen(outputLog, "r");
  // If the file does not exist is because the command did not finished
	if (outputFile == NULL){
	  return State_Crashed;
	}

	// read all lines...
	while ((lineLength = getline(&finalLine, &len, outputFile)) != -1){
		indexOf = str_indexOf((char*)ITERATIONS_STR, finalLine);
		// if it contains 'Iterations: '
		if(indexOf != -1){
			resultStrLength = strlen(ITERATIONS_STR);
			valueLength = -1;

			// move the char * after ':', to get the current output
			subStr = finalLine + indexOf + resultStrLength;
			valueLength = strlen(subStr) -1;
			currentOutput = (char*) malloc(sizeof(char) * valueLength);
			memcpy(currentOutput, subStr, valueLength);
			currentIters = strtol(currentOutput, NULL, 10);
			printf("Current num iters: %d\n", currentIters);
			free(currentOutput);
		}
	}

	if (finalLine){
		// if it contains 'Final result: ' is either correct or corrupted
		indexOf = str_indexOf((char*)RESULT_STR, finalLine);

		if (indexOf != -1){
			resultStrLength = strlen(RESULT_STR);
			valueLength = -1;

			// move the char * after ':', to get the current output
			subStr = finalLine + indexOf + resultStrLength;
			valueLength = strlen(subStr) -1;
			currentOutput = (char*) malloc(sizeof(char) * valueLength);
			memcpy(currentOutput, subStr, valueLength);

			if (strcmp(currentOutput, correctOutput) == 0){
				commandState = currentIters == correctNumIters ?
					State_Correct :
				 	State_Correct_Extra_Iters;
			}
			else{
				commandState = State_Corrupted;
			}

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

	return reclassifyOutput(commandState, wasSoftErrorDetected(outputLog));
}

void printSettings(Settings * this){
	printf("Current Settings:\n");
	printf("  %s: %s\n", SETTING_COMMAND, this->command);
	printf("  %s: %s\n", SETTING_CORRECT_RESULT, this->correctOutput);
	printf("  %s: %d\n", SETTING_NUM_ITERS, this->numIters);
	printf("  %s: %d\n", SETTING_TIMEOUT, this->timeoutSeconds);
	printf("  %s: %d\n", SETTING_NUM_RUNS, this->numRuns);
	printf("\n");
}

void printResults(int numRuns){
	double corruptedP =  			((double) commandStates[State_Corrupted] / numRuns) * 100;
	double correctP = 	 			((double) commandStates[State_Correct] / numRuns) * 100;
	double hungP =  					((double) commandStates[State_Hung] / numRuns) * 100;
	double S_E_DetectedP =  	((double) commandStates[State_SoftErrorDetected] / numRuns) * 100;
	double crashedP =  				((double) commandStates[State_Crashed] / numRuns) * 100;
	double correct_extra_P =  ((double) commandStates[State_Correct_Extra_Iters] / numRuns) * 100;
	// new states with SED
	double corrupted_SED_P =  			((double) commandStates[State_Corrupted_SED] / numRuns) * 100;
	double correct_SED_P = 	 			  ((double) commandStates[State_Correct_SED] / numRuns) * 100;
	double hung_SED_P =  					  ((double) commandStates[State_Hung_SED] / numRuns) * 100;
	double crashed_SED_P =  				((double) commandStates[State_Crashed_SED] / numRuns) * 100;
	double correct_extra_SED_P =   ((double) commandStates[State_Correct_Extra_Iters_SED] / numRuns) * 100;

	printf("\n-------------- Results --------------\n");
	printf(" Corrupted:            %d -- %.5f%% \n", commandStates[State_Corrupted], corruptedP);
	printf(" Correct:              %d -- %.5f%% \n", commandStates[State_Correct], correctP);
	printf(" Correct-Extra-Iters:  %d -- %.5f%% \n", commandStates[State_Correct_Extra_Iters], correct_extra_P);
	printf(" Hung:                 %d -- %.5f%% \n", commandStates[State_Hung], hungP);
	printf(" Soft-Error Detected:  %d -- %.5f%% \n", commandStates[State_SoftErrorDetected], S_E_DetectedP);
	printf(" Crashed:              %d -- %.5f%% \n", commandStates[State_Crashed], crashedP);
	printf(" Corrupted_SED:            %d -- %.5f%% \n", commandStates[State_Corrupted_SED], corrupted_SED_P);
	printf(" Correct_SED:              %d -- %.5f%% \n", commandStates[State_Correct_SED], correct_SED_P);
	printf(" Correct-Extra-Iters_SED:  %d -- %.5f%% \n", commandStates[State_Correct_Extra_Iters_SED], correct_extra_SED_P);
	printf(" Hung_SED:                 %d -- %.5f%% \n", commandStates[State_Hung_SED], hung_SED_P);
	printf(" Crashed_SED:              %d -- %.5f%% \n", commandStates[State_Crashed_SED], crashed_SED_P);
	printf("----------------------------------------|\n");
}

void printCurrentState(State state){
	printf("--- Current State: ");
	switch (state) {
		case State_Correct:
			printf("CORRECT");
			break;

		case State_Correct_Extra_Iters:
				printf("CORRECT EXTRA ITERS");
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

		// NEW STATES WITH SE DETECTED
		case State_Correct_SED:
			printf("CORRECT BUT SE DETECTED");
			break;

		case State_Correct_Extra_Iters_SED:
			printf("CORRECT EXTRA ITERS BUT SE DETECTED");
			break;

		case State_Hung_SED:
			printf("HUNG BUT SE DETECTED");
			break;

		case State_Crashed_SED:
			printf("CRASHED BUT SE DETECTED");
			break;

		case State_Corrupted_SED:
			printf("CORRUPTED! BUT SE DETECTED");
			break;
	}
	printf(" \n");
}
