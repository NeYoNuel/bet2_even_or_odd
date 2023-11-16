pragma circom 2.1.6;

// asegurar que 0 <= in < 255
template Bits8(){
    signal input in;
    signal bits[8];
	signal output par;    // signal de salida para conocer paridad de in
    var bitsum = 0;
    for (var i = 0; i < 8; i++) {
        bits[i] <-- (in >> i) & 1;  // Array de bits de in
        bits[i] * (bits[i] - 1) === 0;
        bitsum = bitsum + 2 ** i * bits[i];		
    }
	par <== bits[0];
    bitsum === in; // restricion que satiface cadena binaria real de in
}

// asegurar que 1 <= in <= 100
template OneToHundred() {
    signal input in;
	signal output paritynumber;
	
	// garantizando que todas las señales son restringidas
    component lowerBound = Bits8(); // instanca para restringir in con un limite inferior
    lowerBound.in <== in - 1;
	lowerBound.par * (lowerBound.par - 1) === 0;
	component upperBound = Bits8(); // instanca para restringir in con un limite superior
    upperBound.in <== in + 155;
	upperBound.par * (upperBound.par - 1) === 0;
	component parity = Bits8();
	parity.in <== in;
	paritynumber <== parity.par;
}

// aseguramos la victoria de alice caundo el resultado de la suma es par
template BetResultIsZero(n) {
    signal input in[n]; // se declara un array para dos entradas
	signal input result_sum;
    signal output aliceWins;
	signal inv, result, finish_parity;  // señales intermedias
	
	component inRange[n]; // garantizar con la instancia OneToHundred para cada entrada
	for (var i = 0; i < n; i++) {
	  inRange[i] = OneToHundred();
	  inRange[i].in <== in[i];
	}
	
	0 === in[0] + in[1] - result_sum; // restricion que satiface la suma para el resultado
	
	finish_parity <-- inRange[0].paritynumber ^ inRange[1].paritynumber;
	inRange[0].paritynumber * (inRange[0].paritynumber - 1) === 0;
	inRange[1].paritynumber * (inRange[1].paritynumber - 1) === 0;
	
	component parity_result = Bits8();
	parity_result.in <== result_sum;
	finish_parity === parity_result.par; // restringir que se cumplan la paridad de la suma de las entradas con la salida
	
	result <== parity_result.par;
    inv <-- result!=0 ? 1/result : 0;
    aliceWins <== -result*inv +1; // si el valor de aliceWins es uno gana la apuesta
    result*aliceWins === 0;
}

component main {public [result_sum]} = BetResultIsZero(2);