; ModuleID = 'gROOT'
source_filename = "gROOT"

%tree_struct = type { i32, %tree_struct*, %tree_struct* }

@fmt = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@fmt.1 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@fmt.2 = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1
@boolT = private unnamed_addr constant [3 x i8] c"#t\00", align 1
@boolF = private unnamed_addr constant [3 x i8] c"#f\00", align 1
@globalChar = private unnamed_addr constant [2 x i8] c"t\00", align 1

declare i32 @printf(i8*, ...)

declare i32 @puts(i8*)

define void @main(%tree_struct %0) {
entry:
  %spc = alloca i8*, align 8
  %loc = getelementptr i8*, i8** %spc, i32 0
  store i8* getelementptr inbounds ([2 x i8], [2 x i8]* @globalChar, i32 0, i32 0), i8** %loc, align 8
  %character_ptr = load i8*, i8** %spc, align 8
  %printc = call i32 @puts(i8* %character_ptr)
  ret void
}
