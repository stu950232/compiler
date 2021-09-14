#include <stdio.h>
#include <string.h>
#include <stdlib.h>
int leap(int year)
{  
  if((year%4)==0 && (year%100)!=0 || (year%400) ==0)
  {
    printf ("%d is a leap year\n",year);
  }
  else
  {
    printf ("%d is not a leap year\n",year);
  } 
}
int main(int argc,char *argv[])
{
  int year;
  printf("Please enter the year you want to check: ");
  scanf("%d",&year);
  leap(year);
  return 0;
}