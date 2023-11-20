## Aplicación de Apuesta entre dos partes

Supongamos que dos personas, Alice y Bob, quieren apostar en un juego de azar. Cada uno de ellos elige un número aleatorio entre 1 y 100, y luego multiplican los dos números. Si la multiplicación es par, Alice gana la apuesta, y si la suma es impar, Bob gana la apuesta. Sin embargo, no quieren revelar sus números aleatorios a la otra persona. Para resolver este problema, se puede utilizar una prueba de conocimiento cero para demostrar que cada persona conoce el número que eligió sin revelarlo. La idea es aplicar zksnark y aplicar homorfismo a los datos cifrados y hacer verificaciones.

## ZKP - GUÍA

Los programas para compiladores de circuitos tienen dos modos de ejecución. El primer modo, generalmente llamado fase de configuración, se realiza para generar el circuito y su sistema de restricción de rango 1 asociado, el último de los cuales generalmente se usa como entrada para algún sistema de prueba de conocimiento cero. El segundo modo de ejecución suele denominarse fase de prueba. En esta fase, generalmente se proporciona como entrada alguna asignación a todas las variables de instancia del circuito y la tarea de un probador es calcular una asignación válida a todas las variables testigo del circuito.

Los lenguajes de programación del mundo real suelen proporcionar la vía para encontrar los valores de entrada adecuados para un circuito determinado estos datos se calculan fuera del circuito. El sistema de restricciones R1CS tiene la siguiente forma:

$(x_1 \cdot s_1 + ... + a_n \cdot s_n) \cdot (b_1 \cdot s_1 + ... + b_n \cdot s_n) + (c_1 \cdot s_1 + ... + c_n \cdot s_n)  = 0$

Se requiere que el probador proporcione el testigo valido (s1) para generar una prueba de conocimiento cero.

	IMPORTANTE: Requisitos prevos de instalación de Node, Circom y snarjs 
	CONSULTAR: https://docs.circom.io/
### Fase 1
#### Compilación de circuitos

Para nuestra aplicación desarrollamos el siguiente circuito en `circom` con 3 templates para generar las restricciones  generando el archivo `bet_even_or_odd.circom`


Podemos inspeccionar nuestro código de circom para revisar sugerencias, advertencias o errores de la siguiente forma:
```bash
circom bet_even_or_odd.circom --inspect
```
![[circom --inspect.png]]

Luego compilamos el circuito `bet_even_or_odd.circom` de la siguiente forma:

```bash
circom bet2_even_or_odd.circom --r1cs --wasm --sym --c --json
```
![[circom compiler.png]]

- `r1cs`: Generar `bet_even_or_odd.r1cs`, que contiene una descripción del sistema de restricciones;
- `--wasm`: Generar `Wasm`código, utilizado para generar `testigo (witness)`;
- `--sym`: Genera `bet_even_or_odd.sym` archivos de símbolos para depuración;
- `--c`: Genera código C para la generación de `testigo (witness)`.

#### Generar testigo (witness)

La entrada de compilación `input.json` es:

```json
{"in": [15, 100]}
```

Luego accedemos a la ruta `bet_even_or_odd_js` llamamos al archivo `Wasm` para generar el `witness`como:
```bash
node generate_witness.js bet2_even_or_odd.wasm input.json witness.wtns
```

#### Generar prueba

Activamos los poderes de Tau (Ceremonia), donde `bn128` es el tipo de curva a utilizar. De momento la documentación define la admisión solo para esta y la curva `bls12-381`. El parámetro `12`, es la potencia de dos del número máximo de restricciones que la ceremonia puede aceptar. El valor máximo admitido es `28`.
```bash
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
```
![[ptau.png]]
Participamos en la ceremonia de los poderes de Tau

```bash
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="Primera Contribucion" -v
```
El `contribute`comando crea un archivo `ptau` que contienen un historial de todos los desafíos y respuestas que han tenido lugar hasta ahora. Se le pedirá que ingrese texto aleatorio para proporcionar una fuente adicional de entropía.

Se pueden realizar tantas contribuciones como se desee generándose nuevos archivos `.ptau` . Además es posible proporcionar contribuciones de un tercero utilizando software de tercero.

Verificar todas las contribuciones al protocolo del cálculo de multi-partes (MPC) hasta el momento 

```bash
snarkjs powersoftau verify pot12_0001.ptau
```

Para finalizar la fase 1 la documentación refleja la posibilidad de emplear un `beacon` una fuente de aleatoriedad pública este valor será alguna forma de alta entropía generando en este por 10 iteraciones de la función hash. Por ejemplo Zcash que emplea zkSNARK anunció que usarían el hash de un bloque de Bitcoin específico, hicieron este anuncio antes de que se extrajera el bloque, siendo el `beacon random` la iteración $2^{42}$ de SHA256 sobre el hash del bloque 514200, con hash:

```
00000000000000000034b33e842ac1c50456abe5fa92b60f6b3dfc5d247f7b58
```

```bash
snarkjs powersoftau beacon pot12_0001.ptau pot12_beacon.ptau 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon"
```

### Fase 2

La fase 2 depende del circuito y se puede iniciar con el siguiente comando que calcula la evaluación cifrada de los polinomios de Lagrange en tau:
```bash
snarkjs powersoftau prepare phase2 pot12_beacon.ptau pot12_final.ptau -v
```

Actualmente, snarkjs admite 3 sistemas de prueba: Groth16, PLONK y FFLONK (versión Beta). Groth16 requiere una ceremonia de confianza para cada circuito. PLONK y FFLONK no lo requieren, basta con los poderes de la ceremonia tau que es universal. En este caso hacemos uso del protocolo Groth16.
Genere `.zkey`un archivo que contenga el certificado, las claves de prueba y las claves de verificación y ejecute el siguiente comando:

```bash
snarkjs groth16 setup ../bet2_even_or_odd.r1cs pot12_final.ptau bet2_even_or_odd_0000.zkey
```
IMPORTANTE: No utilice esta zkey en producción, ya que no es segura. Requiere al menos una contribución

Contribuir a la ceremonia de la fase 2, para el cual se necesita un nuevo texto como fuente de entropía

```bash
snarkjs zkey contribute bet2_even_or_odd_0000.zkey bet2_even_or_odd_0001.zkey --name="1st Contributor Enmanuel" -v
```

Podemos hacer más contribuciones. Aplicando un `beacon random` como una contribución

```bash
snarkjs zkey beacon bet2_even_or_odd_0001.zkey bet2_even_or_odd_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"
```

 Verificar que el archivo `zkey` coincida con el circuito.

```bash
snarkjs zkey verify ../bet2_even_or_odd.r1cs pot12_final.ptau bet2_even_or_odd_final.zkey
```


Clave de verificación de exportación:

```bash
snarkjs zkey export verificationkey bet2_even_or_odd_final.zkey verification_key.json
```


La clave de verificación generada `verification_key.json`es:
![[key.png]]

#### Generar prueba

```bash
snarkjs groth16 prove bet2_even_or_odd_final.zkey witness.wtns proof.json public.json
```

IMPORTANTE: Tenga en cuenta que también es posible crear la prueba y calcular el testigo a la vez con el mismo comando ejecutando:
```bash
snarkjs groth16 fullprove input.json bet_even_or_odd.wasm bet_even_or_odd_final.zkey prueba.json public.json
```

`proof.json` contiene la prueba real, mientras que `public.json`contiene los valores de las entradas y salidas públicas.

Verificar la prueba
```bash
snarkjs groth16 verify verification_key.json public.json proof.json
```
#### Generar contrato de verificación

Un contrato de verificación de Solidity se puede generar de la siguiente manera:

```bash
snarkjs zkey export solidityverifier bet2_even_or_odd_final.zkey verifier.sol
```

Generar parámetros de llamada de contrato:

```bash
snarkjs generatecall
```
o lo mismo
```bash
snarkjs zkey export soliditycalldata public.json proof.json
```

## Interfaz con JavaScript

Using Node
```shell
npm init
npm install snarkjs
```

Copiamos archivos necesarios
```bash
cp node_modules/snarkjs/build/snarkjs.min.js .
cp zkproof/bet2_even_or_odd_js/bet2_even_or_odd.wasm .
cp zkproof/bet2_even_or_odd_js/witness_calculator.js .
cp zkproof/proving/bet2_even_or_odd_final.zkey .
cp zkproof/proving/verification_key.json .
```

Corremos un servidor para nuestra aplicación y eso es todo.

Aunque quizás no sea tan interesante desde el punto de vista técnico, en mi opinión la prueba basada en navegador sigue siendo el ZKP más filosóficamente necesario en términos de casos de uso del mundo real donde la privacidad es de suma importancia. Esperemos que alguien pueda proporcionar información/ayuda/soluciones sobre este problema.

Me parece insatisfactorio que la experiencia introductoria que muchas personas tienen con la implementación de snarkjs en la web les implique sumergirse en una madriguera de paquetes web/activos estáticos de la que muchos no escapan. En el caso más atroz, la gente soluciona esto creando un pequeño backend específicamente para generar pruebas, lo que afloja los supuestos de confianza de su proyecto. ¿No sería bueno si la gente pudiera simplemente escribir