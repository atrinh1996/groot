; ModuleID = 'gROOT'
source_filename = "gROOT"

%anon0_struct = type { i32 (i32)* }

@fmt = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@boolT = private unnamed_addr constant [3 x i8] c"#t\00", align 1
@boolF = private unnamed_addr constant [3 x i8] c"#f\00", align 1
@_anon0_1 = global i32 (i32)* null
@_foo_1 = global %anon0_struct* null

declare i32 @printf(i8*, ...)

declare i32 @puts(i8*)

define i32 @main() {
entry:
  %gstruct = alloca %anon0_struct, align 8
  %funcField = getelementptr inbounds %anon0_struct, %anon0_struct* %gstruct, i32 0, i32 0
  store i32 (i32)* @anon0, i32 (i32)** %funcField, align 8
  store %anon0_struct* %gstruct, %anon0_struct** @_foo_1, align 8
  %_foo_1 = load %anon0_struct*, %anon0_struct** @_foo_1, align 8
  %function_access = getelementptr inbounds %anon0_struct, %anon0_struct* %_foo_1, i32 0, i32 0
  %function_call = load i32 (i32)*, i32 (i32)** %function_access, align 8
  %function_result = call i32 %function_call(i32 1)
  ret i32 0
}

define i32 @anon0(i32 %x) {
entry:
  %x1 = alloca i32, align 4
  store i32 %x, i32* %x1, align 4
  %x2 = load i32, i32* %x1, align 4
  ret i32 %x2
}
