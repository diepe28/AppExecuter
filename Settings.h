#ifndef _SETTINGS_H
#define _SETTINGS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <assert.h>
#include <pthread.h>

// Types definition
typedef struct {
    char* command;
		char* correctOutput;
    int numRuns;
		int timeoutSeconds;
} Settings;

typedef enum {
    State_Correct,
		State_Corrupted,
		State_Hung,
		State_SoftErrorDetected,
		State_Crashed
} State;

// Constants definitions
#define MAXCHAR 1000
extern const char* OUTPUT_FILE_STR;
extern const char* INPUT_FILE_STR;
extern const char* RESULT_STR;
extern const char* SETTING_COMMAND;
extern const char* SETTING_NUM_RUNS;
extern const char* SETTING_TIMEOUT;
extern const char* SETTING_CORRECT_RESULT;
extern int commandOutputStates[5];

// Functions
Settings * readSettings(char *);
void freeSettings(Settings *);
void printSettings(Settings *);
void printResults(int);
void executeSettings(Settings*);
int str_indexOf(char *, char*);

void  step1_executeCommand(char *, char *, int);
State step2_classifyOutput(char *, char *);
void printCurrentState(State);

#endif
