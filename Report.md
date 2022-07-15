# REPORT

#### I was done with strace system call. In strace system call i printed process id,systemcall name and return value of system call.
- In my assignment hints and tutorial helped me a lot. I added strace file to the makefile for clear compilation. 
If i used any extra variables in the code I declared that in proc.h for global declaration. 
I added necessary function in  syscall.c of kernal folder. 
For copying trace function from parent to child process I edited fork().

- I printed trace output by adding array of syscall names and printed them when condition satisfied.

- created user program for user interface for calling syscall from the terminal and modified and \
  defined syscall number for sys_trace.

#### In my First Come First Serve (FCFS) Scheduling..

- As we know it excuited my preference of process generation. Like if the process generated 1st should exicuted 1st.
- using conditional compiling i made the assignment to run with given formate. In my FCFS shecduling I traversed with all the process 
   from the pages as it mentioned  in round robin and found the 1st generated process and swtch that process to context.
 
- I my priorty based scheduling I set a priority global variable and intialized that with 60 and run with a loop of process as 
  mentioned above like in round rubbin and FCFS and found the process which having high priority and scheduled that process.


I compared default,FCFS and PBS
- for default average runtime was high compared with FCFS AND PBS
- for default average wait time was little less .
- runtime for FCFS was less compared with default. For me wait time was more like average 35.
- I got little bit more runtime for PBS compared with FCFS..
