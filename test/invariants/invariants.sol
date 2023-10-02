// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/StdCheats.sol";

import {HelperConfig} from "../../script/Helper.s.sol";

contract Invariant is StdCheats, Test {
    // * STATE VARIABLES

    // * SETUP
    function setUp() public {
        new HelperConfig();
    }
}
