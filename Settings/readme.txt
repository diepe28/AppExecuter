*************** Values with optimizations *************** 
Command=mpiexec -np 1 ./Wang 80 90 100 1;
NumRuns=200;
TimeOut=150;
NumIters=156;
CorrectResult=7.456117e-21;


*************** Values without optimizations ***************
Command=mpiexec -np 1 ./Wang 60 70 70 1;
NumRuns=200;
TimeOut=150;
NumIters=141;
CorrectResult=8.058375e-21;
