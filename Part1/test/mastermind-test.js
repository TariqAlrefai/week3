const chai = require("chai");
const path = require("path");

const wasm_tester = require("circom_tester").wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString("21888242871839275222246405745257275088548364400416034343698204186575808495617");
const Fr = new F1Field(exports.p);
const assert = chai.assert;
const { buildPoseidonOpt } = require("circomlibjs");


describe("Bagel Game test", function () {
    this.timeout(100000000);

    
  let Poseidon;
  before(async ()=>{
      Poseidon = await buildPoseidonOpt();
  });


    it("Bagel Game", async () => {
        const circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
        await circuit.loadConstraints();
        const hash = Poseidon.F.toObject(await Poseidon([25,1,4,9]));
        
        const INPUT = {firNum:1,
        secNum:4, 
        thiNum:9,
        pubNumHit:3,
        pubNumBlow:0,
        pubSolnHash:hash,
        privSolnfir:1,
        privSolnsec:4,
        privSolnthi:9,
        privSalt:25,
        }

        const witness = await circuit.calculateWitness(INPUT, true);

        switch(INPUT.pubNumHit) {
            case 3:
              console.log("Fermi Fermi Fermi !!")
                break;

            case 2:
                if(INPUT.pubNumBlow == 1){
                    console.log("Fermi Fermi Pico")
                } else{
                    console.log("Fermi Fermi")
                }
                break;

            case 1:
                if(INPUT.pubNumBlow == 2){
                    console.log("Fermi Pico Pico") 
                } else if (INPUT.pubNumBlow == 1){
                    console.log("Fermi Pico")
                } else{
                    console.log("Fermi")
                }
                break;

            case 0:
                if(INPUT.pubNumBlow == 3){
                    console.log("Pico Pico Pico")
                } else if (INPUT.pubNumBlow == 2){
                    console.log("Pico Pico")
                } else if (INPUT.pubNumBlow == 1){
                    console.log("Pico")
                } else{
                    console.log("Bagel")
                }
                break;

          }


        assert(Fr.eq(Fr.e(witness[0]),Fr.e(1)));
        assert(Fr.eq(Fr.e(witness[1]),Fr.e(hash)));
    });
});