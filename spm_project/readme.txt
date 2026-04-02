Per buildare è disponibile il makefile. e.g. make all 
Ad esempio con make cpu vengono buildate tutte le versioni scalari, auto-vettorizzate e avx2 o con make cuda tutte le versioni gpu  
altrimenti si possono buildare le singole versioni (vedere target makefile). 

Per verificare la correttezza è possibile eseguire le singole versioni e verificare che restituiscono la stessa checksum che è stampata a schermo. 

Per eseguire i test, eseguire "total_benchmark.sh" 