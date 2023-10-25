// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Plonky2Verification.sol";

contract Plonky2VerificationTest is Test {
    Plonky2Verification public plonky2Verification;
    address callingAddress = address(0x1);

    function setUp() public {
        plonky2Verification = new Plonky2Verification();
    }

    function testRequest() public {
        plonky2Verification.request();
    }
}
