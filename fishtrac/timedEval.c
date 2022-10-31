#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <math.h>
#include <unistd.h>
#include <sys/wait.h>


int timeUpFlag=0;
pid_t childPID1=0;

void timeUp()
{
    //if(childPID1 > 0)
    //{
        //kill(-childPID1, SIGKILL);
    //}
    kill(getpid(), SIGINT);
    timeUpFlag=1;
}

void nothing()
{
}

void killTree(pid_t pid)
{
    char *kill_mc = "init_killtree() { \n\
    local pid=$1 child \n\
    echo \"init_killtree called on $pid\"\n\
    for child in $(pgrep -P $pid); do \n\
        init_killtree $child \n\
    done \n\
    [ $pid -ne $$ ] && kill -kill $pid \n\
    }\n\
    init_killtree ";

    char *kill_cmd = malloc(strlen(kill_mc) +(int)log10(pid) + 4);
    sprintf(kill_cmd, "%s %d\n", kill_mc, pid);
    system(kill_cmd);
    free(kill_cmd);
    kill(-pid, SIGKILL);
}



int main(int argc, char **argv)
{
    struct sigaction act, act2;
    struct sigaction oldact;
    char *command;


    if(argc < 2)
    {
        printf("USAGE: %s COMMAND ...", argv[0]);
        exit(2);
    }

    int sizeSum = 0;
    for(int i=1; i<argc; i++)
    {
        sizeSum += strlen(argv[i])+1;
    }

    command = malloc(sizeof(char)*(sizeSum+1));
    command[0] = '\0';
    for(int i=1; i<argc; i++)
    {
        strcat(command, argv[i]);
        strcat(command, " ");
    }
   
   int code = fork();
    if(code < 0)
    {
        printf("Error. Could not fork() process\n");
        exit(1);
    } else if(code == 0) {
        setpgid(0, 0);
        int ret = system(command);
        printf("system() returned %d in child!\n", ret);
        //int ret2 = system("./dontstop.sh");
        free(command);
        if(ret != 0)
            exit(1);
        else
            exit(0);
    } else {
        printf("this print comes from the parent, child has PID=%d!\n", code);
        act.sa_handler = &timeUp;
        sigemptyset(&act.sa_mask);
        act.sa_flags = 0;
        sigaction(SIGALRM, &act, &oldact);
        act.sa_handler = &nothing;
        sigaction(SIGINT, &act, &oldact);
        
        childPID1 = code;

        alarm(1800);
        int waitStatus;

        pid_t childPID = wait(&waitStatus);
        killTree(childPID1);
        alarm(0);
        if(childPID > 0)
        {
            printf("Child %d exited!\n", childPID);
            if(WIFEXITED(waitStatus))
            {
               int status = WEXITSTATUS(waitStatus);
               printf("...exited with status %d\n", status);
               exit(status);
            }
            else 
            {
                printf("Exited abnormally!\n");
            }
        }
        else
        {
            printf("Alarm fired!\n");
            exit(5);

        }
        //}
        //for(i=0; i< 10; i++)
        //{
           //printf("this print comes from the parent, child has PID=%d, x=%d!\n", code,x);
           // sleep(1);
        //}

    }
    free(command);

    while(wait(NULL) > 0)
    {
    }

    return 0;
}
