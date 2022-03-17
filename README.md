# ROP-Chain

Ejecución de un shellcode que muestra el fichero /etc/passwd guardado en una variable global, dando los permisos de ejecución haciendo una llamada mprotect(2), cuya estructura esta hecha a partir de instruciones de una página ejecutable de la libc. Dejo una pequeña memoria del proceso. 

## Proceso

Para empezar, lo que hice fue buscar en la página de ayuda que argumentos hay que pasarle a la función mprotect(2) que en ensamblador AMD64 corresponde con la syscall 10 (en %rax). 

El primero es la dirección a partir de la cual quieres cambiar los permisos (que se guarda en el registro %rdi), que debe estar alineada a tamaño de página (4096, dejar 3 ceros al final). Esta dirección será para nosotros el inicio del shellcode que muestra por pantalla el fichero /etc/passwd (alineada). El shellcode se guarda como variable global inicializada (en el segmento .data).

El segundo argumento es la cantidad de memoria a la que queremos cambiar los permisos, que como el shellcode está contenido en una página solo lo haremos para una poniendo el literal 4096 (%rsi).

El tercer argumento son las flags, que podrán ser entre otras: Dar permiso de lectura, de escritura y de ejecución. Para saber a cuanto equivale cada flag en hexadecimal, buscasmos en los ficheros de cabecera que están en los directorios de /usr/include, y nos dice que para poner los 3 permisos hay que poner en %rdx un 7 en hexadecimal.

Teniendo claro lo que hay que pasarle a la función mprotect, se diseña conceptualmente la futura cadena rop, que en mi caso voy a usar 5 gadgets, los cuales simplemente haran los pop correspondientes para dejar los registros preparados para ejecutar la función mprotect.
El último gadget hará un syscall y un ret, que guardara en el PC (%rip) la dirección de inicio del shellcode para saltar allí.

Teniendo la cadena rop preparada, sólo hace falta buscar las dirección base de la libc, la dirección de inicio del shellcode y los offset de los gadgets correspondientes. Todo esto se hará con radare2. Ejecutamos radare2 con la opción -d pasandole el fichero rop compilado (Aunque no este completo aún, no pasa nada). Ponemos un db (breakpoint) en main y mostramos el mapa de memoria con dm. Se puede observar que encontramos una libc.so.2.31 pero no la libc.so.6. Si nos vamos a donde esta guardada la libc.so.6 y hacemos un ls -l veremos que es un enlace simbólico. Volvemos a radare2 y guardamos la dirección base que es la 0x7ffff7dfe000.

Para buscar la dirección de inicio del shellcode, consultamos la tabla de símbolos con el comando is y observamos que la dirección es la 0x555555558040. Para buscar los gadgets, abrimos radare2 pasandole como argumento la ruta de la libreria libc y le decimos que nos busque instrucciones que acaben en ret y que pertenezcan a la página de la libc que es ejecutable y lo guardamos en un fichero txt. 

Utilizando el comando grep buscamos los gadgets que serán los siguientes:

Gadget ================ Offset ============== Offset + dirección base libc

pop %rdi; ret ============ 0x28d90 ============ 0x7ffff7e26d90


pop %rsi; ret ============ 0x2890f ============ 0x7ffff7e2690f

pop %rdx; ret ============ 0xcb1cd ============ 0x7ffff7ec91cd

pop %rax; re t============ 0x3ee87 ============ 0x7ffff7e3ce87

syscall; ret ============== 0x580da ============ 0x7ffff7e560da




Por último, introducimos nuestra cadena ROP en la variable global destinada para ello (Cuidado little endian).
