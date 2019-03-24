#include "Settings.h"

// Main Method
int main(int argc, char** argv) {
	char * settingsFile = argc > 1 ? argv[1] : (char*) INPUT_FILE_STR;
	printf("Reading settings file: %s\n", settingsFile);

	Settings* mySettings = readSettings(settingsFile);
	executeSettings(mySettings);
	freeSettings(mySettings);

	return 0;
}
