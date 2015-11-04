/****************************************************************************
*
* Program: epoch
* Version: 1.1
* Author: Marco Ponton
*
*
* History:
*   ------> Do not forget to change VERSION also!
*   - 1.1 - 2005/01/04 - Marco Ponton
*           - Fixed dangling pointer bug that caused seg. faults
*             on Linux.
*   - 1.0 - 2001/11/19 - Marco Ponton
*           - Initial Release
*
*
* Information:
*
*   This program convert a date/time to epoch time and epoch time to
*   date/time.
*
*
* Usage:
*
*   epoch [ "datetime_string" | -e [epoch_time|now] ] [ -f "format" ]
*
*   NOTES:
*
*     - The default datetime_string format is "YYYY mm dd HH MM SS".
*     - The format specified with -f for date/time to epoch conversion
*       must follow the strptime() convention (i.e. specifiers must be
*       separated by blanks or non-numeric characters). See strptime()
*       man page for more information.
*     - The format specified with -f for epoch to date/time conversion
*       must follow the strftime() convention. See strftime() man page
*       for more information.
*
*
* Examples:
*
*   $ epoch
*
*     RETURNS: "Now" epoch time
*
*   $ epoch "2000 12 31 23 59 59"
*
*     RETURNS: 978325199
*
*   $ epoch -e 978325199 -f "%a %b %d %X %Z %Y"
*
*     RETURNS: Sun Dec 31 23:59:59 EST 2000
*
*   $ epoch "Wed Dec 31 19:00:00 EST 1969" -f "%a %b %d %X %Z %Y"
*
*     RETURNS: 0
*
****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <strings.h>
#include <ctype.h>
#include <time.h>
#include <errno.h>


/* Constants */
const char VERSION[] = "epoch v1.1";
#define MAX_FORMAT 512
#define MAX_DATE 512
const char DEFAULT_DATE_FORMAT[] = "%Y %m %d %H %M %S";


/* Global Variables */
int epoch_to_date = 0;
time_t epoch_time = 0;
char date_format[MAX_FORMAT+1];
char date_string[MAX_DATE+1];
struct tm tm_time;


/* Function headers */
void usage(char *myname, char *msg);
void parse_argv(int argc, char *argv[]);


/* Main */
int main(int argc, char *argv[])
{
  char buffer[MAX_DATE*2+1];

  parse_argv(argc, argv);

  if (date_format[0] == 0)
    strcpy(date_format, DEFAULT_DATE_FORMAT);

  if (epoch_to_date)
  {
    strftime(buffer, MAX_DATE*2, date_format, localtime(&epoch_time));
    buffer[MAX_DATE*2] = 0;
    printf("%s\n", buffer);
  }
  else
  {
    if (date_string[0] == 0)
      printf("%lu\n", time(NULL));
    else
    {
      if ((char *)strptime(date_string, date_format, &tm_time) == (char *)NULL)
        usage(argv[0], "Invalid date/time");
      tm_time.tm_isdst = -1;
      printf("%lu\n", mktime(&tm_time));
    }
  }


  return(0);
}


/* Print usage information and quit */
void usage(char *myname, char *msg)
{
  fprintf(stderr, "\n%s\n", VERSION);

  if (msg != NULL)
  {
    fprintf(stderr, "\nERROR: %s\n", msg);
  }

  fprintf(stderr, "\nUsage:\n \
  \n \
  %s [ \"datetime_string\" | -e [epoch_time|now] ] [ -f \"format\" ]\n \
  \n \
  NOTES:\n \
  \n \
    - The default datetime_string format is \"YYYY mm dd HH MM SS\".\n \
    - The format specified with -f for date/time to epoch conversion\n \
      must follow the strptime() convention (i.e. specifiers must be\n \
      separated by blanks or non-numeric characters). See strptime()\n \
      man page for more information.\n \
    - The format specified with -f for epoch to date/time conversion\n \
      must follow the strftime() convention. See strftime() man page\n \
      for more information.\n \
  \n", basename(myname));

  exit(1);
}


/* Parse and validate command line arguments */
void parse_argv(int argc, char *argv[])
{
  int i, j;
  char buffer[32];
  int date_to_epoch = 0;

  for(i = 1; i < argc; i++)
  {
    if (strcmp(argv[i], "-e") == 0)
    {
      /* User wants to transform epoch to date string */
      epoch_to_date = 1;

      ++i;
      if (i < argc)
      {
        strncpy(buffer, argv[i], 31);
        buffer[31] = 0;

        /* Validate epoch string */
        /* The length should be between 1 and 10 characters */
        if (strlen(buffer) > 10)
          usage(argv[0], "Invalid epoch time");

        if (strcmp(buffer, "now") == 0)
        {
          epoch_time = time(NULL);
        }
        else
        {
          /* All characters should be digits */
          for(j = 0; j < strlen(buffer); j++)
          {
            if (!isdigit(buffer[j]))
              usage(argv[0], "Invalid epoch time");
          }
          /* Transform to time_t (unsigned int) */
          epoch_time = strtoul(buffer, (char **)NULL, 10);
          if ((epoch_time == 0) && (errno != 0))
            usage(argv[0], "Invalid epoch time");
        }
      }
      else
      {
        usage(argv[0], "-e option needs parameter");
      }
      continue;
    }
    if (strcmp(argv[i], "-f") == 0)
    {
      /* User specified date desired string format */
      ++i;
      if (i < argc)
      {
        /* The length should be between 1 and MAX_FORMAT characters */
        if (strlen(argv[i]) > MAX_FORMAT)
          usage(argv[0], "Invalid date/time format");

        strncpy(date_format, argv[i], MAX_FORMAT);
        date_format[MAX_FORMAT] = 0;
      }
      else
      {
        usage(argv[0], "-f option needs parameter");
      }
      continue;
    }
    /* If we are here, user wants to convert date-time to epoch.
       epoch_to_date should be false and date_to_epoch should also
       be false else we've been here twice... */
    if (epoch_to_date || date_to_epoch)
      usage(argv[0], NULL);

    date_to_epoch = 1;

    /* The length should be between 1 and MAX_DATE characters */
    if (strlen(argv[i]) > MAX_DATE)
      usage(argv[0], "Invalid date/time");

    strncpy(date_string, argv[i], MAX_DATE);
    date_string[MAX_DATE] = 0;
  }
}

