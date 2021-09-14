; === prologue ====
declare dso_local i32 @printf(i8*, ...)

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

@.str_f = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1

define dso_local i32 @main()
{
%t0 = alloca i32, align 4
store i32 1, i32* %t0
br label %t1
t1:
%t2=load i32, i32* %t0
%t3 = icmp slt i32 %t2, 8
br i1 %t3, label %t4, label %t5

t4:
%t6=load i32, i32* %t0
%t7 = icmp sle i32 %t6, 4
br i1 %t7, label %t8, label %t9

t8:
%t10=load i32, i32* %t0
%t11=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0), i32 %t10)
br label %t12

t9:
%t13=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str_f, i32 0, i32 0), double 2.3)
br label %t12

t12:
%t14=load i32, i32* %t0
%t15 = add nsw i32 %t14, 1
store i32 %t15, i32* %t0
br label %t1

t5:

; === epilogue ===
ret i32 0
}
