; === prologue ====
declare dso_local i32 @printf(i8*, ...)

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

@.str_f = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1

define dso_local i32 @main()
{
%t0 = alloca float, align 4
%t1 = alloca float, align 4
store float 0x4010ccccc0000000, float* %t0
%t2=load float, float* %t0
%t3=load float, float* %t0
%t4 = fpext float %t3 to double
%t5 = fadd double 1.1, %t4
%t6 = fpext float %t2 to double
%t7 = fmul double %t6, %t5
%t8 = fsub double 4.2, %t7
%t9 = fptrunc double %t8 to float
store float %t9, float* %t1, align 4
%t10=load float, float* %t1
%t11=load float, float* %t0
%t12 = fdiv float %t10, %t11
%t13 = fpext float %t12 to double
%t14=call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str_f, i32 0, i32 0), double %t13)

; === epilogue ===
ret i32 0
}
