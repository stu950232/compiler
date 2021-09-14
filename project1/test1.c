#include <stdio.h>
 
int Sum1To100(){
	int i, sum=0;
	for(i=1;i<=100;i++){
		sum += i;
	}
    return sum;
}
 
int main(){
    int sum;
	sum=Sum1To100();
    printf("%d\n", sum);
	return 0;
}