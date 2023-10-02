// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

interface ICounter {
    function number() external view returns (uint256);

    function setNumber(uint256 newNumber) external;

    function increment() external;
}

contract CounterTest is Test {
    // Counter public counter;
    ICounter counter;

    function setUp() public {
        // counter = new Counter();
        counter = ICounter(
            getContractAddress("Counter.sol:Counter", bytes(""))
        );

        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function getContractAddress(
        string memory artifactPath,
        bytes memory args
    ) internal returns (address) {
        bytes memory bytecode = abi.encodePacked(
            vm.getCode(artifactPath),
            args
        );

        address _address;
        assembly {
            _address := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        return _address;
    }
}
