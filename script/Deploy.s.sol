// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Plonky2Verification.sol";

// Use the below command to run this script
// forge script script/Deploy.s.sol --broadcast
contract Deploy is Script {
    function setUp() public {}

    function run() public {
        uint256 privKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(privKey);
        vm.createSelectFork("goerli");
        vm.startBroadcast(deployer);

        Plonky2Verification plonky2Verification = new Plonky2Verification();
        console.log(
            "Plonky2Verification address: %s",
            address(plonky2Verification)
        );
        plonky2Verification.request();

        vm.stopBroadcast();
    }
}
