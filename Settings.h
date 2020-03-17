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
    int numIters;
		int timeoutSeconds;
} Settings;

typedef enum {
    State_Correct,
    State_Correct_Extra_Iters,
		State_Corrupted,
		State_Hung,
		State_SoftErrorDetected,
		State_Crashed,

    State_Correct_SED,
    State_Correct_Extra_Iters_SED,
		State_Corrupted_SED,
		State_Hung_SED,
		State_Crashed_SED
} State;

// Constants definitions
#define NUM_STATES 11
#define MAXCHAR 1000
#define KILLED_BY_TIMEOUT 31744
extern const char* OUTPUT_FILE_STR;
extern char APP_GOT_HUNG_STR[];
extern char APP_GOT_CORRUPTED_STR[];
extern const char* INPUT_FILE_STR;
extern const char* RESULT_STR;
extern const char* SETTING_COMMAND;
extern const char* SETTING_NUM_RUNS;
extern const char* SETTING_TIMEOUT;
extern const char* SETTING_CORRECT_RESULT;
extern const char* SETTING_NUM_ITERS;

// Functions
Settings * readSettings(char *);
void freeSettings(Settings *);
void printSettings(Settings *);
void printResults(int);
void executeSettings(Settings*);
int str_indexOf(char *, char*);

int step1_executeCommand(char *, char *, int);
int wasSoftErrorDetected(char *);
State reclassifyOutput(State, int);
State step2_classifyOutput(char *, char *, int);
void printCurrentState(State);

#endif
