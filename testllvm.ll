; Declare the printf function from the C standard library
declare i32 @printf(i8*, ...)

; Define a constant string "Hello, LLVM!\n"
@.str = private constant [13 x i8] c"Hello, LLVM!\0A\00"

; Define the main function
define i32 @main() {
entry:
  ; Get pointer to the string
  %0 = getelementptr [13 x i8], [13 x i8]* @.str, i32 0, i32 0
  ; Call printf with the string pointer
  call i32 (i8*, ...) @printf(i8* %0)
  ; Return 0 (success)
  ret i32 0
}
