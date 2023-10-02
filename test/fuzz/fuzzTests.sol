// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {HelperConfig} from "../../script/Helper.s.sol";

import "forge-std/console.sol";

contract FuzzTests is HelperConfig, Test {
    address deployer;

    function setUp() public {
        deployer = wallet;

        address[] memory vTokens = new address[](2);
        vTokens[0] = address(vusdt);
        vTokens[1] = address(veth);

        vm.startPrank(user1);
        eth.approve(address(veth), bigNumber18 * 90);
        veth.mint(bigNumber18 * 90);
        comptroller.enterMarkets(vTokens);

        // vusdt.borrow(bigNumber18 * 5);

        vm.stopPrank();

        vm.startPrank(user2);
        usdt.approve(address(vusdt), bigNumber18 * 9000);
        vusdt.mint(bigNumber18 * 9000);
        comptroller.enterMarkets(vTokens);

        // veth.borrow(bigNumber18 * 1);

        vm.stopPrank();
    }

    // * Protocol Setup Tests

    function test_MarketsAdded() public {
        assertEq(comptroller.allMarkets(0), address(vusdt));
        assertEq(comptroller.allMarkets(1), address(veth));
    }

    // function test_BorrowBalance() public {
    //     assertGt(usdt.balanceOf(user1), 0);
    //     assertGt(eth.balanceOf(user2), 0);
    // }

    function test_MarketsInPrime() public {
        address[] memory markets = prime.getAllMarkets();

        assertEq(markets[0], address(vusdt));
        assertEq(markets[1], address(veth));
    }

    // * Mint and Burn Tests

    function test_stakeAndMint() public {
        address user = user1;

        vm.startPrank(user);

        vm.expectRevert();
        prime.claim();

        xvs.approve(address(xvsVault), bigNumber18 * 10000);
        xvsVault.deposit(address(xvs), 0, bigNumber18 * 10000);

        assertGt(prime.stakedAt(user), 0);

        vm.expectRevert();
        prime.claim();

        assertEq(prime.claimTimeRemaining(user), 7776000);

        vm.warp((90 * 24 * 60 * 60) + 1);

        prime.claim();

        vm.stopPrank();
    }
}
