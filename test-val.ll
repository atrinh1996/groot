; ModuleID = 'gROOT'
source_filename = "gROOT"

%_anon0_struct = type { i32 ()* }

@fmt = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@boolT = private unnamed_addr constant [3 x i8] c"#t\00", align 1
@boolF = private unnamed_addr constant [3 x i8] c"#f\00", align 1
@__anon0_1 = global i32 ()* null
@_x_6 = global %_anon0_struct* null
@_x_5 = global i32 0
@_x_4 = global i0 0
@_x_3 = global i0 0
@_x_2 = global i32 0
@_x_1 = global i32 0
@_y_1 = global i0 0
@globalChar = private unnamed_addr constant [2 x i8] c"c\00", align 1
@globalChar.1 = private unnamed_addr constant [2 x i8] c"a\00", align 1
@globalChar.2 = private unnamed_addr constant [2 x i8] c"b\00", align 1

declare i32 @printf(i8*, ...)

declare i32 @puts(i8*)

define i32 @main() {
entry:
  store i32 10, i32* @_x_1, align 4
  %_x_1 = load i32, i32* @_x_1, align 4
  %printi = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @fmt, i32 0, i32 0), i32 %_x_1)
  store i32 7, i32* @_x_2, align 4
  %_x_2 = load i32, i32* @_x_2, align 4
  %printi1 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @fmt, i32 0, i32 0), i32 %_x_2)
  %spc = alloca i8*, align 8
  %loc = getelementptr i8*, i8** %spc, i32 0
  store i8* getelementptr inbounds ([2 x i8], [2 x i8]* @globalChar, i32 0, i32 0), i8** %loc, align 8
  %character_ptr = load i8*, i8** %spc, align 8
  store i8* %character_ptr, i0* @_y_1, align 8
  %spc2 = alloca i8*, align 8
  %loc3 = getelementptr i8*, i8** %spc2, i32 0
  store i8* getelementptr inbounds ([2 x i8], [2 x i8]* @globalChar.1, i32 0, i32 0), i8** %loc3, align 8
  %character_ptr4 = load i8*, i8** %spc2, align 8
  store i8* %character_ptr4, i0* @_x_3, align 8
  %spc5 = alloca i8*, align 8
  %loc6 = getelementptr i8*, i8** %spc5, i32 0
  store i8* getelementptr inbounds ([2 x i8], [2 x i8]* @globalChar.2, i32 0, i32 0), i8** %loc6, align 8
  %character_ptr7 = load i8*, i8** %spc5, align 8
  store i8* %character_ptr7, i0* @_x_4, align 8
  store i32 1, i32* @_x_5, align 4
  %_x_5 = load i32, i32* @_x_5, align 4
  %printi8 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @fmt, i32 0, i32 0), i32 %_x_5)
  %gstruct = alloca %_anon0_struct, align 8
  %funcField = getelementptr inbounds %_anon0_struct, %_anon0_struct* %gstruct, i32 0, i32 0
  store i32 ()* @_anon0, i32 ()** %funcField, align 8
  store %_anon0_struct* %gstruct, %_anon0_struct** @_x_6, align 8
  ret i32 0
}

define i32 @_anon0() {
entry:
  ret i32 7
}
