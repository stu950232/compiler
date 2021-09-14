; === prologue ====
declare dso_local i32 @printf(i8*, ...)

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

@.str_f = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1

define dso_local i32 @main()
{
%t0 = alloca float, align 4
%t1 = alloca float, align 4
store float 0x403d666660000000, float* %t1
%t2=load float, float* %t1
store float %t2, float* %t0
%t3=load float, float* %t1
%t4 = fpext float %t3 to double
%t5 = fcmp olt double %t4, 1.23
br i1 %t5, label %t6, label %t7

t6:
%t8=load float, float* %t1
%t9 = fpext float %t8 to double
%t10 = fadd double %t9, 1.1
%t11 = fptrunc double %t10 to float
store float %t11, float* %t1, align 4
%t12=load float, float* %t1
%t13 = fpext float %t12 to double
%t14=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str_f, i32 0, i32 0), double %t13)
br label %t15

t7:
%t16=load float, float* %t0
%t17 = fpext float %t16 to double
%t18=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str_f, i32 0, i32 0), double %t17)
br label %t15

t15:

; === epilogue ===
ret i32 0
}
