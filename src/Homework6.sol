// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

contract homework6 {


    //struct for G1 point
    struct ECpoint {
        uint256 x;
        uint256 y;
    }

    //struct for G2 point
    struct ECpointG2 {
    uint256[2] x;
    uint256[2] y;
    }


     // New struct to hold a G1/G2 pair for pairing
    struct Pairing {
        ECpoint p1;
        ECpointG2 p2;
    }
    

    //hardcoding alpha G1 (times 5)

    ECpoint alphaG1 = ECpoint(10744596414106452074759370245733544594153395043370666422502510773307029471145,
     848677436511517736191562425154572367705380862894644942948681172815252343932); 


    //hardcoding beta G2 (times 3)

    ECpointG2 betaG2 = ECpointG2(
        [2725019753478801796453339367788033689375851816420509565303521482350756874229, 7273165102799931111715871471550377909735733521218303035754523677688038059653],
        [2512659008974376214222774206987427162027254181373325676825515531566330959255, 957874124722006818841961785324909313781880061366718538693995380805373202866]
    ); 


    //hardcoding gamma G2 (times 6)

    ECpointG2 gammaG2 = ECpointG2(
        [10191129150170504690859455063377241352678147020731325090942140630855943625622, 12345624066896925082600651626583520268054356403303305150512393106955803260718],
        [16727484375212017249697795760885267597317766655549468217180521378213906474374, 13790151551682513054696583104432356791070435696840691503641536676885931241944]
    ); 

    //hardcoding delta G2 (times 8)
    ECpointG2 deltaG2 = ECpointG2(
        [11166086885672626473267565287145132336823242144708474818695443831501089511977, 1513450333913810775282357068930057790874607011341873340507105465411024430745],
         [10576778712883087908382530888778326306865681986179249638025895353796469496812,  20245151454212206884108313452940569906396451322269011731680309881579291004202]);



    //this is the prime field for the elliptic curve
   uint256 p = 21888242871839275222246405745257275088696311157297823662689037894645226208583;


    //this is the generator point G1 for the elliptic curve
    ECpoint G1 = ECpoint(1,2);


      function PairingEquation (uint256 x1, uint256 x2, uint256 x3, ECpoint calldata a, ECpointG2 calldata b, ECpoint calldata c) public view returns (bool) {


        //we first multiply the bottom equation using scalar multiplication i.e. precompile address of 0x06
        //first x1 by G1
        ECpoint memory pointA = ECmultiply(x1, G1);
        //then x2 by G2
        ECpoint memory pointB = ECmultiply(x2, G1);
        //then x3 by G3
        ECpoint memory pointC = ECmultiply(x3, G1);


        //now we add the three points together using the precompile address of 0x07

        ECpoint memory sumAB = ECAdd(pointA, pointB);
        ECpoint memory bigX = ECAdd(sumAB, pointC);

        //now we solve for the first equation in the readme 
        //to solve for negative a, we must flip the y coordinate of a
        ECpoint memory negA = ECpoint(a.x, p - a.y);


        //we do a multipairing function to check if the equation is valid i.e. if the multipairing is == g (identity element)
        //we use the precompile address of 0x08 for this
        Pairing[] memory pairings = new Pairing[](4);
        pairings[0] = Pairing(negA, b);
        pairings[1] = Pairing(alphaG1, betaG2);
        pairings[2] = Pairing(bigX, gammaG2);
        pairings[3] = Pairing(c, deltaG2);

        require(ECmultiPairing(pairings), "Pairing check failed");

        return true;


    }

    
    function ECmultiply(uint256 scalar, ECpoint memory point) public view returns (ECpoint memory) {
        // This function should implement the scalar multiplication of an elliptic curve point
        // using the precompile at address 0x06.
        // The implementation details will depend on the specific elliptic curve used.
        // For example, if using secp256k1, you would call the precompile with the appropriate parameters.
        
        // Prepare input for the precompile: [point.x, point.y, scalar]
        bytes memory input = abi.encodePacked(point.x, point.y, scalar);
        bytes memory output = new bytes(64);

        bool success;
        (success, output) = address(0x06).staticcall(input);
        require(success, "ECmultiply failed");

        uint256 x;
        uint256 y;
        assembly {
            x := mload(add(output, 0x20))
            y := mload(add(output, 0x40))
        }
        return ECpoint(x, y);
     
    }


    function ECAdd(ECpoint memory a, ECpoint memory b) public view returns (ECpoint memory) {
        // This function should implement the addition of two elliptic curve points
        // using the precompile at address 0x07.
        // The implementation details will depend on the specific elliptic curve used.
        
        bytes memory input = abi.encodePacked(a.x, a.y, b.x, b.y);
        bytes memory output = new bytes(64);

        bool success;
        (success, output) = address(0x07).staticcall(input);
        require(success, "ECAdd failed");

        uint256 x;
        uint256 y;
        assembly {
            x := mload(add(output, 0x20))
            y := mload(add(output, 0x40))
        }
        return ECpoint(x, y);
    }





function ECmultiPairing(Pairing[] memory pairings) public pure returns (bool) {
    bytes memory input = new bytes(pairings.length * 192);

    // Each pairing is 192 bytes: G1 (2*32) + G2 (4*32)
    for (uint i = 0; i < pairings.length; i++) {
        uint offset = i * 192;
        ECpoint memory p1 = pairings[i].p1;
        ECpointG2 memory p2 = pairings[i].p2;

        // G1: x, y
        bytes32 p1x = bytes32(p1.x);
        bytes32 p1y = bytes32(p1.y);
        // G2: x[1], x[0], y[1], y[0] (swapped order for precompile)
        bytes32 p2x1 = bytes32(p2.x[1]);
        bytes32 p2x0 = bytes32(p2.x[0]);
        bytes32 p2y1 = bytes32(p2.y[1]);
        bytes32 p2y0 = bytes32(p2.y[0]);

        for (uint j = 0; j < 32; j++) input[offset + j] = p1x[j];
        for (uint j = 0; j < 32; j++) input[offset + 32 + j] = p1y[j];
        for (uint j = 0; j < 32; j++) input[offset + 64 + j] = p2x1[j];
        for (uint j = 0; j < 32; j++) input[offset + 96 + j] = p2x0[j];
        for (uint j = 0; j < 32; j++) input[offset + 128 + j] = p2y1[j];
        for (uint j = 0; j < 32; j++) input[offset + 160 + j] = p2y0[j];
    }

}

}
