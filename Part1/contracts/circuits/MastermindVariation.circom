pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";


// Bagels will be implemented   
template MastermindVariation() {

    // Public inputs
    signal input firNum;
    signal input secNum;
    signal input thiNum;
    signal input pubNumHit;
    signal input pubNumBlow;
    signal input pubSolnHash;
    
    // Private inputs
    signal input privSolnfir;
    signal input privSolnsec;
    signal input privSolnthi;
    signal input privSalt;

    // Output
    signal output solnHashOut;

    var guessNum[3] = [firNum, secNum, thiNum];
    var solNum[3] =  [privSolnfir, privSolnsec, privSolnthi];
    
    component lessThan[6];
    component equalGuess[6];
    component equalSoln[6];
    component equalHB[9];
    component equalBlow = IsEqual();
    component equalHit = IsEqual();
    component poseidon = Poseidon(4);
    var equalIdx = 0;

    // Create a constraint that the solution and guess digits are all less than 10.
    var j;
    var k;
    for (j=0; j<3; j++) {
        lessThan[j] = LessThan(4);
        lessThan[j].in[0] <== guessNum[j];
        lessThan[j].in[1] <== 10;
        lessThan[j].out === 1;
        lessThan[j+3] = LessThan(4);
        lessThan[j+3].in[0] <== solNum[j];
        lessThan[j+3].in[1] <== 10;
        lessThan[j+3].out === 1;
        for (k=j+1; k<3; k++) {
            // Create a constraint that the solution and guess digits are unique. no duplication.
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guessNum[j];
            equalGuess[equalIdx].in[1] <== guessNum[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== solNum[j];
            equalSoln[equalIdx].in[1] <== solNum[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }


    // Count hit & blow
    var hit = 0;
    var blow = 0;

    for (j=0; j<3; j++) {
        for (k=0; k<3; k++) {
            equalHB[3*j+k] = IsEqual();
            equalHB[3*j+k].in[0] <== solNum[j];
            equalHB[3*j+k].in[1] <== guessNum[k];
            blow += equalHB[3*j+k].out;
            if (j == k) {
                hit += equalHB[3*j+k].out;
                blow -= equalHB[3*j+k].out;
            }
        }
    }

    
    // Create a constraint around the number of hit
    equalHit.in[0] <== pubNumHit;
    equalHit.in[1] <== hit;
    equalHit.out === 1;
    
    // Create a constraint around the number of blow
    equalBlow.in[0] <== pubNumBlow;
    equalBlow.in[1] <== blow;
    equalBlow.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnfir;
    poseidon.inputs[2] <== privSolnsec;
    poseidon.inputs[3] <== privSolnthi;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;

 }

}

component main = MastermindVariation();