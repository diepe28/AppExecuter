
#include "Settings.h"

// Main Method
int main(int argc, char** argv) {
  //char * x = "ing";
  //char * y = "this is the whole string abc oh yes";
  //printf ("Index of \"%s\" in \"%s\" is: %d\n", x, y, str_indexOf(x, y));
  //return 1;
	Settings* mySettings = readSettings();

	executeSettings(mySettings);

	freeSettings(mySettings);

	return 0;
}
