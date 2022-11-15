//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	/*Command*/		/*Update Interval*/	/*Update Signal*/
	{"", "memory",			5,		0},
	{"", "battery",			30,		0},
	{"", "cpu_temp",		5,		0},
	/*{"", "nm-applet 2>/dev/null",	0,		0},*/
	{"", "date_hour",		5,		0},
};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = " | ";
static unsigned int delimLen = 5;
